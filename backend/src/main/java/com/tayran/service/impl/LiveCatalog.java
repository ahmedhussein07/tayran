package com.tayran.service.impl;

import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.LoadingCache;
import com.tayran.config.properties.AppProperties;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import com.tayran.service.impl.CatalogPublisher.CatalogJson;
import com.tayran.service.impl.CatalogPublisher.ProductJson;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.sql.Array;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * The catalog as it is in the database right now, kept in memory a category at a time for the
 * customer's category screen and cart.
 *
 * <ul>
 *   <li>Key: the category (with its store, since prices are per store). The first customer to
 *       open a category loads it with one small query; everyone after reads memory. Concurrent
 *       requests for a category that isn't loaded wait for that one load, not N queries.</li>
 *   <li>Any admin catalog edit clears it right after its transaction commits, so the next request
 *       reloads and never sees an old price. Everything is cleared, not just the edited category:
 *       an edit can move a product between categories or touch several at once, and a reload is
 *       one query per category actually opened.</li>
 * </ul>
 *
 * <p>The published CDN file (see {@link CatalogPublisher}) still backs home, offline use and the
 * phone's saved copy; this is the live view on top of it.
 *
 * <p>One backend instance: the eviction is in-process. With several instances, the
 * {@link CatalogEdited} signal must reach all of them (e.g. Postgres LISTEN/NOTIFY).
 */
@Slf4j
@Service
public class LiveCatalog {

    /** Fired by {@link CatalogChanges#markDirty()} inside the admin's transaction. */
    public record CatalogEdited() {
    }

    record CategoryKey(long storeId, long categoryId) {
    }

    /** At most this many ids per cart check. */
    public static final int MAX_IDS = 100;

    /** Which category a product is in, for the cart check (products of hidden categories included). */
    private static final String PRODUCT_CATEGORY = """
            SELECT p.id, s.category_id FROM products p JOIN subcategories s ON s.id = p.subcategory_id
            WHERE p.id = ANY (?)
            """;

    private final CatalogPublisher publisher;
    private final JdbcTemplate jdbc;
    /** The category page, or empty when the category isn't visible (cached too, so bad ids don't hit the database). */
    private final LoadingCache<CategoryKey, Optional<CatalogJson>> categories;
    /** product id → category id; ids that don't exist are not cached. */
    private final LoadingCache<Long, Long> productCategory;

    public LiveCatalog(CatalogPublisher publisher, JdbcTemplate jdbc, AppProperties appProperties) {
        this.publisher = publisher;
        this.jdbc = jdbc;
        // Cleared on every edit; the TTL is only a safety net for edits made outside the portal.
        this.categories = Caffeine.newBuilder()
                .maximumSize(2_000)
                .expireAfterWrite(appProperties.categoriesCacheTtl())
                .build(this::loadCategory);
        this.productCategory = Caffeine.newBuilder()
                .maximumSize(100_000)
                .expireAfterWrite(appProperties.categoriesCacheTtl())
                .build(new com.github.benmanes.caffeine.cache.CacheLoader<>() {
                    @Override
                    public Long load(Long id) {
                        return loadProductCategories(Set.of(id)).get(id);
                    }

                    @Override
                    public Map<Long, Long> loadAll(Set<? extends Long> ids) {
                        return loadProductCategories(ids);
                    }
                });
    }

    /**
     * One category with its subcategories and products, in the same shape as the published file
     * (so the app reads both the same way).
     *
     * @throws BusinessException NOT_FOUND when the category isn't visible in this store
     */
    public CatalogJson category(long storeId, long categoryId) {
        return categories.get(new CategoryKey(storeId, categoryId))
                .orElseThrow(() -> new BusinessException(TayranConst.NOT_FOUND));
    }

    /**
     * The products the customer can see now, for the given ids, read from their categories'
     * entries. Ids that are missing were deleted, deactivated, lost their price or are in a hidden
     * category: the app treats them as unavailable.
     *
     * @throws BusinessException VALIDATION_ERROR for more than {@link #MAX_IDS} ids
     */
    public List<ProductJson> products(long storeId, Collection<Long> ids) {
        if (ids.size() > MAX_IDS) {
            throw new BusinessException(TayranConst.VALIDATION_ERROR);
        }
        Set<Long> wanted = new LinkedHashSet<>(ids);
        Map<Long, Long> categoryOf = productCategory.getAll(wanted);
        Map<Long, ProductJson> visible = new HashMap<>();
        for (Long categoryId : new LinkedHashSet<>(categoryOf.values())) {
            categories.get(new CategoryKey(storeId, categoryId))
                    .ifPresent(page -> page.products().forEach(p -> visible.put(p.id(), p)));
        }
        List<ProductJson> out = new ArrayList<>();
        for (Long id : wanted) {
            ProductJson p = visible.get(id);
            if (p != null) {
                out.add(p);
            }
        }
        return out;
    }

    /**
     * After the edit commits (or right away when there's no transaction). An in-flight load is
     * waited for and dropped, so a load that read the old rows can't stay cached.
     */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onEdited(CatalogEdited event) {
        categories.invalidateAll();
        productCategory.invalidateAll();
    }

    private Optional<CatalogJson> loadCategory(CategoryKey key) {
        CatalogJson page = publisher.loadCategory(key.storeId(), key.categoryId());
        log.debug("Live catalog store-{} category {} loaded: {} products", key.storeId(), key.categoryId(), page.products().size());
        return page.categories().isEmpty() ? Optional.empty() : Optional.of(page);
    }

    private Map<Long, Long> loadProductCategories(Set<? extends Long> ids) {
        Map<Long, Long> found = new HashMap<>();
        jdbc.query(con -> {
            var ps = con.prepareStatement(PRODUCT_CATEGORY);
            Array array = con.createArrayOf("bigint", ids.toArray());
            ps.setArray(1, array);
            return ps;
        }, (org.springframework.jdbc.core.RowCallbackHandler) rs -> found.put(rs.getLong(1), rs.getLong(2)));
        return found;
    }
}
