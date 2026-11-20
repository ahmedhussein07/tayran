package com.tayran.dao.entity;

import com.tayran.model.order.OrderStatus;
import com.tayran.model.order.PaymentMethod;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnTransformer;
import org.hibernate.annotations.Generated;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * A customer order. Status changes and version bumps go through conditional updates in
 * {@code OrderRepository}, never through dirty checking, so two writers can't both win.
 */
@Getter
@Setter
@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** From order_number_seq (starts at 10001). */
    @Generated
    @Column(name = "order_number", insertable = false, updatable = false)
    private Long orderNumber;

    @Column(name = "user_id", nullable = false, updatable = false)
    private Long userId;

    @Column(name = "store_id", nullable = false, updatable = false)
    private Long storeId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20, updatable = false)
    private OrderStatus status;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", nullable = false, length = 10, updatable = false)
    private PaymentMethod paymentMethod;

    /** JSON of {@code CustomerSnapshot}; written as jsonb. */
    @ColumnTransformer(write = "?::jsonb")
    @Column(name = "customer_snapshot", nullable = false, updatable = false, columnDefinition = "jsonb")
    private String customerSnapshot;

    @Column(name = "address_id", updatable = false)
    private Long addressId;

    @Column(name = "notes", length = 300, updatable = false)
    private String notes;

    @Column(name = "cash_change_for", precision = 10, scale = 2, updatable = false)
    private BigDecimal cashChangeFor;

    @Column(name = "subtotal", nullable = false, precision = 10, scale = 2, updatable = false)
    private BigDecimal subtotal;

    @Column(name = "delivery_fee", nullable = false, precision = 10, scale = 2, updatable = false)
    private BigDecimal deliveryFee;

    @Column(name = "online_fee", nullable = false, precision = 10, scale = 2, updatable = false)
    private BigDecimal onlineFee;

    @Column(name = "discount", nullable = false, precision = 10, scale = 2, updatable = false)
    private BigDecimal discount;

    @Column(name = "total", nullable = false, precision = 10, scale = 2, updatable = false)
    private BigDecimal total;

    @Column(name = "original_total", nullable = false, precision = 10, scale = 2, updatable = false)
    private BigDecimal originalTotal;

    @Column(name = "items_changed", nullable = false, updatable = false)
    private boolean itemsChanged;

    @Column(name = "eta_minutes", nullable = false, updatable = false)
    private int etaMinutes;

    @Column(name = "courier_name", length = 50, updatable = false)
    private String courierName;

    @Column(name = "courier_phone", length = 13, updatable = false)
    private String courierPhone;

    @Column(name = "cancel_reason", length = 300, updatable = false)
    private String cancelReason;

    @Column(name = "cash_collected", updatable = false)
    private Boolean cashCollected;

    @Column(name = "idempotency_key", nullable = false, length = 64, updatable = false)
    private String idempotencyKey;

    @Column(name = "version", nullable = false, updatable = false)
    private int version;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false, updatable = false)
    private Instant updatedAt;
}
