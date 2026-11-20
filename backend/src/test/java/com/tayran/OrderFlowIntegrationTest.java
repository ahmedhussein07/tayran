package com.tayran;

import com.tayran.dao.repository.UserDeviceRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import tools.jackson.databind.JsonNode;

import java.math.BigDecimal;
import java.net.URI;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Orders end to end over real HTTP and PostgreSQL: a cash order, the admin editing and moving it
 * through every stage, pushes after each commit, the live feed, and the rules around it.
 * Store settings come from the migration: delivery 15, free from 200, minimum 50, online fee 5.
 */
class OrderFlowIntegrationTest extends IntegrationTestBase {

    @Autowired
    UserDeviceRepository deviceRepository;

    /** Catalog made once for the class through the admin API. */
    private static long milk;      // 30.00, REPLACE allowed
    private static long bread;     // 10.00
    private static long cheese;    // 120.00
    private static long cheese2;   // 150.00 (a pricier replacement)
    private static long soldOut;   // available = false
    private static boolean ready;

    private synchronized void catalog() throws Exception {
        if (ready) {
            return;
        }
        String admin = adminToken();
        long cat = post("/admin/categories", Map.of("nameAr", "طلبات تجربة", "nameEn", "Order test", "tileColor", "pastel-sky"), admin)
                .content().get("id").asLong();
        long sub = post("/admin/categories/" + cat + "/subcategories", Map.of("nameAr", "أساسي", "nameEn", "Basics"), admin)
                .content().get("id").asLong();
        milk = product(admin, sub, "لبن تجربة", "30", true);
        bread = product(admin, sub, "عيش تجربة", "10", true);
        cheese = product(admin, sub, "جبنة تجربة", "120", true);
        cheese2 = product(admin, sub, "جبنة فاخرة", "150", true);
        soldOut = product(admin, sub, "منتج خلصان", "20", false);
        ready = true;
    }

    private long product(String admin, long sub, String name, String price, boolean available) throws Exception {
        Map<String, Object> body = new HashMap<>();
        body.put("subcategoryId", sub);
        body.put("nameAr", name);
        body.put("nameEn", name + " en");
        body.put("sizeLabel", "1");
        body.put("active", true);
        body.put("price", new BigDecimal(price));
        body.put("available", available);
        return post("/admin/products", body, admin).content().get("id").asLong();
    }

    /** A signed-in customer with one saved address; returns {token, addressId}. */
    private Customer customer(String localPhone) throws Exception {
        String token = customerToken(localPhone);
        put("/me/name", Map.of("firstName", "تجربة", "lastName", "طلبات"), token);
        JsonNode village = get("/locations", null, null).content().get("villages").get(0);
        post("/me/address", Map.of("villageId", village.get("id").asLong(),
                "streetId", village.get("streets").get(0).get("id").asLong(), "landmark", "جنب الجامع الكبير"), token);
        long addressId = get("/me/addresses", token, null).content().get(0).get("id").asLong();
        return new Customer(token, addressId);
    }

    record Customer(String token, long addressId) {
    }

    private static Map<String, Object> line(long productId, int qty, String pref) {
        Map<String, Object> l = new HashMap<>();
        l.put("productId", productId);
        l.put("qty", qty);
        l.put("substitutionPref", pref);
        return l;
    }

    private static Map<String, Object> order(long addressId, String method, List<Map<String, Object>> items, String expectedTotal) {
        Map<String, Object> body = new HashMap<>();
        body.put("addressId", addressId);
        body.put("paymentMethod", method);
        body.put("items", items);
        body.put("notes", "رن الجرس مرتين");
        body.put("expectedTotal", new BigDecimal(expectedTotal));
        return body;
    }

