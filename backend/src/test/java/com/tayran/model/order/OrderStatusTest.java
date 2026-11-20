package com.tayran.model.order;

import org.junit.jupiter.api.Test;

import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/** Every allowed transition is allowed, and every other pair is refused. */
class OrderStatusTest {

    private static final Map<OrderStatus, Set<OrderStatus>> ADMIN_ALLOWED = Map.of(
            OrderStatus.PENDING_REVIEW, EnumSet.of(OrderStatus.CONFIRMED, OrderStatus.CANCELLED),
            OrderStatus.CONFIRMED, EnumSet.of(OrderStatus.OUT_FOR_DELIVERY, OrderStatus.CANCELLED),
            OrderStatus.OUT_FOR_DELIVERY, EnumSet.of(OrderStatus.DELIVERED),
            OrderStatus.DELIVERED, EnumSet.noneOf(OrderStatus.class),
            OrderStatus.CANCELLED, EnumSet.noneOf(OrderStatus.class));

    @Test
    void adminTransitionsMatchTheLifecycleExactly() {
        for (OrderStatus from : OrderStatus.values()) {
            for (OrderStatus to : OrderStatus.values()) {
                assertThat(from.canMoveTo(to, ActorType.ADMIN))
                        .as("admin %s -> %s", from, to)
                        .isEqualTo(ADMIN_ALLOWED.get(from).contains(to));
            }
        }
    }

    @Test
    void customerMayOnlyCancelWhileWaitingForReview() {
        for (OrderStatus from : OrderStatus.values()) {
            for (OrderStatus to : OrderStatus.values()) {
                boolean allowed = from == OrderStatus.PENDING_REVIEW && to == OrderStatus.CANCELLED;
                assertThat(from.canMoveTo(to, ActorType.CUSTOMER)).as("customer %s -> %s", from, to).isEqualTo(allowed);
            }
        }
    }

    @Test
    void systemNeverMovesOrders() {
        for (OrderStatus from : OrderStatus.values()) {
            for (OrderStatus to : OrderStatus.values()) {
                assertThat(from.canMoveTo(to, ActorType.SYSTEM)).isFalse();
            }
        }
    }

    @Test
    void stagesAndFinalStates() {
        assertThat(OrderStatus.PENDING_REVIEW.stage()).isEqualTo(1);
        assertThat(OrderStatus.CONFIRMED.stage()).isEqualTo(2);
        assertThat(OrderStatus.OUT_FOR_DELIVERY.stage()).isEqualTo(3);
        assertThat(OrderStatus.DELIVERED.stage()).isEqualTo(4);
        assertThat(OrderStatus.CANCELLED.stage()).isZero();
        assertThat(EnumSet.allOf(OrderStatus.class).stream().filter(OrderStatus::isFinal))
                .containsExactlyInAnyOrder(OrderStatus.DELIVERED, OrderStatus.CANCELLED);
    }
}
