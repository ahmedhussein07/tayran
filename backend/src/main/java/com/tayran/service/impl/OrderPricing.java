package com.tayran.service.impl;

import com.tayran.dao.entity.Order;
import com.tayran.dao.entity.OrderItem;
import com.tayran.dao.entity.StoreSettings;
import com.tayran.model.order.PaymentMethod;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collection;

/**
 * The one pricing implementation: order creation, the cart check, admin edits and the app all
 * follow these rules. Money is BigDecimal with two decimals, never floating point.
 */
public final class OrderPricing {

    private OrderPricing() {
    }

    public record Totals(BigDecimal subtotal, BigDecimal deliveryFee, BigDecimal onlineFee, BigDecimal discount, BigDecimal total) {
    }

    /** A priced line for a new order. */
    public record Line(BigDecimal unitPrice, int qty) {
    }

    /**
     * A new order: delivery is free once the subtotal reaches the threshold, the online fee applies
     * only to online payment, and there are no discounts yet.
     */
    public static Totals forNewOrder(Collection<Line> lines, StoreSettings settings, PaymentMethod method) {
        BigDecimal subtotal = money(lines.stream()
                .map(l -> l.unitPrice().multiply(BigDecimal.valueOf(l.qty())))
                .reduce(BigDecimal.ZERO, BigDecimal::add));
        BigDecimal delivery = subtotal.compareTo(settings.getFreeDeliveryThreshold()) >= 0 ? zero() : money(settings.getDeliveryFee());
        BigDecimal online = method == PaymentMethod.ONLINE ? money(settings.getOnlinePaymentFee()) : zero();
        BigDecimal discount = zero();
        return new Totals(subtotal, delivery, online, discount, money(subtotal.add(delivery).add(online).subtract(discount)));
    }

    /**
     * After an admin edit: only charged lines count, and the delivery fee, online fee and discount
     * stay exactly as first charged (free delivery stays free; the minimum isn't re-applied), so
     * the customer never pays more than they agreed to.
     */
    public static Totals afterEdit(Order order, Collection<OrderItem> items) {
        BigDecimal subtotal = money(items.stream()
                .filter(i -> i.getLineStatus().charged())
                .map(i -> i.getUnitPrice().multiply(BigDecimal.valueOf(i.getQty())))
                .reduce(BigDecimal.ZERO, BigDecimal::add));
        BigDecimal total = money(subtotal.add(order.getDeliveryFee()).add(order.getOnlineFee()).subtract(order.getDiscount()));
        if (total.compareTo(order.getOriginalTotal()) > 0) {
            // Unreachable with these rules (lines only shrink, replacements cost no more); kept as a guard.
            throw new IllegalStateException("An edit would raise order " + order.getId() + " above its original total");
        }
        return new Totals(subtotal, order.getDeliveryFee(), order.getOnlineFee(), order.getDiscount(), total);
    }

    /** A replacement is charged at the lower of the original line's price and the replacement's. */
    public static BigDecimal replacementPrice(BigDecimal originalUnitPrice, BigDecimal replacementPrice) {
        return money(originalUnitPrice.min(replacementPrice));
    }

    public static BigDecimal money(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    private static BigDecimal zero() {
        return BigDecimal.ZERO.setScale(2);
    }
}
