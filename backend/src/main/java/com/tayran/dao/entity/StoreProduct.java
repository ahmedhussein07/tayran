package com.tayran.dao.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;
import java.math.BigDecimal;

/** A product's price and availability in one store. */
@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "store_products")
public class StoreProduct {

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    @Embeddable
    public static class Key implements Serializable {
        @Column(name = "store_id")
        private Long storeId;

        @Column(name = "product_id")
        private Long productId;
    }

    @EmbeddedId
    private Key id;

    @Column(name = "price", nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "old_price", precision = 10, scale = 2)
    private BigDecimal oldPrice;

    @Column(name = "available", nullable = false)
    private boolean available = true;

    public StoreProduct(long storeId, long productId) {
        this.id = new Key(storeId, productId);
    }
}