    private Res place(String token, String key, Map<String, Object> body) throws Exception {
        HttpRequest.Builder b = HttpRequest.newBuilder(URI.create("http://localhost:" + port + "/api/v1/orders"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + token)
                .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(body)));
        if (key != null) {
            b.header("Idempotency-Key", key);
        }
        return send(b);
    }

    private void awaitPush(long orderId, String status) throws InterruptedException {
        for (int i = 0; i < 100; i++) {
            if (pushSender.forOrder(orderId).stream().anyMatch(s -> status.equals(s.message().data().get("status")))) {
                return;
            }
            Thread.sleep(50);
        }
        throw new AssertionError("No " + status + " push for order " + orderId);
    }

    // ---- placing ------------------------------------------------------------------------------

    @Test
    void theServerRecheckesEveryOrderBeforeCreatingIt() throws Exception {
        catalog();
        Customer c = customer("01020000001");
        Customer other = customer("01020000002");
        List<Map<String, Object>> items = List.of(line(milk, 2, "REPLACE"));  // 60 + 15 delivery = 75

        assertThat(place(c.token(), null, order(c.addressId(), "CASH", items, "75")).code()).isEqualTo("IDEMPOTENCY_KEY_REQUIRED");

        Res wrongTotal = place(c.token(), UUID.randomUUID().toString(), order(c.addressId(), "CASH", items, "70"));
        assertThat(wrongTotal.status()).isEqualTo(409);
        assertThat(wrongTotal.code()).isEqualTo("CART_CHANGED");
        assertThat(wrongTotal.content().get("total").decimalValue()).isEqualByComparingTo("75.00");
        assertThat(wrongTotal.content().get("lines").get(0).get("status").asString()).isEqualTo("OK");

        Map<String, Object> stalePrice = line(milk, 2, "REPLACE");
        stalePrice.put("unitPrice", new BigDecimal("25.00"));
        Res priceChanged = place(c.token(), UUID.randomUUID().toString(), order(c.addressId(), "CASH", List.of(stalePrice), "65"));
        assertThat(priceChanged.code()).isEqualTo("CART_CHANGED");
        JsonNode changedLine = priceChanged.content().get("lines").get(0);
        assertThat(changedLine.get("status").asString()).isEqualTo("PRICE_CHANGED");
        assertThat(changedLine.get("price").decimalValue()).isEqualByComparingTo("30.00");
        assertThat(changedLine.get("oldPrice").decimalValue()).isEqualByComparingTo("25.00");

        Res unavailable = place(c.token(), UUID.randomUUID().toString(),
                order(c.addressId(), "CASH", List.of(line(milk, 2, "REPLACE"), line(soldOut, 1, "REFUND")), "95"));
        assertThat(unavailable.code()).isEqualTo("CART_CHANGED");
        assertThat(unavailable.content().get("lines").get(1).get("status").asString()).isEqualTo("UNAVAILABLE");
        assertThat(unavailable.content().get("total").decimalValue()).isEqualByComparingTo("75.00");

        Res belowMinimum = place(c.token(), UUID.randomUUID().toString(), order(c.addressId(), "CASH", List.of(line(bread, 1, "REFUND")), "25"));
        assertThat(belowMinimum.code()).isEqualTo("MIN_ORDER_NOT_MET");
        assertThat(belowMinimum.content().get("minOrderAmount").decimalValue()).isEqualByComparingTo("50.00");

        assertThat(place(c.token(), UUID.randomUUID().toString(), order(c.addressId(), "ONLINE", items, "80")).code())
                .isEqualTo("PAYMENT_METHOD_NOT_AVAILABLE");

        // Someone else's address is refused like a missing one.
        assertThat(place(c.token(), UUID.randomUUID().toString(), order(other.addressId(), "CASH", items, "75")).code())
                .isEqualTo("INVALID_ADDRESS");

        // Nothing was created by any of those.
        assertThat(get("/orders", c.token(), null).content().get("orders").size()).isZero();
    }

    @Test
    void theSameIdempotencyKeyNeverCreatesASecondOrder() throws Exception {
        catalog();
        Customer c = customer("01020000003");
        String key = UUID.randomUUID().toString();
        Map<String, Object> body = order(c.addressId(), "CASH", List.of(line(milk, 2, "REPLACE")), "75");

        Res first = place(c.token(), key, body);
        assertThat(first.status()).isEqualTo(200);
        Res retry = place(c.token(), key, body);
        assertThat(retry.content().get("id").asLong()).isEqualTo(first.content().get("id").asLong());
        assertThat(retry.content().get("number").asLong()).isEqualTo(first.content().get("number").asLong());

        // Two at once with a new key: still one order.
        String raceKey = UUID.randomUUID().toString();
        CompletableFuture<Res> a = CompletableFuture.supplyAsync(() -> uncheck(() -> place(c.token(), raceKey, body)));
        CompletableFuture<Res> b = CompletableFuture.supplyAsync(() -> uncheck(() -> place(c.token(), raceKey, body)));
        assertThat(a.get().content().get("id").asLong()).isEqualTo(b.get().content().get("id").asLong());

        assertThat(get("/orders", c.token(), null).content().get("orders").size()).isEqualTo(2);
    }

    @Test
    void customersSeeAndCancelOnlyTheirOwnOrders() throws Exception {
        catalog();
        Customer owner = customer("01020000004");
        Customer stranger = customer("01020000005");
        long id = place(owner.token(), UUID.randomUUID().toString(),
                order(owner.addressId(), "CASH", List.of(line(milk, 2, "REPLACE")), "75")).content().get("id").asLong();

        assertThat(get("/orders/" + id, stranger.token(), null).status()).isEqualTo(404);
        assertThat(post("/orders/" + id + "/cancel", Map.of(), stranger.token()).status()).isEqualTo(404);

        Res cancelled = post("/orders/" + id + "/cancel", Map.of(), owner.token());
        assertThat(cancelled.content().get("status").asString()).isEqualTo("CANCELLED");
        assertThat(cancelled.content().get("cancelledBy").asString()).isEqualTo("CUSTOMER");
        // Final: cancelling again (or by the admin) is a state conflict.
        assertThat(post("/orders/" + id + "/cancel", Map.of(), owner.token()).code()).isEqualTo("ORDER_STATE_CHANGED");
        Thread.sleep(300);
        assertThat(pushSender.forOrder(id)).as("no push for the customer's own cancellation").isEmpty();
    }

    // ---- the whole flow -----------------------------------------------------------------------

    @Test
    void cashOrderIsEditedConfirmedDeliveredAndEndsUpInOldOrders() throws Exception {
        catalog();
        String admin = adminToken();
        Customer c = customer("01020000006");
        post("/me/devices", Map.of("fcmToken", "flow-phone-token", "platform", "ANDROID"), c.token());

        // The admin board listens live.
        BlockingQueue<String> feed = new LinkedBlockingQueue<>();
        HttpRequest streamRequest = HttpRequest.newBuilder(URI.create("http://localhost:" + port + "/api/v1/admin/orders/stream"))
                .header("Authorization", "Bearer " + admin).header("Accept", "text/event-stream").GET().build();
        CompletableFuture<HttpResponse<java.util.stream.Stream<String>>> stream = http.sendAsync(streamRequest, HttpResponse.BodyHandlers.ofLines());
        stream.thenAccept(r -> r.body().forEach(feed::add));
        Thread.sleep(300);

        // milk 30×2 + bread 10 + cheese 120 = 190, + 15 delivery = 205.
        Res placed = place(c.token(), UUID.randomUUID().toString(), order(c.addressId(), "CASH",
                List.of(line(milk, 2, "REPLACE"), line(bread, 1, "REFUND"), line(cheese, 1, "CALL_ME")), "205"));
        assertThat(placed.status()).isEqualTo(200);
        JsonNode o = placed.content();
        long id = o.get("id").asLong();
        assertThat(o.get("number").asLong()).isGreaterThanOrEqualTo(10001);
        assertThat(o.get("status").asString()).isEqualTo("PENDING_REVIEW");
        assertThat(o.get("stage").asInt()).isEqualTo(1);
        assertThat(o.get("total").decimalValue()).isEqualByComparingTo("205.00");
        assertThat(o.get("deliveryFee").decimalValue()).isEqualByComparingTo("15.00");
        assertThat(o.get("items").size()).isEqualTo(3);
        assertThat(o.get("timeline").get(0).get("status").asString()).isEqualTo("PENDING_REVIEW");
        assertThat(o.get("address").get("landmark").asString()).isEqualTo("جنب الجامع الكبير");
        assertThat(waitFor(feed, "\"orderId\":" + id)).contains("\"type\":\"NEW\"");

        // Active orders show on the bootstrap.
        JsonNode boot = get("/app/bootstrap", c.token(), null).content();
        assertThat(boot.get("activeOrders").get(0).get("id").asLong()).isEqualTo(id);
        assertThat(boot.get("settings").get("freeDeliveryThreshold").decimalValue()).isEqualByComparingTo("200.00");
        assertThat(boot.get("onlinePaymentEnabled").asBoolean()).isFalse();

        // The admin edits before confirming.
        JsonNode detail = get("/admin/orders/" + id, admin, null).content();
        long milkLine = lineId(detail, milk);
        long breadLine = lineId(detail, bread);
        long cheeseLine = lineId(detail, cheese);
        assertThat(put("/admin/orders/" + id + "/items", Map.of("version", 0, "edits",
                List.of(Map.of("lineId", breadLine, "action", "REPLACE", "productId", milk))), admin).code())
                .as("bread asked for a refund, not a replacement").isEqualTo("REPLACEMENT_NOT_ALLOWED");

        Res edited = put("/admin/orders/" + id + "/items", Map.of("version", 0, "edits", List.of(
                Map.of("lineId", milkLine, "action", "REDUCE", "qty", 1),
                Map.of("lineId", cheeseLine, "action", "REPLACE", "productId", cheese2))), admin);
        assertThat(edited.status()).isEqualTo(200);
        JsonNode e = edited.content();
        // 30 + 10 + replacement at the lower price 120 = 160, + the original 15 delivery = 175.
        assertThat(e.get("subtotal").decimalValue()).isEqualByComparingTo("160.00");
        assertThat(e.get("total").decimalValue()).isEqualByComparingTo("175.00");
        assertThat(e.get("itemsChanged").asBoolean()).isTrue();
        assertThat(e.get("version").asInt()).isEqualTo(1);
        JsonNode replacement = byProduct(e, cheese2);
        assertThat(replacement.get("unitPrice").decimalValue()).isEqualByComparingTo("120.00");
        assertThat(replacement.get("replacement").asBoolean()).isTrue();
        assertThat(byProduct(e, cheese).get("lineStatus").asString()).isEqualTo("REPLACED");
        assertThat(byProduct(e, milk).get("lineStatus").asString()).isEqualTo("REDUCED");

        // Another admin with the old version is told it changed.
        assertThat(post("/admin/orders/" + id + "/confirm", Map.of("version", 0), admin).code()).isEqualTo("ORDER_STATE_CHANGED");
        assertThat(post("/admin/orders/" + id + "/deliver", Map.of("version", 1, "cashCollected", true), admin).code())
                .as("can't skip stages").isEqualTo("ORDER_STATE_CHANGED");

        Res confirmed = post("/admin/orders/" + id + "/confirm", Map.of("version", 1), admin);
        assertThat(confirmed.content().get("status").asString()).isEqualTo("CONFIRMED");
        awaitPush(id, "CONFIRMED");
        var confirmPush = pushSender.forOrder(id).getLast();
        assertThat(confirmPush.tokens()).containsExactly("flow-phone-token");
        assertThat(confirmPush.message().data()).containsEntry("itemsChanged", "true").containsEntry("stage", "2");
        assertThat(confirmPush.message().body()).contains("عدّلنا");

        assertThat(post("/admin/orders/" + id + "/out-for-delivery",
                Map.of("version", 2, "courierName", "حسن", "courierPhone", "123"), admin).code()).isEqualTo("INVALID_COURIER_PHONE");
        Res out = post("/admin/orders/" + id + "/out-for-delivery",
                Map.of("version", 2, "courierName", "حسن", "courierPhone", "01099998888"), admin);
        assertThat(out.content().get("status").asString()).isEqualTo("OUT_FOR_DELIVERY");
        awaitPush(id, "OUT_FOR_DELIVERY");
        assertThat(pushSender.forOrder(id).getLast().message().body()).contains("حسن");

        JsonNode tracking = get("/orders/" + id, c.token(), null).content();
        assertThat(tracking.get("stage").asInt()).isEqualTo(3);
        assertThat(tracking.get("courier").get("name").asString()).isEqualTo("حسن");
        assertThat(tracking.get("courier").get("phone").asString()).isEqualTo("+201099998888");
        assertThat(tracking.get("timeline").size()).isEqualTo(3);

        Res delivered = post("/admin/orders/" + id + "/deliver", Map.of("version", 3, "cashCollected", true), admin);
        assertThat(delivered.content().get("status").asString()).isEqualTo("DELIVERED");
        assertThat(delivered.content().get("cashCollected").asBoolean()).isTrue();
        awaitPush(id, "DELIVERED");
        assertThat(waitFor(feed, "\"status\":\"DELIVERED\"")).contains("\"orderId\":" + id);

        // Final, and listed with the customer's orders; no longer active.
        JsonNode list = get("/orders", c.token(), null).content().get("orders");
        assertThat(list.get(0).get("id").asLong()).isEqualTo(id);
        assertThat(list.get(0).get("status").asString()).isEqualTo("DELIVERED");
        assertThat(list.get(0).get("total").decimalValue()).isEqualByComparingTo("175.00");
        assertThat(get("/app/bootstrap", c.token(), null).content().get("activeOrders").size()).isZero();
        assertThat(post("/admin/orders/" + id + "/cancel", Map.of("version", 4, "reason", "متأخر جدًا"), admin).code())
                .isEqualTo("ORDER_STATE_CHANGED");

        // The admin sees the whole history with names.
        JsonNode history = get("/admin/orders/" + id, admin, null).content().get("events");
        assertThat(history.size()).isEqualTo(5); // placed, items edited, confirmed, out, delivered
        assertThat(history.get(1).get("kind").asString()).isEqualTo("ITEMS_EDITED");
        assertThat(history.get(2).get("actorName").asString()).isEqualTo("Admin");

        // Search by order number and by phone.
        long number = o.get("number").asLong();
        assertThat(get("/admin/orders?search=" + number, admin, null).content().get("orders").get(0).get("id").asLong()).isEqualTo(id);
        assertThat(get("/admin/orders?search=01020000006", admin, null).content().get("orders").get(0).get("id").asLong()).isEqualTo(id);

        stream.cancel(true);
    }

    @Test
    void twoAdminsConfirmingAtOnceOnlyOneWins() throws Exception {
        catalog();
        String admin = adminToken();
        Customer c = customer("01020000007");
        long id = place(c.token(), UUID.randomUUID().toString(),
                order(c.addressId(), "CASH", List.of(line(milk, 2, "REPLACE")), "75")).content().get("id").asLong();

        List<CompletableFuture<Res>> attempts = new ArrayList<>();
        for (int i = 0; i < 4; i++) {
            attempts.add(CompletableFuture.supplyAsync(() -> uncheck(() -> post("/admin/orders/" + id + "/confirm", Map.of("version", 0), admin))));
        }
        List<Integer> statuses = new ArrayList<>();
        for (CompletableFuture<Res> a : attempts) {
            statuses.add(a.get(10, TimeUnit.SECONDS).status());
        }
        assertThat(statuses).containsOnlyOnce(200);
        assertThat(statuses.stream().filter(s -> s == 409)).hasSize(3);
        assertThat(get("/admin/orders/" + id, admin, null).content().get("events").size()).isEqualTo(2);
    }

    @Test
    void aFailedPushNeverUndoesTheChangeAndRejectedTokensAreRemoved() throws Exception {
        catalog();
        String admin = adminToken();
        Customer c = customer("01020000008");
        post("/me/devices", Map.of("fcmToken", "good-token", "platform", "ANDROID"), c.token());
        post("/me/devices", Map.of("fcmToken", "stale-token", "platform", "ANDROID"), c.token());
        long first = place(c.token(), UUID.randomUUID().toString(),
                order(c.addressId(), "CASH", List.of(line(milk, 2, "REPLACE")), "75")).content().get("id").asLong();
        long second = place(c.token(), UUID.randomUUID().toString(),
                order(c.addressId(), "CASH", List.of(line(milk, 3, "REPLACE")), "105")).content().get("id").asLong();

        pushSender.fail = true;
        try {
            assertThat(post("/admin/orders/" + first + "/confirm", Map.of("version", 0), admin).status()).isEqualTo(200);
            Thread.sleep(300);
        } finally {
            pushSender.fail = false;
        }
        assertThat(get("/orders/" + first, c.token(), null).content().get("status").asString()).isEqualTo("CONFIRMED");

        pushSender.invalidTokens.add("stale-token");
        post("/admin/orders/" + second + "/cancel", Map.of("version", 0, "reason", "مفيش طيارين دلوقتي"), admin);
        awaitPush(second, "CANCELLED");
        assertThat(pushSender.forOrder(second).getLast().message().body()).isEqualTo("مفيش طيارين دلوقتي");
        for (int i = 0; i < 40 && deviceRepository.findByFcmToken("stale-token").isPresent(); i++) {
            Thread.sleep(50);
        }
        assertThat(deviceRepository.findByFcmToken("stale-token")).isEmpty();
        assertThat(deviceRepository.findByFcmToken("good-token")).isPresent();
    }

    @Test
    void addressesSoftDeleteAndKeepOneDefault() throws Exception {
        Customer c = customer("01020000009");
        JsonNode village = get("/locations", null, null).content().get("villages").get(1);
        Map<String, Object> work = new HashMap<>(Map.of("villageId", village.get("id").asLong(),
                "streetId", village.get("streets").get(0).get("id").asLong(), "landmark", "عند المحطة", "label", "الشغل"));
        JsonNode added = post("/me/addresses", work, c.token()).content();
        assertThat(added.get("isDefault").asBoolean()).isFalse();

        JsonNode afterDefault = put("/me/addresses/" + added.get("id").asLong() + "/default", Map.of(), c.token()).content();
        assertThat(afterDefault.get(0).get("id").asLong()).isEqualTo(added.get("id").asLong());
        assertThat(afterDefault.get(0).get("isDefault").asBoolean()).isTrue();
        assertThat(afterDefault.get(1).get("isDefault").asBoolean()).isFalse();

        // Deleting the default promotes the other; the last one can't go.
        JsonNode remaining = delete("/me/addresses/" + added.get("id").asLong(), c.token()).content();
        assertThat(remaining.size()).isEqualTo(1);
        assertThat(remaining.get(0).get("isDefault").asBoolean()).isTrue();
        assertThat(delete("/me/addresses/" + remaining.get(0).get("id").asLong(), c.token()).code()).isEqualTo("LAST_ADDRESS");

        assertThat(put("/me/preferences", Map.of("language", "en"), c.token()).status()).isEqualTo(200);
        assertThat(put("/me/preferences", Map.of("language", "fr"), c.token()).code()).isEqualTo("VALIDATION_ERROR");
    }

    // ---- helpers ------------------------------------------------------------------------------

    private static long lineId(JsonNode order, long productId) {
        return byProduct(order, productId).get("id").asLong();
    }

    private static JsonNode byProduct(JsonNode order, long productId) {
        JsonNode match = null;
        for (JsonNode item : order.get("items")) {
            if (item.get("productId").asLong() == productId) {
                match = item;
            }
        }
        return match;
    }

    private static String waitFor(BlockingQueue<String> feed, String needle) throws InterruptedException {
        long until = System.currentTimeMillis() + 5000;
        while (System.currentTimeMillis() < until) {
            String line = feed.poll(200, TimeUnit.MILLISECONDS);
            if (line != null && line.contains(needle)) {
                return line;
            }
        }
        throw new AssertionError("No stream event containing " + needle);
    }

    interface Call<T> {
        T run() throws Exception;
    }

    private static <T> T uncheck(Call<T> call) {
        try {
            return call.run();
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}
