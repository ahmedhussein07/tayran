package com.tayran.service.impl.order;

import com.tayran.dao.entity.Order;
import com.tayran.dao.entity.OrderEvent;
import com.tayran.dao.entity.OrderItem;
import com.tayran.model.order.ActorType;
import com.tayran.model.order.CustomerSnapshot;
import com.tayran.model.order.EventKind;
import com.tayran.model.order.OrderDtos.AdminEventDto;
import com.tayran.model.order.OrderDtos.AdminOrderDto;
import com.tayran.model.order.OrderDtos.AdminOrderRow;
import com.tayran.model.order.OrderDtos.Courier;
import com.tayran.model.order.OrderDtos.DeliveryAddress;
import com.tayran.model.order.OrderDtos.OrderDto;
import com.tayran.model.order.OrderDtos.OrderItemDto;
import com.tayran.model.order.OrderDtos.OrderSummaryDto;
import com.tayran.model.order.OrderDtos.StageTime;
import com.tayran.model.order.OrderStatus;
import com.tayran.service.impl.OrderPricing;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Orders as the customer app and the admin portal see them. */
@Component
@RequiredArgsConstructor
public class OrderAssembler {

    private final ObjectMapper objectMapper;
    private final com.tayran.config.properties.StorageProperties storageProperties;

    public CustomerSnapshot snapshot(Order order) {
        return objectMapper.readValue(order.getCustomerSnapshot(), CustomerSnapshot.class);
    }

    public String snapshotJson(CustomerSnapshot snapshot) {
        return objectMapper.writeValueAsString(snapshot);
    }

    public OrderDto toDto(Order order, List<OrderItem> items, List<OrderEvent> events) {
        CustomerSnapshot snapshot = snapshot(order);
        return new OrderDto(order.getId(), order.getOrderNumber(), order.getStatus(), order.getStatus().stage(),
                order.getPaymentMethod(), order.getCreatedAt(), order.getEtaMinutes(), expectedAt(order),
                order.getSubtotal(), order.getDeliveryFee(), order.getOnlineFee(), order.getDiscount(), order.getTotal(),
                order.getOriginalTotal(), order.isItemsChanged(), order.getCashChangeFor(), order.getNotes(),
                DeliveryAddress.of(snapshot), courier(order), order.getCancelReason(), cancelledBy(order, events),
                order.getVersion(), itemCount(items), items(items), timeline(events));
    }

    public OrderSummaryDto toSummary(Order order, List<OrderItem> items) {
        List<String> images = items.stream()
                .filter(i -> i.getLineStatus().charged() && i.getImageHash() != null)
                .map(OrderItem::getImageHash).distinct().limit(4).toList();
        return new OrderSummaryDto(order.getId(), order.getOrderNumber(), order.getStatus(), order.getStatus().stage(),
                order.getTotal(), itemCount(items), images, order.getCreatedAt(), order.getEtaMinutes(), expectedAt(order),
                order.getVersion());
    }

    public AdminOrderDto toAdmin(Order order, List<OrderItem> items, List<OrderEvent> events, Map<Long, String> adminNames) {
        List<AdminEventDto> eventDtos = events.stream()
                .map(e -> new AdminEventDto(e.getKind(), e.getStatus(), e.getActorType(), e.getActorId(),
                        e.getActorType() == ActorType.ADMIN ? adminNames.get(e.getActorId()) : null, e.getNote(), e.getAt()))
                .toList();
        Courier courier = order.getCourierName() == null ? null : new Courier(order.getCourierName(), order.getCourierPhone());
        return new AdminOrderDto(order.getId(), order.getOrderNumber(), order.getStatus(), order.getStatus().stage(),
                order.getPaymentMethod(), order.getCreatedAt(), order.getEtaMinutes(), snapshot(order), order.getNotes(),
                order.getCashChangeFor(), order.getSubtotal(), order.getDeliveryFee(), order.getOnlineFee(),
                order.getDiscount(), order.getTotal(), order.getOriginalTotal(), order.isItemsChanged(), courier,
                order.getCancelReason(), order.getCashCollected(), order.getVersion(), items(items), eventDtos);
    }

    public AdminOrderRow toAdminRow(Order order, List<OrderItem> items) {
        CustomerSnapshot s = snapshot(order);
        String name = (s.firstName() == null ? "" : s.firstName()) + (s.lastName() == null ? "" : " " + s.lastName());
        return new AdminOrderRow(order.getId(), order.getOrderNumber(), order.getStatus(), name.strip(), s.phone(),
                s.villageNameAr(), itemCount(items), order.getTotal(), order.getPaymentMethod(), order.getCreatedAt(),
                order.getVersion());
    }

    /** Units the customer will receive (charged lines only). */
    public static int itemCount(List<OrderItem> items) {
        return items.stream().filter(i -> i.getLineStatus().charged()).mapToInt(OrderItem::getQty).sum();
    }

    private List<OrderItemDto> items(List<OrderItem> items) {
        Set<Long> replacements = new HashSet<>();
        items.forEach(i -> {
            if (i.getReplacedByItemId() != null) {
                replacements.add(i.getReplacedByItemId());
            }
        });
        List<OrderItemDto> out = new ArrayList<>();
        for (OrderItem i : items) {
            BigDecimal lineTotal = i.getLineStatus().charged()
                    ? OrderPricing.money(i.getUnitPrice().multiply(BigDecimal.valueOf(i.getQty())))
                    : BigDecimal.ZERO.setScale(2);
            out.add(new OrderItemDto(i.getId(), i.getProductId(), i.getNameAr(), i.getNameEn(), i.getSizeLabel(),
                    i.getImageHash(), i.getUnitPrice(), i.getQty(), i.getOriginalQty(), i.getSubstitutionPref(),
                    i.getLineStatus(), i.getReplacedByItemId(), replacements.contains(i.getId()), lineTotal,
                    i.getImageHash() == null ? null
                            : storageProperties.url(com.tayran.model.ImageKind.PRODUCT.key(i.getImageHash(), 160))));
        }
        return out;
    }

    /** First time each status was reached. */
    private static List<StageTime> timeline(List<OrderEvent> events) {
        List<StageTime> out = new ArrayList<>();
        Set<OrderStatus> seen = new HashSet<>();
        for (OrderEvent e : events) {
            if (e.getKind() == EventKind.STATUS && seen.add(e.getStatus())) {
                out.add(new StageTime(e.getStatus(), e.getStatus().stage(), e.getAt()));
            }
        }
        return out;
    }

    /** The courier is shown once the order is on its way. */
    private static Courier courier(Order order) {
        boolean shown = order.getStatus() == OrderStatus.OUT_FOR_DELIVERY || order.getStatus() == OrderStatus.DELIVERED;
        return shown && order.getCourierName() != null ? new Courier(order.getCourierName(), order.getCourierPhone()) : null;
    }

    private static ActorType cancelledBy(Order order, List<OrderEvent> events) {
        if (order.getStatus() != OrderStatus.CANCELLED) {
            return null;
        }
        return events.stream().filter(e -> e.getKind() == EventKind.STATUS && e.getStatus() == OrderStatus.CANCELLED)
                .map(OrderEvent::getActorType).findFirst().orElse(null);
    }

    private static Instant expectedAt(Order order) {
        return order.getCreatedAt().plus(Duration.ofMinutes(order.getEtaMinutes()));
    }
}
