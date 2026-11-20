package com.tayran.service.impl.order;

import com.tayran.dao.entity.Order;
import com.tayran.dao.entity.OrderEvent;
import com.tayran.dao.entity.OrderItem;
import com.tayran.dao.entity.User;
import com.tayran.dao.repository.OrderEventRepository;
import com.tayran.dao.repository.OrderItemRepository;
import com.tayran.dao.repository.OrderRepository;
import com.tayran.dao.repository.UserRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import com.tayran.model.order.ActorType;
import com.tayran.model.order.LineStatus;
import com.tayran.model.order.OrderDtos.AdminOrderDto;
import com.tayran.model.order.OrderDtos.AdminOrderPage;
import com.tayran.model.order.OrderDtos.AdminOrderRow;
import com.tayran.model.order.OrderDtos.CancelRequest;
import com.tayran.model.order.OrderDtos.DeliverRequest;
import com.tayran.model.order.OrderDtos.EditItemsRequest;
import com.tayran.model.order.OrderDtos.ItemEdit;
import com.tayran.model.order.OrderDtos.OutForDeliveryRequest;
import com.tayran.model.order.OrderStatus;
import com.tayran.model.order.SubstitutionPref;
import com.tayran.service.AdminOrderService;
import com.tayran.service.impl.OrderPricing;
import com.tayran.service.impl.order.OrderWriter.TransitionData;
import com.tayran.utils.PhoneUtils;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminOrderServiceImpl implements AdminOrderService {

    static final int PAGE_SIZE = 30;

    private final OrderRepository orderRepository;
    private final OrderItemRepository itemRepository;
    private final OrderEventRepository eventRepository;
    private final UserRepository userRepository;
    private final CatalogLookup catalog;
    private final OrderAssembler assembler;
    private final OrderWriter writer;

    @PersistenceContext
    private EntityManager entityManager;

    // ---- read --------------------------------------------------------------------------------

    @Override
    @Transactional(readOnly = true)
    public AdminOrderPage list(OrderStatus status, String cursor, String search) {
        if (search != null && !search.isBlank()) {
            return new AdminOrderPage(rows(search(search.strip())), null);
        }
        Set<OrderStatus> statuses = status == null ? Set.of(OrderStatus.values()) : Set.of(status);
        PageRequest page = PageRequest.of(0, PAGE_SIZE + 1);
        List<Order> orders;
        if (cursor == null || cursor.isBlank()) {
            orders = orderRepository.findAdminFirstPage(com.tayran.service.impl.CatalogChanges.DEFAULT_STORE_ID, statuses, page);
        } else {
            OrderServiceImpl.Cursor c = OrderServiceImpl.Cursor.parse(cursor);
            orders = orderRepository.findAdminPageBefore(com.tayran.service.impl.CatalogChanges.DEFAULT_STORE_ID, statuses,
                    c.at(), c.id(), page);
        }
        String next = null;
        if (orders.size() > PAGE_SIZE) {
            orders = orders.subList(0, PAGE_SIZE);
            next = new OrderServiceImpl.Cursor(orders.getLast().getCreatedAt(), orders.getLast().getId()).encode();
        }
        return new AdminOrderPage(rows(orders), next);
    }

    /** An order number (digits) or a customer's phone in any accepted format. */
    private List<Order> search(String query) {
        String digits = PhoneUtils.toWesternDigits(query).replaceAll("[^0-9]", "");
        if (!digits.isEmpty() && digits.length() <= 9 && !digits.startsWith("0")) {
            return orderRepository.findByOrderNumber(Long.parseLong(digits)).map(List::of).orElse(List.of());
        }
        try {
            return orderRepository.findByPhone(com.tayran.service.impl.CatalogChanges.DEFAULT_STORE_ID, PhoneUtils.normalize(query));
        } catch (BusinessException e) {
            return List.of();
        }
    }

    @Override
    @Transactional(readOnly = true)
    public AdminOrderDto get(long orderId) {
        return dto(find(orderId));
    }

    @Override
    @Transactional(readOnly = true)
    public Map<OrderStatus, Long> counts() {
        Map<OrderStatus, Long> counts = new EnumMap<>(OrderStatus.class);
        for (OrderStatus s : OrderStatus.values()) {
            counts.put(s, orderRepository.countByStoreIdAndStatus(com.tayran.service.impl.CatalogChanges.DEFAULT_STORE_ID, s));
        }
        return counts;
    }

    // ---- item edits --------------------------------------------------------------------------

    @Override
    @Transactional
    public AdminOrderDto editItems(long adminId, long orderId, EditItemsRequest request) {
        Order order = find(orderId);
        if (order.getStatus() != OrderStatus.PENDING_REVIEW || order.getVersion() != request.version()) {
            throw new BusinessException(TayranConst.ORDER_STATE_CHANGED);
        }
        List<OrderItem> items = new ArrayList<>(itemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId));
        Map<Long, OrderItem> byId = items.stream().collect(Collectors.toMap(OrderItem::getId, i -> i));
        List<String> notes = new ArrayList<>();

        for (ItemEdit edit : request.edits()) {
            OrderItem line = byId.get(edit.lineId());
            if (line == null || !line.getLineStatus().charged()) {
                throw invalid("lineId");
            }
            switch (edit.action()) {
                case "REDUCE" -> {
                    if (edit.qty() == null || edit.qty() < 1 || edit.qty() >= line.getQty()) {
                        throw invalid("qty");
                    }
                    line.setQty(edit.qty());
                    line.setLineStatus(edit.qty() < line.getOriginalQty() ? LineStatus.REDUCED : LineStatus.OK);
                    notes.add(line.getNameAr() + " → " + edit.qty());
                }
                case "REMOVE" -> {
                    line.setQty(0);
                    line.setLineStatus(LineStatus.REMOVED);
                    notes.add("شيل " + line.getNameAr());
                }
                case "REPLACE" -> {
                    if (line.getSubstitutionPref() == SubstitutionPref.REFUND) {
                        throw new BusinessException(TayranConst.REPLACEMENT_NOT_ALLOWED);
                    }
                    if (edit.productId() == null || edit.productId().equals(line.getProductId())) {
                        throw invalid("productId");
                    }
                    int qty = edit.qty() == null ? line.getQty() : edit.qty();
                    if (qty < 1 || qty > line.getQty()) {
                        throw invalid("qty");
                    }
                    CatalogLookup.Sellable product = catalog.find(order.getStoreId(), List.of(edit.productId())).get(edit.productId());
                    if (product == null || !product.canBuy()) {
                        throw invalid("productId");
                    }
                    OrderItem replacement = new OrderItem();
                    replacement.setOrderId(orderId);
                    replacement.setProductId(product.id());
                    replacement.setNameAr(product.nameAr());
                    replacement.setNameEn(product.nameEn());
                    replacement.setSizeLabel(product.sizeLabel());
                    replacement.setImageHash(product.imageHash());
                    // Never more than the customer agreed to pay for the original.
                    replacement.setUnitPrice(OrderPricing.replacementPrice(line.getUnitPrice(), product.price()));
                    replacement.setQty(qty);
                    replacement.setOriginalQty(qty);
                    replacement.setSubstitutionPref(line.getSubstitutionPref());
                    replacement.setLineStatus(LineStatus.OK);
                    replacement.setSortOrder(line.getSortOrder());
                    itemRepository.saveAndFlush(replacement);
                    line.setLineStatus(LineStatus.REPLACED);
                    line.setReplacedByItemId(replacement.getId());
                    items.add(replacement);
                    byId.put(replacement.getId(), replacement);
                    notes.add(line.getNameAr() + " ← " + product.nameAr());
                }
                default -> throw invalid("action");
            }
        }
        if (items.stream().noneMatch(i -> i.getLineStatus().charged())) {
            throw new BusinessException(TayranConst.EMPTY_ORDER);
        }
        itemRepository.saveAll(items);
        OrderPricing.Totals totals = OrderPricing.afterEdit(order, items);
        writer.applyItemEdit(order, request.version(), totals, adminId, truncate(String.join("، ", notes)));
        entityManager.flush();
        entityManager.refresh(order);
        return dto(order);
    }

    // ---- transitions -------------------------------------------------------------------------

    @Override
    @Transactional
    public AdminOrderDto confirm(long adminId, long orderId, int version) {
        return move(adminId, orderId, OrderStatus.CONFIRMED, version, TransitionData.NONE);
    }

    @Override
    @Transactional
    public AdminOrderDto outForDelivery(long adminId, long orderId, OutForDeliveryRequest request) {
        String phone;
        try {
            phone = PhoneUtils.normalize(request.courierPhone());
        } catch (BusinessException e) {
            throw new BusinessException(TayranConst.INVALID_COURIER_PHONE);
        }
        return move(adminId, orderId, OrderStatus.OUT_FOR_DELIVERY, request.version(),
                new TransitionData(request.courierName().strip(), phone, null, null));
    }

    @Override
    @Transactional
    public AdminOrderDto deliver(long adminId, long orderId, DeliverRequest request) {
        return move(adminId, orderId, OrderStatus.DELIVERED, request.version(),
                new TransitionData(null, null, null, request.cashCollected()));
    }

    @Override
    @Transactional
    public AdminOrderDto cancel(long adminId, long orderId, CancelRequest request) {
        return move(adminId, orderId, OrderStatus.CANCELLED, request.version(),
                new TransitionData(null, null, request.reason().strip(), null));
    }

    private AdminOrderDto move(long adminId, long orderId, OrderStatus to, int version, TransitionData data) {
        Order order = find(orderId);
        writer.transition(order, to, ActorType.ADMIN, adminId, version, data);
        entityManager.refresh(order);
        return dto(order);
    }

    // ---- helpers -----------------------------------------------------------------------------

    private Order find(long orderId) {
        return orderRepository.findById(orderId).orElseThrow(() -> new BusinessException(TayranConst.NOT_FOUND));
    }

    private AdminOrderDto dto(Order order) {
        List<OrderEvent> events = eventRepository.findByOrderIdOrderByAtAscIdAsc(order.getId());
        Set<Long> adminIds = events.stream().filter(e -> e.getActorType() == ActorType.ADMIN && e.getActorId() != null)
                .map(OrderEvent::getActorId).collect(Collectors.toSet());
        Map<Long, String> names = new HashMap<>();
        for (User u : userRepository.findAllById(adminIds)) {
            names.put(u.getId(), u.getFirstName());
        }
        return assembler.toAdmin(order, itemRepository.findByOrderIdOrderBySortOrderAscIdAsc(order.getId()), events, names);
    }

    private List<AdminOrderRow> rows(List<Order> orders) {
        if (orders.isEmpty()) {
            return List.of();
        }
        Map<Long, List<OrderItem>> items = itemRepository.findByOrderIdInOrderBySortOrderAscIdAsc(
                orders.stream().map(Order::getId).toList()).stream().collect(Collectors.groupingBy(OrderItem::getOrderId));
        return orders.stream().map(o -> assembler.toAdminRow(o, items.getOrDefault(o.getId(), List.of()))).toList();
    }

    private static BusinessException invalid(String field) {
        return new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of(field)));
    }

    private static String truncate(String s) {
        return s.length() <= 300 ? s : s.substring(0, 297) + "...";
    }
}
