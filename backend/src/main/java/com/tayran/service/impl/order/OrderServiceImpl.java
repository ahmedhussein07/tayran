package com.tayran.service.impl.order;

import com.tayran.dao.entity.Address;
import com.tayran.dao.entity.Order;
import com.tayran.dao.entity.OrderEvent;
import com.tayran.dao.entity.OrderItem;
import com.tayran.dao.entity.StoreSettings;
import com.tayran.dao.entity.User;
import com.tayran.dao.repository.AddressRepository;
import com.tayran.dao.repository.OrderEventRepository;
import com.tayran.dao.repository.OrderItemRepository;
import com.tayran.dao.repository.OrderRepository;
import com.tayran.dao.repository.UserRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import com.tayran.model.order.ActorType;
import com.tayran.model.order.CustomerSnapshot;
import com.tayran.model.order.EventKind;
import com.tayran.model.order.LineStatus;
import com.tayran.model.order.OrderDtos.CartChanged;
import com.tayran.model.order.OrderDtos.CartLine;
import com.tayran.model.order.OrderDtos.CartLineCheck;
import com.tayran.model.order.OrderDtos.OrderDto;
import com.tayran.model.order.OrderDtos.OrderPage;
import com.tayran.model.order.OrderDtos.OrderSummaryDto;
import com.tayran.model.order.OrderDtos.PlaceOrderRequest;
import com.tayran.model.order.OrderStatus;
import com.tayran.model.order.PaymentMethod;
import com.tayran.model.order.SubstitutionPref;
import com.tayran.service.OrderService;
import com.tayran.service.impl.OrderPricing;
import com.tayran.service.impl.StoreSettingsService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
public class OrderServiceImpl implements OrderService {

    static final int PAGE_SIZE = 20;
    private static final EnumSet<OrderStatus> ACTIVE = EnumSet.of(OrderStatus.PENDING_REVIEW, OrderStatus.CONFIRMED,
            OrderStatus.OUT_FOR_DELIVERY);

    private final OrderRepository orderRepository;
    private final OrderItemRepository itemRepository;
    private final OrderEventRepository eventRepository;
    private final AddressRepository addressRepository;
    private final UserRepository userRepository;
    private final StoreSettingsService settingsService;
    private final CatalogLookup catalog;
    private final OrderAssembler assembler;
    private final OrderWriter writer;
    private final ApplicationEventPublisher events;
    private final ObjectMapper objectMapper;
    private final TransactionTemplate tx;
    private final Clock clock;
    private final boolean onlinePaymentEnabled;

    @jakarta.persistence.PersistenceContext
    private jakarta.persistence.EntityManager entityManager;

    public OrderServiceImpl(OrderRepository orderRepository, OrderItemRepository itemRepository, OrderEventRepository eventRepository,
                            AddressRepository addressRepository, UserRepository userRepository, StoreSettingsService settingsService,
                            CatalogLookup catalog, OrderAssembler assembler, OrderWriter writer, ApplicationEventPublisher events,
                            ObjectMapper objectMapper, PlatformTransactionManager transactionManager, Clock clock,
                            @Value("${payments.online.enabled:false}") boolean onlinePaymentEnabled) {
        this.orderRepository = orderRepository;
        this.itemRepository = itemRepository;
        this.eventRepository = eventRepository;
        this.addressRepository = addressRepository;
        this.userRepository = userRepository;
        this.settingsService = settingsService;
        this.catalog = catalog;
        this.assembler = assembler;
        this.writer = writer;
        this.events = events;
        this.objectMapper = objectMapper;
        this.tx = new TransactionTemplate(transactionManager);
        this.clock = clock;
        this.onlinePaymentEnabled = onlinePaymentEnabled;
    }

    // ---- place -------------------------------------------------------------------------------

    @Override
    public OrderDto place(long userId, String idempotencyKey, PlaceOrderRequest request) {
        String key = idempotencyKey == null ? "" : idempotencyKey.strip();
        if (key.isEmpty() || key.length() > 64) {
            throw new BusinessException(TayranConst.IDEMPOTENCY_KEY_REQUIRED);
        }
        // A repeated attempt returns what the first one created, whatever it carries now.
        OrderDto existing = findByKey(userId, key);
        if (existing != null) {
            return existing;
        }
        try {
            return tx.execute(status -> create(userId, key, request));
        } catch (DataIntegrityViolationException e) {
            // The same key raced in from a second request: the first one won; return its order.
            OrderDto winner = findByKey(userId, key);
            if (winner != null) {
                return winner;
            }
            throw e;
        }
    }

    private OrderDto findByKey(long userId, String key) {
        return tx.execute(status -> orderRepository.findByUserIdAndIdempotencyKey(userId, key).map(this::dto).orElse(null));
    }

