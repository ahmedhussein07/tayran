package com.tayran.service.impl.order;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.sql.Array;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

/**
 * Products as the customer can buy them right now in a store: visible in the catalog (product,
 * subcategory and category active, not deleted) with a store price, and whether it's available.
 */
@Component
@RequiredArgsConstructor
public class CatalogLookup {

    /** price is null when the product has no price in this store. */
    public record Sellable(long id, String nameAr, String nameEn, String sizeLabel, String imageHash, BigDecimal price,
                           boolean visible, boolean available) {
        public boolean canBuy() {
            return visible && available && price != null;
        }
    }

    private static final String QUERY = """
            SELECT p.id, p.name_ar, p.name_en, p.size_label, p.image_hash, sp.price, COALESCE(sp.available, FALSE) available,
                   (p.active AND p.deleted_at IS NULL AND s.active AND c.active) visible
            FROM products p
            JOIN subcategories s ON s.id = p.subcategory_id
            JOIN categories c ON c.id = s.category_id
            LEFT JOIN store_products sp ON sp.product_id = p.id AND sp.store_id = ?
            WHERE p.id = ANY (?)
            """;

    private final JdbcTemplate jdbc;

    /** Products by id; ids that don't exist are absent from the map. */
    public Map<Long, Sellable> find(long storeId, Collection<Long> productIds) {
        Map<Long, Sellable> found = new HashMap<>();
        if (productIds.isEmpty()) {
            return found;
        }
        jdbc.query(con -> {
            var ps = con.prepareStatement(QUERY);
            ps.setLong(1, storeId);
            Array ids = con.createArrayOf("bigint", productIds.toArray());
            ps.setArray(2, ids);
            return ps;
        }, (org.springframework.jdbc.core.RowCallbackHandler) rs -> found.put(rs.getLong("id"), new Sellable(
                rs.getLong("id"), rs.getString("name_ar"), rs.getString("name_en"), rs.getString("size_label"),
                rs.getString("image_hash"), rs.getBigDecimal("price"), rs.getBoolean("visible"), rs.getBoolean("available"))));
        return found;
    }
}
