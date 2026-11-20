package com.tayran.service.impl;

import com.tayran.dao.entity.Order;
import com.tayran.dao.entity.OrderItem;
import com.tayran.dao.entity.StoreSettings;
import com.tayran.model.order.LineStatus;
import com.tayran.model.order.PaymentMethod;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class OrderPricingTest {

    private static StoreSettings settings() {
        StoreSettings s = new StoreSettings();
        s.setDeliveryFee(new BigDecimal("15.00"));
        s.setFreeDeliveryThreshold(new BigDecimal("200.00"));
        s.setMinOrderAmount(new BigDecimal("50.00"));
        s.setOnlinePaymentFee(new BigDecimal("5.00"));
        s.setEtaMinutes(20);
        return s;
    }

    private static OrderPricing.Line line(String price, int qty) {
        return new OrderPricing.Line(new BigDecimal(price), qty);
    }

    @Test
    void deliveryIsChargedBelowTheThresholdAndFreeFromIt() {
        OrderPricing.Totals below = OrderPricing.forNewOrder(List.of(line("99.99", 2)), settings(), PaymentMethod.CASH);
        assertThat(below.subtotal()).isEqualByComparingTo("199.98");
        assertThat(below.deliveryFee()).isEqualByComparingTo("15.00");
        assertThat(below.total()).isEqualByComparingTo("214.98");

        OrderPricing.Totals exactly = OrderPricing.forNewOrder(List.of(line("100.00", 2)), settings(), PaymentMethod.CASH);
        assertThat(exactly.deliveryFee()).isEqualByComparingTo("0.00");
        assertThat(exactly.total()).isEqualByComparingTo("200.00");
    }

    @Test
    void onlineFeeOnlyForOnlinePayment() {
        OrderPricing.Totals cash = OrderPricing.forNewOrder(List.of(line("60.00", 1)), settings(), PaymentMethod.CASH);
        OrderPricing.Totals online = OrderPricing.forNewOrder(List.of(line("60.00", 1)), settings(), PaymentMethod.ONLINE);
        assertThat(cash.onlineFee()).isEqualByComparingTo("0.00");
        assertThat(online.onlineFee()).isEqualByComparingTo("5.00");
        assertThat(online.total()).isEqualByComparingTo(cash.total().add(new BigDecimal("5.00")));
    }

    @Test
    void moneyStaysExactWithTwoDecimals() {
        OrderPricing.Totals t = OrderPricing.forNewOrder(List.of(line("0.10", 3), line("12.35", 7)), settings(), PaymentMethod.CASH);
        assertThat(t.subtotal()).isEqualByComparingTo("86.75");
        assertThat(t.subtotal().scale()).isEqualTo(2);
    }

    @Test
    void editsKeepTheOriginalFeesAndNeverRaiseTheTotal() {
        // Free delivery at 210; after the edit the subtotal drops below the threshold, delivery stays free.
        Order order = new Order();
        order.setId(1L);
        order.setDeliveryFee(new BigDecimal("0.00"));
        order.setOnlineFee(new BigDecimal("5.00"));
        order.setDiscount(new BigDecimal("0.00"));
        order.setOriginalTotal(new BigDecimal("215.00"));
        List<OrderItem> items = List.of(item("70.00", 2, LineStatus.REDUCED), item("70.00", 1, LineStatus.REMOVED),
                item("10.00", 1, LineStatus.REPLACED), item("8.00", 1, LineStatus.OK));
        OrderPricing.Totals t = OrderPricing.afterEdit(order, items);
        assertThat(t.subtotal()).isEqualByComparingTo("148.00");
        assertThat(t.deliveryFee()).isEqualByComparingTo("0.00");
        assertThat(t.onlineFee()).isEqualByComparingTo("5.00");
        assertThat(t.total()).isEqualByComparingTo("153.00").isLessThanOrEqualTo(order.getOriginalTotal());
    }

    @Test
    void aChargedDeliveryFeeIsNotAddedTwiceOrChangedByAnEdit() {
        Order order = new Order();
        order.setId(2L);
        order.setDeliveryFee(new BigDecimal("15.00"));
        order.setOnlineFee(new BigDecimal("0.00"));
        order.setDiscount(new BigDecimal("0.00"));
        order.setOriginalTotal(new BigDecimal("75.00"));
        OrderPricing.Totals t = OrderPricing.afterEdit(order, List.of(item("30.00", 1, LineStatus.REDUCED)));
        assertThat(t.total()).isEqualByComparingTo("45.00");
    }

    @Test
    void aReplacementCostsTheLowerOfTheTwoPrices() {
        assertThat(OrderPricing.replacementPrice(new BigDecimal("25.00"), new BigDecimal("30.00"))).isEqualByComparingTo("25.00");
        assertThat(OrderPricing.replacementPrice(new BigDecimal("25.00"), new BigDecimal("19.50"))).isEqualByComparingTo("19.50");
    }

    private static OrderItem item(String price, int qty, LineStatus status) {
        OrderItem i = new OrderItem();
        i.setUnitPrice(new BigDecimal(price));
        i.setQty(qty);
        i.setLineStatus(status);
        return i;
    }
}
