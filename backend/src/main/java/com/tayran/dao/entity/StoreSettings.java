package com.tayran.dao.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/** Fees, thresholds and the delivery promise for a store; edited in the admin portal. */
@Getter
@Setter
@Entity
@Table(name = "store_settings")
public class StoreSettings {

    @Id
    @Column(name = "store_id")
    private Long storeId;

    @Column(name = "delivery_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal deliveryFee;

    @Column(name = "free_delivery_threshold", nullable = false, precision = 10, scale = 2)
    private BigDecimal freeDeliveryThreshold;

    @Column(name = "min_order_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal minOrderAmount;

    @Column(name = "online_payment_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal onlinePaymentFee;

    @Column(name = "eta_minutes", nullable = false)
    private int etaMinutes;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "updated_by")
    private Long updatedBy;
}
