package com.tayran.config;

import com.tayran.dao.entity.Category;
import com.tayran.dao.entity.Product;
import com.tayran.dao.entity.StoreProduct;
import com.tayran.dao.entity.Subcategory;
import com.tayran.dao.repository.CategoryRepository;
import com.tayran.dao.repository.ProductRepository;
import com.tayran.dao.repository.StoreProductRepository;
import com.tayran.dao.repository.StoreRepository;
import com.tayran.dao.repository.SubcategoryRepository;
import com.tayran.model.ImageKind;
import com.tayran.service.impl.CatalogChanges;
import com.tayran.service.impl.ImageIngestService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * TEST DATA (dev profile only): seeds subcategories, products and store prices from
 * seed/catalog.json, and gives the 8 main categories their images. Every image goes through the
 * real pipeline from seed-images/*.png. Runs once: skipped when any product exists.
 */
@Slf4j
@Order(10)
@Component
@Profile("dev")
@RequiredArgsConstructor
public class DevCatalogSeeder implements ApplicationRunner {

    private final CategoryRepository categoryRepository;
    private final SubcategoryRepository subcategoryRepository;
    private final ProductRepository productRepository;
    private final StoreProductRepository storeProductRepository;
    private final StoreRepository storeRepository;
    private final ImageIngestService imageIngestService;
    private final ObjectMapper objectMapper;

    @Value("${app.seed-dir:seed}")
    private String seedDir;

    @Value("${app.seed-images-dir:seed-images}")
    private String seedImagesDir;

    private final Map<String, String[]> ingested = new HashMap<>();

    @Override
    @Transactional
    public void run(ApplicationArguments args) throws IOException {
        if (productRepository.count() > 0) {
            return;
        }
        Path catalogFile = Path.of(seedDir, "catalog.json");
        if (!Files.isRegularFile(catalogFile)) {
            log.warn("Dev seed skipped: {} not found (run the backend from the backend/ folder)", catalogFile.toAbsolutePath());
            return;
        }
        JsonNode root = objectMapper.readTree(catalogFile.toFile());
        Map<String, Category> existing = categoryRepository.findAll().stream()
                .collect(Collectors.toMap(Category::getNameAr, Function.identity()));
        int sort = 0;
        int products = 0;
        for (JsonNode c : root.get("categories")) {
            sort++;
            Category category = existing.getOrDefault(text(c, "nameAr"), new Category());
            category.setNameAr(text(c, "nameAr"));
            category.setNameEn(text(c, "nameEn"));
            category.setTileColor(text(c, "tile"));
            category.setSortOrder(sort);
            category.setActive(true);
            String[] image = image(text(c, "image"), ImageKind.CATEGORY);
            category.setImageHash(image == null ? null : image[0]);
            category.setImageBg(image == null ? null : image[1]);
            categoryRepository.save(category);

            int subSort = 0;
            for (JsonNode s : c.get("subcategories")) {
                Subcategory sub = new Subcategory();
                sub.setCategoryId(category.getId());
                sub.setNameAr(text(s, "nameAr"));
                sub.setNameEn(text(s, "nameEn"));
                sub.setSortOrder(++subSort);
                subcategoryRepository.save(sub);

                int productSort = 0;
                for (JsonNode p : s.get("products")) {
                    Product product = new Product();
                    product.setSubcategoryId(sub.getId());
                    product.setNameAr(text(p, "ar"));
                    product.setNameEn(text(p, "en"));
                    product.setSizeLabel(text(p, "size"));
                    product.setDescription(text(p, "desc"));
                    product.setIngredients(text(p, "ingr"));
                    product.setSortOrder(++productSort);
                    String[] img = image(text(p, "img"), ImageKind.PRODUCT);
                    product.setImageHash(img == null ? null : img[0]);
                    product.setImageBg(img == null ? null : img[1]);
                    productRepository.save(product);

                    StoreProduct price = new StoreProduct(CatalogChanges.DEFAULT_STORE_ID, product.getId());
                    price.setPrice(new BigDecimal(p.get("price").asString()));
                    price.setOldPrice(p.hasNonNull("old") ? new BigDecimal(p.get("old").asString()) : null);
                    price.setAvailable(!p.has("available") || p.get("available").asBoolean());
                    storeProductRepository.save(price);
                    products++;
                }
            }
        }
        storeRepository.markAllDirty();
        log.info("Dev catalog seeded (TEST DATA): {} categories, {} products, {} distinct images", sort, products, ingested.size());
    }

    /** Runs seed-images/{name}.png through the real pipeline once; returns {hash, bg} or null. */
    private String[] image(String name, ImageKind kind) throws IOException {
        if (name == null) {
            return null;
        }
        String cacheKey = kind + ":" + name;
        String[] cached = ingested.get(cacheKey);
        if (cached != null) {
            return cached;
        }
        Path file = Path.of(seedImagesDir, name + ".png");
        if (!Files.isRegularFile(file)) {
            log.warn("Seed image missing: {}", file);
            return null;
        }
        ImageIngestService.Result result = imageIngestService.ingest(kind, Files.readAllBytes(file));
        String[] value = {result.hash(), result.bg()};
        ingested.put(cacheKey, value);
        return value;
    }

    private static String text(JsonNode node, String field) {
        JsonNode value = node.get(field);
        return value == null || value.isNull() ? null : value.asString();
    }
}
