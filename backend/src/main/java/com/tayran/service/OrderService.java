package com.tayran.service;

import com.tayran.model.order.OrderDtos.OrderDto;
import com.tayran.model.order.OrderDtos.OrderPage;
import com.tayran.model.order.OrderDtos.OrderSummaryDto;
import com.tayran.model.order.OrderDtos.PlaceOrderRequest;

import java.util.List;

/** The customer's side of orders. Every method is scoped to the calling customer. */
public interface OrderService {

    /** Places an order, or returns the one already placed with the same idempotency key. */
    OrderDto place(long userId, String idempotencyKey, PlaceOrderRequest request);

    OrderPage list(long userId, String cursor);

    OrderDto get(long userId, long orderId);

    OrderDto cancel(long userId, long orderId);

    /** Non-final orders, newest first (for the bootstrap). */
    List<OrderSummaryDto> active(long userId);
}
