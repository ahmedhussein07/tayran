package com.tayran.model.order;

import java.util.Map;
import java.util.Set;

/**
 * The order lifecycle. Each state maps to the customer-facing tracking stage (1-4; 0 for
 * cancelled). DELIVERED and CANCELLED are final.
 */
public enum OrderStatus {
    PENDING_REVIEW(1),
    CONFIRMED(2),
    OUT_FOR_DELIVERY(3),
    DELIVERED(4),
    CANCELLED(0);

    private static final Map<OrderStatus, Set<OrderStatus>> ADMIN_MOVES = Map.of(
            PENDING_REVIEW, Set.of(CONFIRMED, CANCELLED),
            CONFIRMED, Set.of(OUT_FOR_DELIVERY, CANCELLED),
            OUT_FOR_DELIVERY, Set.of(DELIVERED));

    private final int stage;

    OrderStatus(int stage) {
        this.stage = stage;
    }

    public int stage() {
        return stage;
    }

    public boolean isFinal() {
        return this == DELIVERED || this == CANCELLED;
    }

    /** Whether {@code actor} may move an order from this state to {@code target}. */
    public boolean canMoveTo(OrderStatus target, ActorType actor) {
        return switch (actor) {
            case ADMIN -> ADMIN_MOVES.getOrDefault(this, Set.of()).contains(target);
            case CUSTOMER -> this == PENDING_REVIEW && target == CANCELLED;
            case SYSTEM -> false;
        };
    }
}
