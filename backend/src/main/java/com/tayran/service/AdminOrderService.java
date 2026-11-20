package com.tayran.service;

import com.tayran.model.order.OrderDtos.AdminOrderDto;
import com.tayran.model.order.OrderDtos.AdminOrderPage;
import com.tayran.model.order.OrderDtos.CancelRequest;
import com.tayran.model.order.OrderDtos.DeliverRequest;
import com.tayran.model.order.OrderDtos.EditItemsRequest;
import com.tayran.model.order.OrderDtos.OutForDeliveryRequest;
import com.tayran.model.order.OrderStatus;

import java.util.Map;

/** The store's side of orders. Every change checks the version the admin saw. */
public interface AdminOrderService {

    AdminOrderPage list(OrderStatus status, String cursor, String search);

    AdminOrderDto get(long orderId);

    AdminOrderDto editItems(long adminId, long orderId, EditItemsRequest request);

    AdminOrderDto confirm(long adminId, long orderId, int version);

    AdminOrderDto outForDelivery(long adminId, long orderId, OutForDeliveryRequest request);

    AdminOrderDto deliver(long adminId, long orderId, DeliverRequest request);

    AdminOrderDto cancel(long adminId, long orderId, CancelRequest request);

    /** Orders per status, for the board's tab badges. */
    Map<OrderStatus, Long> counts();
}
