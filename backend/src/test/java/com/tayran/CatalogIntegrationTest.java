package com.tayran;

import com.tayran.service.impl.CatalogPublisher;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import tools.jackson.databind.JsonNode;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Admin → publish → customer: an admin uploads images and builds a category with products, the
 * publisher writes a new catalog version, and the customer's bootstrap and catalog file reflect it.
 */
class CatalogIntegrationTest extends IntegrationTestBase {

    @Autowired
    CatalogPublisher publisher;

    @Test
    void adminCreatesCategoryAndProductsWithImagesThenBootstrapAndCatalogReflectIt() throws Exception {
        String admin = adminToken();
        String customer = customerToken("01098765432");
        publisher.publishDirty();
        int versionBefore = catalogVersion(customer);

        // 1. Two-step upload: the image first, then its hash on the category / product.
        Res categoryImage = upload("/admin/images?kind=CATEGORY", png(new Color(0xE8, 0x9A, 0x2C)), "bread.png", "image/png", admin);
        assertThat(categoryImage.status()).isEqualTo(200);
        String categoryHash = categoryImage.content().get("hash").asString();
        assertThat(categoryHash).matches("[0-9a-f]{12}");
        assertThat(categoryImage.content().get("bg").asString()).matches("#[0-9A-F]{6}");
        assertThat(categoryImage.content().get("previewUrl").asString()).isEqualTo(CDN + "/c/" + categoryHash + "_256.webp");
        assertThat(Files.exists(CDN_DIR.resolve("c/" + categoryHash + "_128.webp"))).isTrue();
        assertThat(Files.exists(CDN_DIR.resolve("c/" + categoryHash + "_256.webp"))).isTrue();

        Res productImage = upload("/admin/images?kind=PRODUCT", png(new Color(0x3A, 0x7D, 0x44)), "loaf.png", "image/png", admin);
        String productHash = productImage.content().get("hash").asString();
        for (int w : List.of(160, 320, 640)) {
            assertThat(Files.exists(CDN_DIR.resolve("p/" + productHash + "_" + w + ".webp"))).isTrue();
        }

        // The CDN serves the variant with an immutable cache header.
        HttpResponse<byte[]> variant = http.send(HttpRequest.newBuilder(
                URI.create("http://localhost:" + port + "/api/v1/cdn/p/" + productHash + "_320.webp")).GET().build(),
                HttpResponse.BodyHandlers.ofByteArray());
        assertThat(variant.statusCode()).isEqualTo(200);
        assertThat(variant.headers().firstValue("Content-Type").orElseThrow()).startsWith("image/webp");
        assertThat(variant.headers().firstValue("Cache-Control").orElseThrow()).contains("immutable");

        // A product image can't be used for a category.
        Res wrongKind = post("/admin/categories", category("خطأ", "Wrong", productHash), admin);
        assertThat(wrongKind.code()).isEqualTo("UNKNOWN_IMAGE");
        assertThat(post("/admin/images?kind=CATEGORY", Map.of(), admin).code()).isEqualTo("VALIDATION_ERROR");
        Res notAnImage = upload("/admin/images?kind=PRODUCT", "hello".getBytes(), "x.png", "image/png", admin);
        assertThat(notAnImage.code()).isEqualTo("IMAGE_TYPE_UNSUPPORTED");

        // 2. Category → subcategory → products.
        Res created = post("/admin/categories", category("مخبوزات طازة", "Fresh bakery", categoryHash), admin);
        assertThat(created.status()).isEqualTo(200);
        long categoryId = created.content().get("id").asLong();
        long subId = post("/admin/categories/" + categoryId + "/subcategories",
                Map.of("nameAr", "عيش", "nameEn", "Bread"), admin).content().get("id").asLong();

        long liveId = post("/admin/products", product(subId, "عيش فينو", "Fino bread", productHash, true, "25", "30"), admin)
                .content().get("id").asLong();
        long deletedId = post("/admin/products", product(subId, "عيش بلدي", "Baladi bread", null, true, "5", null), admin)
                .content().get("id").asLong();
        long inactiveId = post("/admin/products", product(subId, "كرواسون", "Croissant", null, false, "15", null), admin)
                .content().get("id").asLong();

        Res badOldPrice = post("/admin/products", product(subId, "تجربة", "Test", null, true, "10", "10"), admin);
        assertThat(badOldPrice.code()).isEqualTo("VALIDATION_ERROR");

        // 3. Soft delete hides the product from the admin list and the catalog.
        assertThat(delete("/admin/products/" + deletedId, admin).status()).isEqualTo(200);
        assertThat(get("/admin/products/" + deletedId, admin, null).status()).isEqualTo(404);

        // Delete rules: a category with subcategories, or a subcategory with products (even soft-deleted), can't go.
        assertThat(delete("/admin/categories/" + categoryId, admin).code()).isEqualTo("CATEGORY_NOT_EMPTY");
        assertThat(delete("/admin/categories/" + categoryId + "/subcategories/" + subId, admin).code())
                .isEqualTo("SUBCATEGORY_NOT_EMPTY");

        // Until the publisher runs, the customer still sees the previous version.
        assertThat(catalogVersion(customer)).isEqualTo(versionBefore);

        // 4. Publish → new version, bootstrap and catalog reflect it.
        assertThat(publisher.publishDirty()).isEqualTo(1);
        JsonNode home = get("/app/bootstrap", customer, null).content();
        int version = home.get("catalog").get("version").asInt();
        assertThat(version).isEqualTo(versionBefore + 1);
        String url = home.get("catalog").get("url").asString();
        assertThat(url).isEqualTo(CDN + "/catalog/store-1/v" + version + ".json");
        assertThat(home.get("catalog").get("store").asLong()).isEqualTo(1);

        JsonNode tile = byId(home.get("categories"), categoryId);
        assertThat(tile).isNotNull();
        assertThat(tile.get("img").asString()).isEqualTo(categoryHash);
        assertThat(tile.get("bg").asString()).isEqualTo(categoryImage.content().get("bg").asString());
        assertThat(tile.get("tile").asString()).isEqualTo("pastel-wheat");
        assertThat(tile.get("nameEn").asString()).isEqualTo("Fresh bakery");
        JsonNode categories = home.get("categories");
        assertThat(categories.get(categories.size() - 1).get("id").asLong()).isEqualTo(categoryId);

        JsonNode catalog = readCdnJson(url);
        assertThat(catalog.get("v").asInt()).isEqualTo(version);
        assertThat(byId(catalog.get("categories"), categoryId)).isNotNull();
        assertThat(byId(catalog.get("subcategories"), subId).get("cat").asLong()).isEqualTo(categoryId);
        JsonNode live = byId(catalog.get("products"), liveId);
        assertThat(live.get("sub").asLong()).isEqualTo(subId);
        assertThat(live.get("price").asInt()).isEqualTo(25);
        assertThat(live.get("oldPrice").asInt()).isEqualTo(30);
        assertThat(live.get("img").asString()).isEqualTo(productHash);
        assertThat(live.get("available").asBoolean()).isTrue();
        assertThat(byId(catalog.get("products"), deletedId)).as("soft-deleted product").isNull();
        assertThat(byId(catalog.get("products"), inactiveId)).as("inactive product").isNull();

        // Nothing changed → nothing published, version unchanged.
        assertThat(publisher.publishDirty()).isZero();
        assertThat(catalogVersion(customer)).isEqualTo(version);

        // 5. Deactivating the category takes it and its products out of bootstrap and the catalog.
        assertThat(put("/admin/categories/" + categoryId + "/active", Map.of("active", false), admin).status()).isEqualTo(200);
        publisher.publishDirty();
        JsonNode after = get("/app/bootstrap", customer, null).content();
        assertThat(byId(after.get("categories"), categoryId)).isNull();
        JsonNode catalogAfter = readCdnJson(after.get("catalog").get("url").asString());
        assertThat(byId(catalogAfter.get("categories"), categoryId)).isNull();
        assertThat(byId(catalogAfter.get("products"), liveId)).isNull();
    }

