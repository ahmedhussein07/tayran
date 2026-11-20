package com.tayran.service.impl.order;

import com.tayran.dao.entity.Order;
import com.tayran.dao.entity.OrderEvent;
import com.tayran.dao.repository.OrderEventRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import com.tayran.model.order.ActorType;
import com.tayran.model.order.EventKind;
import com.tayran.model.order.OrderStatus;
import com.tayran.service.impl.OrderPricing;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Every write to an existing order. Each one is a single conditional
 * {@code UPDATE ... WHERE id = ? AND status = ? [AND version = ?]}: if another writer got there
 * first, 0 rows change and the caller gets 409 ORDER_STATE_CHANGED. Each also records an
 * order_events row and publishes {@link OrderChanged} (acted on after commit). Callers run inside
 * a transaction.
 */
@Component
@RequiredArgsConstructor
public class OrderWriter {

    /** Extra columns set by a transition (null = leave as is). */
    public record TransitionData(String courierName, String courierPhone, String cancelReason, Boolean cashCollected) {
        public static final TransitionData NONE = new TransitionData(null, null, null, null);
    }

    private final JdbcTemplate jdbc;
    private final OrderEventRepository eventRepository;
    private final ApplicationEventPublisher events;
    private final Clock clock;

    /**
     * Moves {@code order} (as the caller loaded it) to {@code to}.
     *
     * @param expectedVersion the version the admin saw; null for the customer (status is checked anyway)
     * @return the new version
     */
    public int transition(Order order, OrderStatus to, ActorType actor, Long actorId, Integer expectedVersion, TransitionData data) {
        if (!order.getStatus().canMoveTo(to, actor) || (expectedVersion != null && expectedVersion != order.getVersion())) {
            throw new BusinessException(TayranConst.ORDER_STATE_CHANGED);
        }
        Instant now = clock.instant();
        StringBuilder sql = new StringBuilder("UPDATE orders SET status = ?, version = version + 1, updated_at = ?");
        List<Object> args = new ArrayList<>(List.of(to.name(), Timestamp.from(now)));
        if (data.courierName() != null) {
            sql.append(", courier_name = ?, courier_phone = ?");
            args.add(data.courierName());
            args.add(data.courierPhone());
        }
        if (data.cancelReason() != null) {
            sql.append(", cancel_reason = ?");
            args.add(data.cancelReason());
        }
        if (data.cashCollected() != null) {
            sql.append(", cash_collected = ?");
            args.add(data.cashCollected());
        }
        sql.append(" WHERE id = ? AND status = ?");
        args.add(order.getId());
        args.add(order.getStatus().name());
        if (expectedVersion != null) {
            sql.append(" AND version = ?");
            args.add(expectedVersion);
        }
        if (actor == ActorType.CUSTOMER) {
            sql.append(" AND user_id = ?");
            args.add(order.getUserId());
        }
        sql.append(" RETURNING version");
        List<Integer> versions = jdbc.queryForList(sql.toString(), Integer.class, args.toArray());
        if (versions.isEmpty()) {
            throw new BusinessException(TayranConst.ORDER_STATE_CHANGED);
        }
        int version = versions.getFirst();
        eventRepository.save(new OrderEvent(order.getId(), EventKind.STATUS, to, actor, actorId, data.cancelReason(), now));
        events.publishEvent(new OrderChanged(order.getId(), order.getOrderNumber(), order.getUserId(), to, version, false, false,
                order.isItemsChanged(), actor, data.cancelReason(), data.courierName()));
        return version;
    }

    /** Saves new totals after an admin item edit; only while PENDING_REVIEW and at the expected version. */
    public int applyItemEdit(Order order, int expectedVersion, OrderPricing.Totals totals, long adminId, String note) {
        Instant now = clock.instant();
        List<Integer> versions = jdbc.queryForList("""
                        UPDATE orders SET subtotal = ?, total = ?, items_changed = TRUE, version = version + 1, updated_at = ?
                        WHERE id = ? AND status = 'PENDING_REVIEW' AND version = ?
                        RETURNING version""", Integer.class,
                totals.subtotal(), totals.total(), Timestamp.from(now), order.getId(), expectedVersion);
        if (versions.isEmpty()) {
            throw new BusinessException(TayranConst.ORDER_STATE_CHANGED);
        }
        int version = versions.getFirst();
        eventRepository.save(new OrderEvent(order.getId(), EventKind.ITEMS_EDITED, OrderStatus.PENDING_REVIEW, ActorType.ADMIN,
                adminId, note, now));
        events.publishEvent(new OrderChanged(order.getId(), order.getOrderNumber(), order.getUserId(), OrderStatus.PENDING_REVIEW,
                version, false, true, true, ActorType.ADMIN, null, null));
        return version;
    }
}
