package com.tayran.service.impl;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.tayran.dao.entity.CatalogPublication;
import com.tayran.dao.entity.Store;
import com.tayran.dao.repository.CatalogPublicationRepository;
import com.tayran.dao.repository.StoreRepository;
import com.tayran.integration.storage.ObjectStorage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.zip.GZIPOutputStream;

/**
 * Publishes each dirty store's catalog as an immutable JSON file:
 * {@code catalog/store-{id}/v{n}.json}. The version is bumped and the dirty flag cleared only
 * after the write succeeds. Versions older than 7 days are deleted.
 */
@Slf4j
@Service
public class CatalogPublisher {

    /** Fired after a publish commits; the bootstrap cache listens for it. */
    public record CatalogPublished(long storeId, int version) {
    }

    /**
     * What the admin portal shows: the live version, when it went out, whether edits are waiting
     * for the next run, and where files are stored (LOCAL in dev, R2 in production).
     */
    public record CatalogStatus(long store, int version, Instant publishedAt, boolean pendingChanges, String storage,
                                long publishIntervalSeconds, String catalogUrl) {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record CatalogJson(int v, long store, List<CategoryJson> categories, List<SubcategoryJson> subcategories,
                              List<ProductJson> products) {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record CategoryJson(long id, String nameAr, String nameEn, String img, String bg, String tile) {
    }

    public record SubcategoryJson(long id, long cat, String nameAr, String nameEn) {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record ProductJson(long id, long sub, String nameAr, String nameEn, String size, Number price, Number oldPrice,
                              String img, String bg, boolean available, String description, String ingredients) {
    }

    static final Duration KEEP_VERSIONS_FOR = Duration.ofDays(7);

    /**
     * One query loads the whole store catalog: active categories, their active subcategories, and
     * their active, not-deleted products that have a price in this store, in admin order.
     */
    private static final String CATALOG_SELECT = """
            SELECT c.id c_id, c.name_ar c_ar, c.name_en c_en, c.tile_color, c.image_hash c_img, c.image_bg c_bg,
                   s.id s_id, s.name_ar s_ar, s.name_en s_en,
                   p.id p_id, p.name_ar p_ar, p.name_en p_en, p.size_label, p.description, p.ingredients,
                   p.image_hash p_img, p.image_bg p_bg, sp.price, sp.old_price, sp.available
            FROM categories c
            LEFT JOIN subcategories s ON s.category_id = c.id AND s.active
            LEFT JOIN (products p JOIN store_products sp ON sp.product_id = p.id AND sp.store_id = ?)
                   ON p.subcategory_id = s.id AND p.active AND p.deleted_at IS NULL
            """;
    private static final String CATALOG_ORDER = " ORDER BY c.sort_order, c.id, s.sort_order, s.id, p.sort_order, p.id";
    private static final String CATALOG_QUERY = CATALOG_SELECT + " WHERE c.active" + CATALOG_ORDER;
    /** The same rows for one category (the live catalog loads a category at a time). */
    private static final String CATEGORY_QUERY = CATALOG_SELECT + " WHERE c.active AND c.id = ?" + CATALOG_ORDER;

    private final StoreRepository storeRepository;
    private final CatalogPublicationRepository publicationRepository;
    private final ObjectStorage storage;
    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final TransactionTemplate tx;
    private final ApplicationEventPublisher events;
    private final Clock clock;
    private final boolean publishOnStartup;
    private final Duration publishInterval;
    private final com.tayran.config.properties.StorageProperties storageProperties;

    public CatalogPublisher(StoreRepository storeRepository, CatalogPublicationRepository publicationRepository, ObjectStorage storage,
                            JdbcTemplate jdbc, ObjectMapper objectMapper,
                            org.springframework.transaction.PlatformTransactionManager transactionManager,
                            ApplicationEventPublisher events, Clock clock,
                            @Value("${app.catalog-publish-on-startup:false}") boolean publishOnStartup,
                            @Value("${app.catalog-publish-interval:90s}") Duration publishInterval,
                            com.tayran.config.properties.StorageProperties storageProperties) {
        this.storeRepository = storeRepository;
        this.publicationRepository = publicationRepository;
        this.storage = storage;
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
        this.tx = new TransactionTemplate(transactionManager);
        this.events = events;
        this.clock = clock;
        this.publishOnStartup = publishOnStartup;
        this.publishInterval = publishInterval;
        this.storageProperties = storageProperties;
    }

    /** The store's catalog status for the admin portal. */
    public CatalogStatus status(long storeId) {
        Store store = storeRepository.findById(storeId).orElseThrow();
        Instant publishedAt = publicationRepository.findFirstByIdStoreIdOrderByPublishedAtDesc(storeId)
                .map(CatalogPublication::getPublishedAt).orElse(null);
        String url = store.getCatalogVersion() > 0 ? storageProperties.url(key(storeId, store.getCatalogVersion())) : null;
        return new CatalogStatus(storeId, store.getCatalogVersion(), publishedAt, store.isCatalogDirty(), storageName(),
                publishInterval.toSeconds(), url);
    }

    /** "LOCAL" (dev files served at /cdn) or "R2". */
    String storageName() {
        return storage instanceof com.tayran.integration.storage.LocalFileStorage ? "LOCAL" : "R2";
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onStartup() {
        if (publishOnStartup) {
            publishDirty();
        }
    }

    @Scheduled(fixedDelayString = "${app.catalog-publish-interval:90s}", initialDelayString = "${app.catalog-publish-interval:90s}")
    public void scheduled() {
        publishDirty();
    }

    /** Publishes every dirty store. Returns how many were published. */
    public int publishDirty() {
        int published = 0;
        for (Store store : storeRepository.findByCatalogDirtyTrue()) {
            try {
                if (publish(store.getId())) {
                    published++;
                }
            } catch (RuntimeException e) {
                // The store stays dirty and is retried on the next run.
                log.error("Publishing the catalog of store {} failed", store.getId(), e);
            }
        }
        return published;
    }

    /** Publishes one store if it is still dirty. */
    public boolean publish(long storeId) {
        CatalogPublished done = tx.execute(status -> {
            Store store = storeRepository.findByIdForUpdate(storeId).orElseThrow();
            if (!store.isCatalogDirty()) {
                return null;
            }
            int version = store.getCatalogVersion() + 1;
            byte[] json = render(load(storeId, version));
            String key = key(storeId, version);
            storage.put(key, json, "application/json", ObjectStorage.IMMUTABLE); // throws -> rollback, stays dirty

            Instant now = clock.instant();
            publicationRepository.save(new CatalogPublication(new CatalogPublication.Key(storeId, version), key, now, null));
            store.setCatalogVersion(version);
            store.setCatalogDirty(false);
            storeRepository.save(store);
            log.info("Published catalog store-{} v{}: {} bytes raw, {} bytes gzipped", storeId, version, json.length, gzippedSize(json));
            deleteOldVersions(storeId, now);
            return new CatalogPublished(storeId, version);
        });
        if (done == null) {
            return false;
        }
        events.publishEvent(done);
        return true;
    }

    public static String key(long storeId, int version) {
        return "catalog/store-" + storeId + "/v" + version + ".json";
    }

    CatalogJson load(long storeId, int version) {
        return query(storeId, version, CATALOG_QUERY, storeId);
    }

    /** One active category of a store with its subcategories and products; no categories when it isn't active. */
    CatalogJson loadCategory(long storeId, long categoryId) {
        return query(storeId, 0, CATEGORY_QUERY, storeId, categoryId);
    }

    private CatalogJson query(long storeId, int version, String sql, Object... args) {
        Map<Long, CategoryJson> categories = new LinkedHashMap<>();
        Map<Long, SubcategoryJson> subcategories = new LinkedHashMap<>();
        List<ProductJson> products = new ArrayList<>();
        jdbc.query(sql, (org.springframework.jdbc.core.RowCallbackHandler) rs -> {
            long categoryId = rs.getLong("c_id");
            categories.computeIfAbsent(categoryId, id -> category(rs, id));
            long subId = rs.getLong("s_id");
            if (!rs.wasNull()) {
                subcategories.computeIfAbsent(subId, id -> subcategory(rs, id, categoryId));
                long productId = rs.getLong("p_id");
                if (!rs.wasNull()) {
                    products.add(new ProductJson(productId, subId, rs.getString("p_ar"), rs.getString("p_en"),
                            rs.getString("size_label"), number(rs.getBigDecimal("price")), number(rs.getBigDecimal("old_price")),
                            rs.getString("p_img"), rs.getString("p_bg"), rs.getBoolean("available"),
                            rs.getString("description"), rs.getString("ingredients")));
                }
            }
        }, args);
        return new CatalogJson(version, storeId, List.copyOf(categories.values()), List.copyOf(subcategories.values()), products);
    }

    private byte[] render(CatalogJson catalog) {
        return objectMapper.writeValueAsBytes(catalog);
    }

    private void deleteOldVersions(long storeId, Instant now) {
        for (CatalogPublication old : publicationRepository.findByIdStoreIdAndDeletedAtIsNullAndPublishedAtBefore(storeId, now.minus(KEEP_VERSIONS_FOR))) {
            storage.delete(old.getObjectKey());
            old.setDeletedAt(now);
            publicationRepository.save(old);
        }
    }

    private static CategoryJson category(ResultSet rs, long id) {
        try {
            return new CategoryJson(id, rs.getString("c_ar"), rs.getString("c_en"), rs.getString("c_img"), rs.getString("c_bg"),
                    rs.getString("tile_color"));
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    private static SubcategoryJson subcategory(ResultSet rs, long id, long categoryId) {
        try {
            return new SubcategoryJson(id, categoryId, rs.getString("s_ar"), rs.getString("s_en"));
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    /** 15.00 → 15, 12.50 → 12.5: smaller JSON, never scientific notation. */
    static Number number(BigDecimal value) {
        if (value == null) {
            return null;
        }
        BigDecimal stripped = value.stripTrailingZeros();
        return stripped.scale() <= 0 ? (Number) stripped.longValueExact() : (Number) stripped.doubleValue();
    }

    private static long gzippedSize(byte[] bytes) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            try (GZIPOutputStream gzip = new GZIPOutputStream(out)) {
                gzip.write(bytes);
            }
            return out.size();
        } catch (IOException e) {
            return -1;
        }
    }
}