    @Test
    void bootstrapListsOnlyActiveCategoriesInAdminOrder() throws Exception {
        String admin = adminToken();
        String customer = customerToken("01098765433");

        List<Long> original = new ArrayList<>();
        Map<Long, Boolean> active = new HashMap<>();
        get("/admin/categories", admin, null).content().forEach(c -> {
            original.add(c.get("id").asLong());
            active.put(c.get("id").asLong(), c.get("active").asBoolean());
        });
        List<Long> activeIds = original.stream().filter(active::get).toList();
        long first = activeIds.get(0);
        long second = activeIds.get(1);
        long third = activeIds.get(2);

        List<Long> reordered = new ArrayList<>(original);
        reordered.remove(second);
        reordered.addFirst(second);
        try {
            assertThat(put("/admin/categories/order", Map.of("ids", reordered), admin).status()).isEqualTo(200);
            assertThat(put("/admin/categories/" + third + "/active", Map.of("active", false), admin).status()).isEqualTo(200);
            publisher.publishDirty();

            List<Long> shown = ids(get("/app/bootstrap", customer, null).content().get("categories"));
            assertThat(shown).startsWith(second, first).doesNotContain(third);
            assertThat(shown).containsExactlyElementsOf(reordered.stream()
                    .filter(id -> id != third && active.get(id)).toList());
        } finally {
            put("/admin/categories/order", Map.of("ids", original), admin);
            put("/admin/categories/" + third + "/active", Map.of("active", true), admin);
            publisher.publishDirty();
        }
        assertThat(ids(get("/app/bootstrap", customer, null).content().get("categories"))).startsWith(first, second, third);
    }