    private OrderDto create(long userId, String key, PlaceOrderRequest request) {
        if (request.paymentMethod() == PaymentMethod.ONLINE && !onlinePaymentEnabled) {
            throw new BusinessException(TayranConst.PAYMENT_METHOD_NOT_AVAILABLE);
        }
        if (request.paymentMethod() == PaymentMethod.ONLINE && request.cashChangeFor() != null) {
            throw new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of("cashChangeFor")));
        }
        Address address = addressRepository.findLive(request.addressId(), userId)
                .orElseThrow(() -> new BusinessException(TayranConst.INVALID_ADDRESS));
        User user = userRepository.findById(userId).orElseThrow(() -> new BusinessException(TayranConst.UNAUTHORIZED));
        long storeId = address.getVillage().getStoreId();
        StoreSettings settings = settingsService.get(storeId);

        // Merge repeated products (sum quantities; the first line's preference and shown price win).
        Map<Long, CartLine> lines = new LinkedHashMap<>();
        for (CartLine line : request.items()) {
            lines.merge(line.productId(), line, (a, b) -> new CartLine(a.productId(), Math.min(99, a.qty() + b.qty()),
                    a.substitutionPref(), a.unitPrice()));
        }
        Map<Long, CatalogLookup.Sellable> products = catalog.find(storeId, lines.keySet());

        // Re-check every line against the catalog as it is now.
        List<CartLineCheck> checks = new ArrayList<>();
        List<OrderPricing.Line> priced = new ArrayList<>();
        boolean changed = false;
        for (CartLine line : lines.values()) {
            CatalogLookup.Sellable product = products.get(line.productId());
            if (product == null || !product.canBuy()) {
                checks.add(new CartLineCheck(line.productId(), "UNAVAILABLE", null, line.unitPrice(), line.qty()));
                changed = true;
                continue;
            }
            BigDecimal price = OrderPricing.money(product.price());
            if (line.unitPrice() != null && line.unitPrice().compareTo(price) != 0) {
                checks.add(new CartLineCheck(line.productId(), "PRICE_CHANGED", price, line.unitPrice(), line.qty()));
                changed = true;
            } else {
                checks.add(new CartLineCheck(line.productId(), "OK", price, null, line.qty()));
            }
            priced.add(new OrderPricing.Line(price, line.qty()));
        }
        OrderPricing.Totals totals = OrderPricing.forNewOrder(priced, settings, request.paymentMethod());
        if (changed || totals.total().compareTo(OrderPricing.money(request.expectedTotal())) != 0) {
            CartChanged content = new CartChanged(checks, totals.subtotal(), totals.deliveryFee(), totals.onlineFee(),
                    totals.total(), settings.getMinOrderAmount());
            throw new BusinessException(TayranConst.CART_CHANGED, contentOf(content));
        }
        if (totals.subtotal().compareTo(settings.getMinOrderAmount()) < 0) {
            throw new BusinessException(TayranConst.MIN_ORDER_NOT_MET,
                    Map.of("minOrderAmount", settings.getMinOrderAmount(), "subtotal", totals.subtotal()));
        }
        if (request.cashChangeFor() != null && request.cashChangeFor().compareTo(totals.total()) < 0) {
            throw new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of("cashChangeFor")));
        }

        Instant now = clock.instant();
        Order order = new Order();
        order.setUserId(userId);
        order.setStoreId(storeId);
        order.setStatus(OrderStatus.PENDING_REVIEW);
        order.setPaymentMethod(request.paymentMethod());
        order.setCustomerSnapshot(assembler.snapshotJson(new CustomerSnapshot(user.getFirstName(), user.getLastName(), user.getPhone(),
                address.getVillage().getId(), address.getVillage().getNameAr(), address.getVillage().getNameEn(),
                address.getStreet().getId(), address.getStreet().getNameAr(), address.getStreet().getNameEn(),
                address.getLandmark(), address.getLabel())));
        order.setAddressId(address.getId());
        order.setNotes(blankToNull(request.notes()));
        order.setCashChangeFor(request.cashChangeFor() == null ? null : OrderPricing.money(request.cashChangeFor()));
        order.setSubtotal(totals.subtotal());
        order.setDeliveryFee(totals.deliveryFee());
        order.setOnlineFee(totals.onlineFee());
        order.setDiscount(totals.discount());
        order.setTotal(totals.total());
        order.setOriginalTotal(totals.total());
        order.setEtaMinutes(settings.getEtaMinutes());
        order.setIdempotencyKey(key);
        order.setVersion(0);
        order.setCreatedAt(now);
        order.setUpdatedAt(now);
        orderRepository.saveAndFlush(order);

        int sort = 0;
        List<OrderItem> items = new ArrayList<>();
        for (CartLine line : lines.values()) {
            CatalogLookup.Sellable p = products.get(line.productId());
            OrderItem item = new OrderItem();
            item.setOrderId(order.getId());
            item.setProductId(p.id());
            item.setNameAr(p.nameAr());
            item.setNameEn(p.nameEn());
            item.setSizeLabel(p.sizeLabel());
            item.setImageHash(p.imageHash());
            item.setUnitPrice(OrderPricing.money(p.price()));
            item.setQty(line.qty());
            item.setOriginalQty(line.qty());
            item.setSubstitutionPref(line.substitutionPref() == null ? SubstitutionPref.REPLACE : line.substitutionPref());
            item.setLineStatus(LineStatus.OK);
            item.setSortOrder(sort++);
            items.add(item);
        }
        itemRepository.saveAll(items);
        OrderEvent placed = eventRepository.save(new OrderEvent(order.getId(), EventKind.STATUS, OrderStatus.PENDING_REVIEW,
                ActorType.CUSTOMER, userId, null, now));
        events.publishEvent(new OrderChanged(order.getId(), order.getOrderNumber(), userId, OrderStatus.PENDING_REVIEW, 0,
                true, false, false, ActorType.CUSTOMER, null, null));
        return assembler.toDto(order, items, List.of(placed));
    }

    // ---- read --------------------------------------------------------------------------------

    @Override
    @Transactional(readOnly = true)
    public OrderPage list(long userId, String cursor) {
        PageRequest page = PageRequest.of(0, PAGE_SIZE + 1);
        List<Order> orders;
        if (cursor == null || cursor.isBlank()) {
            orders = orderRepository.findFirstPage(userId, page);
        } else {
            Cursor c = Cursor.parse(cursor);
            orders = orderRepository.findPageBefore(userId, c.at(), c.id(), page);
        }
        String next = null;
        if (orders.size() > PAGE_SIZE) {
            orders = orders.subList(0, PAGE_SIZE);
            Order last = orders.getLast();
            next = new Cursor(last.getCreatedAt(), last.getId()).encode();
        }
        return new OrderPage(summaries(orders), next);
    }

    @Override
    @Transactional(readOnly = true)
    public OrderDto get(long userId, long orderId) {
        return dto(own(userId, orderId));
    }

    @Override
    @Transactional
    public OrderDto cancel(long userId, long orderId) {
        Order order = own(userId, orderId);
        writer.transition(order, OrderStatus.CANCELLED, ActorType.CUSTOMER, userId, null, OrderWriter.TransitionData.NONE);
        // The conditional update bypassed the persistence context; reload what the database has now.
        entityManager.refresh(order);
        return dto(order);
    }

    @Override
    @Transactional(readOnly = true)
    public List<OrderSummaryDto> active(long userId) {
        return summaries(orderRepository.findByUserIdAndStatusInOrderByCreatedAtDesc(userId, ACTIVE));
    }

    // ---- helpers -----------------------------------------------------------------------------

    /** Another customer's order looks the same as one that doesn't exist. */
    private Order own(long userId, long orderId) {
        return orderRepository.findByIdAndUserId(orderId, userId).orElseThrow(() -> new BusinessException(TayranConst.NOT_FOUND));
    }

    private OrderDto dto(Order order) {
        return assembler.toDto(order, itemRepository.findByOrderIdOrderBySortOrderAscIdAsc(order.getId()),
                eventRepository.findByOrderIdOrderByAtAscIdAsc(order.getId()));
    }

    private List<OrderSummaryDto> summaries(List<Order> orders) {
        if (orders.isEmpty()) {
            return List.of();
        }
        Map<Long, List<OrderItem>> items = itemRepository.findByOrderIdInOrderBySortOrderAscIdAsc(
                orders.stream().map(Order::getId).toList()).stream().collect(Collectors.groupingBy(OrderItem::getOrderId));
        return orders.stream().map(o -> assembler.toSummary(o, items.getOrDefault(o.getId(), List.of()))).toList();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> contentOf(Object value) {
        return objectMapper.convertValue(value, Map.class);
    }

    private static String blankToNull(String s) {
        return s == null || s.isBlank() ? null : s.strip();
    }

    /** Opaque paging cursor: base64url of "createdAt|id". */
    record Cursor(Instant at, long id) {
        String encode() {
            return Base64.getUrlEncoder().withoutPadding().encodeToString((at + "|" + id).getBytes(StandardCharsets.UTF_8));
        }

        static Cursor parse(String value) {
            try {
                String[] parts = new String(Base64.getUrlDecoder().decode(value), StandardCharsets.UTF_8).split("\\|");
                return new Cursor(Instant.parse(parts[0]), Long.parseLong(parts[1]));
            } catch (RuntimeException e) {
                throw new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of("cursor")));
            }
        }
    }
}
