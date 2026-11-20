package com.tayran.service.impl.order;

import com.tayran.model.order.ActorType;
import com.tayran.model.order.OrderStatus;

/**
 * Published inside the transaction that changed an order; listeners act on it only after the
 * commit (push notifications, the admin live feed).
 *
 * @param created      a new order (NEW on the admin feed, no push)
 * @param itemsEdited  this change was an item edit (no status change)
 * @param itemsChanged the order's items differ from what the customer ordered
 */
public record OrderChanged(long orderId, long number, long userId, OrderStatus status, int version, boolean created,
                           boolean itemsEdited, boolean itemsChanged, ActorType actor, String cancelReason, String courierName) {
}