    // ---- helpers ---------------------------------------------------------------------------

    private int catalogVersion(String customer) throws Exception {
        JsonNode ref = get("/app/bootstrap", customer, null).content().get("catalog");
        return ref == null || ref.isNull() ? 0 : ref.get("version").asInt();
    }

    private static Map<String, Object> category(String ar, String en, String imageHash) {
        Map<String, Object> body = new HashMap<>(Map.of("nameAr", ar, "nameEn", en, "tileColor", "pastel-wheat"));
        body.put("imageHash", imageHash);
        return body;
    }

    private static Map<String, Object> product(long subId, String ar, String en, String imageHash, boolean active,
                                               String price, String oldPrice) {
        Map<String, Object> body = new HashMap<>();
        body.put("subcategoryId", subId);
        body.put("nameAr", ar);
        body.put("nameEn", en);
        body.put("sizeLabel", "5 قطع");
        body.put("imageHash", imageHash);
        body.put("active", active);
        body.put("price", new java.math.BigDecimal(price));
        body.put("oldPrice", oldPrice == null ? null : new java.math.BigDecimal(oldPrice));
        body.put("available", true);
        return body;
    }

    private static JsonNode byId(JsonNode array, long id) {
        for (JsonNode node : array) {
            if (node.get("id").asLong() == id) {
                return node;
            }
        }
        return null;
    }

    private static List<Long> ids(JsonNode array) {
        List<Long> ids = new ArrayList<>();
        array.forEach(n -> ids.add(n.get("id").asLong()));
        return ids;
    }

    /** A product shot on a white background: a filled circle, off-centre, so trimming has work to do. */
    static byte[] png(Color colour) throws Exception {
        BufferedImage image = new BufferedImage(600, 400, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, 600, 400);
        g.setColor(colour);
        g.fillOval(80, 60, 260, 260);
        g.dispose();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "png", out);
        return out.toByteArray();
    }
}
