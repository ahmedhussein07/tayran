package com.tayran.dao.entity;

import com.tayran.model.order.LineStatus;
import com.tayran.model.order.SubstitutionPref;
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

import java.math.BigDecimal;

/** One order line, with the product as it was when ordered. */
@Getter
@Setter
@Entity
@Table(name = "order_items")
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false, updatable = false)
    private Long orderId;

    @Column(name = "product_id", nullable = false, updatable = false)
    private Long productId;

    @Column(name = "name_ar", nullable = false, length = 100, updatable = false)
    private String nameAr;

    @Column(name = "name_en", nullable = false, length = 100, updatable = false)
    private String nameEn;

    @Column(name = "size_label", nullable = false, length = 40, updatable = false)
    private String sizeLabel;

    @Column(name = "image_hash", length = 12, updatable = false)
    private String imageHash;

    @Column(name = "unit_price", nullable = false, precision = 10, scale = 2, updatable = false)
    private BigDecimal unitPrice;

    @Column(name = "qty", nullable = false)
    private int qty;

    @Column(name = "original_qty", nullable = false, updatable = false)
    private int originalQty;

    @Enumerated(EnumType.STRING)
    @Column(name = "substitution_pref", nullable = false, length = 10, updatable = false)
    private SubstitutionPref substitutionPref;

    @Enumerated(EnumType.STRING)
    @Column(name = "line_status", nullable = false, length = 10)
    private LineStatus lineStatus = LineStatus.OK;

    @Column(name = "replaced_by_item_id")
    private Long replacedByItemId;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;
}
