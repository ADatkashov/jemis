package kz.jemis.integration;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

class PurchaseFlowIT extends IntegrationTestBase {
    @Autowired kz.jemis.payment.MockPaymentProvider mock;

    @Test
    void catalogSearchFilterSortAndLocalization() throws Exception {
        String cat = createCategory();
        String cheap = createProduct(cat, 100, null, 10, "PIECE", false, 1000);
        String mid = createProduct(cat, 500, 700L, 10, "PIECE", false, 1000);
        String dear = createProduct(cat, 900, null, 10, "PIECE", false, 1000);
        String outOfStock = createProduct(cat, 300, null, 0, "PIECE", false, 1000);

        JsonNode all = get("/api/v1/catalog/products?categoryId=" + cat + "&sort=price_desc", null, 200);
        assertThat(all.get("totalElements").asInt()).isEqualTo(4);
        assertThat(all.get("items").get(0).get("id").asText()).isEqualTo(dear);

        JsonNode inStock = get("/api/v1/catalog/products?categoryId=" + cat + "&inStock=true", null, 200);
        assertThat(inStock.get("totalElements").asInt()).isEqualTo(3);
        JsonNode oos = get("/api/v1/catalog/products?categoryId=" + cat, null, 200);
        boolean sawOos = false;
        for (JsonNode p : oos.get("items")) if (p.get("id").asText().equals(outOfStock)) { sawOos = true; assertThat(p.get("available").asBoolean()).isFalse(); }
        assertThat(sawOos).isTrue();

        JsonNode range = get("/api/v1/catalog/products?categoryId=" + cat + "&minPrice=20000&maxPrice=60000", null, 200);
        assertThat(range.get("totalElements").asInt()).isEqualTo(2);

        JsonNode disc = get("/api/v1/catalog/products?categoryId=" + cat + "&discounted=true", null, 200);
        assertThat(disc.get("totalElements").asInt()).isEqualTo(1);
        assertThat(disc.get("items").get(0).get("discountPercent").asInt()).isEqualTo(29);

        // backend search by name in any language; '%' and '_' are literals
        String nameEn = productAdmin(mid).get("nameEn").asText();
        assertThat(get("/api/v1/catalog/products?q=" + nameEn.toLowerCase(), null, 200).get("totalElements").asInt()).isEqualTo(1);
        assertThat(get("/api/v1/catalog/products?q=%", null, 200).get("totalElements").asInt()).isZero();
        get("/api/v1/catalog/products?sort=bogus", null, 400);

        // localization
        var req = MockMvcRequestBuilders.get("/api/v1/catalog/products/" + cheap).header("Accept-Language", "kk");
        JsonNode kk = json.readTree(mvc.perform(req).andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        assertThat(kk.get("product").get("name").asText()).startsWith("Тауар");
        assertThat(get("/api/v1/catalog/products/" + cheap, null, 200).get("product").get("name").asText()).startsWith("Товар");
    }

    @Test
    void cartMathStepsAndStockLimits() throws Exception {
        String cat = createCategory();
        String kg = createProduct(cat, 790, null, 10, "KG", true, 500);      // 790 KZT/kg, 10 kg
        Customer c = registerCustomer();
        addToCart(c, kg, 1300, 400);                                        // not a multiple of 0.5 kg
        addToCart(c, kg, 11_000, 409);                                      // more than in stock
        addToCart(c, kg, 1500, 200);
        JsonNode cart = get("/api/v1/cart", c.token(), 200);
        assertThat(cart.get("subtotalMinor").asLong()).isEqualTo(118_500);   // 1.5 kg * 790.00
        assertThat(cart.get("lines").get(0).get("lineTotalMinor").asLong()).isEqualTo(118_500);
        assertThat(cart.get("totalMinor").asLong()).isEqualTo(cart.get("subtotalMinor").asLong() + cart.get("deliveryFeeMinor").asLong()
                + cart.get("serviceFeeMinor").asLong() - cart.get("discountMinor").asLong());
        call(MockMvcRequestBuilders.delete("/api/v1/cart/items/" + kg), c.token(), null, 200);
        assertThat(get("/api/v1/cart", c.token(), 200).get("lines")).isEmpty();
    }

    @Test
    void cashCheckoutReservesStockIdempotentAndFullLifecycle() throws Exception {
        String city = createZone(990, 3000, 15_000L);
        String slot = createSlot(10, 0);
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 10, "PIECE", false, 1000);
        Customer c = registerCustomer();
        String addr = createAddress(c, city);
        addToCart(c, p, 4000, 200);

        Map<String, Object> body = checkoutBody(addr, slot, "CASH");
        String key = "idem-" + rnd();
        JsonNode first = checkout(c, key, body, 201);
        // cart was emptied by the first checkout: the retry must replay the same order, not fail or duplicate
        JsonNode retry = checkout(c, key, body, 201);
        assertThat(retry.get("id").asText()).isEqualTo(first.get("id").asText());

        assertThat(first.get("status").asText()).isEqualTo("CONFIRMED");
        assertThat(first.get("paymentStatus").asText()).isEqualTo("PENDING");
        assertThat(first.get("subtotalMinor").asLong()).isEqualTo(400_000);
        assertThat(first.get("deliveryFeeMinor").asLong()).isEqualTo(99_000);
        assertThat(first.get("totalMinor").asLong()).isEqualTo(499_000);
        String id = first.get("id").asText();

        // reserved, not yet deducted
        JsonNode prod = productAdmin(p);
        assertThat(prod.get("stockMilli").asLong()).isEqualTo(10_000);
        assertThat(prod.get("reservedMilli").asLong()).isEqualTo(4_000);

        // permitted transitions only
        adminStatus(id, "DELIVERED", 409);
        adminStatus(id, "ACCEPTED", 200);
        adminStatus(id, "PREPARING", 200);
        adminStatus(id, "READY_FOR_DELIVERY", 200);
        adminStatus(id, "PICKED_UP", 409);
        adminStatus(id, "REFUNDED", 400);
        adminStatus(id, "PICKED_UP", 409);
        // customer can no longer cancel once preparing
        post("/api/v1/orders/" + id + "/cancel", c.token(), null, 409);
        // operator override of the courier leg
        post("/api/v1/admin/orders/" + id + "/status", admin(), Map.of("status", "ASSIGNED_TO_COURIER"), 400);

        JsonNode detail = get("/api/v1/admin/orders/" + id, admin(), 200);
        assertThat(detail.get("order").get("status").asText()).isEqualTo("READY_FOR_DELIVERY");
        assertThat(detail.get("order").get("timeline")).hasSizeGreaterThanOrEqualTo(4);
        assertThat(get("/api/v1/notifications", c.token(), 200).get("totalElements").asInt()).isGreaterThanOrEqualTo(2);
    }

    @Test
    void cancellingReleasesStockPromoAndCapacity() throws Exception {
        String city = createZone(0, 0, null);
        String slot = createSlot(1, 0);
        String cat = createCategory();
        String p = createProduct(cat, 500, null, 5, "PIECE", false, 1000);
        Customer a = registerCustomer();
        Customer b = registerCustomer();
        String addrA = createAddress(a, city);
        String addrB = createAddress(b, city);

        addToCart(a, p, 2000, 200);
        JsonNode orderA = checkout(a, "k" + rnd(), checkoutBody(addrA, slot, "CASH"), 201);
        assertThat(productAdmin(p).get("reservedMilli").asLong()).isEqualTo(2000);

        // slot capacity is 1: the second customer is rejected
        addToCart(b, p, 1000, 200);
        JsonNode full = checkout(b, "k" + rnd(), checkoutBody(addrB, slot, "CASH"), 409);
        assertThat(full.get("code").asText()).isEqualTo("SLOT_FULL");

        // cancel -> stock and capacity return
        JsonNode cancelled = post("/api/v1/orders/" + orderA.get("id").asText() + "/cancel", a.token(), null, 200);
        assertThat(cancelled.get("status").asText()).isEqualTo("CANCELLED");
        assertThat(productAdmin(p).get("reservedMilli").asLong()).isZero();
        checkout(b, "k" + rnd(), checkoutBody(addrB, slot, "CASH"), 201);
    }

    @Test
    void stockIsCommittedWhenPickedUpAndCashSettlesOnDelivery() throws Exception {
        String city = createZone(0, 0, null);
        String slot = createSlot(10, 0);
        String cat = createCategory();
        String p = createProduct(cat, 400, null, 10, "PIECE", false, 1000);
        Customer c = registerCustomer();
        String addr = createAddress(c, city);
        addToCart(c, p, 3000, 200);
        JsonNode o = checkout(c, "k" + rnd(), checkoutBody(addr, slot, "CASH"), 201);
        String id = o.get("id").asText();

        // courier account
        String email = "cour" + rnd() + "@test.jemis";
        JsonNode staff = post("/api/v1/admin/staff", admin(), Map.of("email", email, "fullName", "Test Courier", "password", "CourierPass123!",
                "role", "COURIER", "phone", "+7701" + (1000000 + new java.util.Random().nextInt(8999999))), 201);
        String courier = login(email, "CourierPass123!");
        String courierId = null;
        for (JsonNode row : get("/api/v1/admin/delivery/couriers", admin(), 200)) if (row.get("userId").asText().equals(staff.get("id").asText())) courierId = row.get("id").asText();
        assertThat(courierId).isNotNull();

        adminStatus(id, "ACCEPTED", 200);
        adminStatus(id, "PREPARING", 200);
        post("/api/v1/admin/orders/" + id + "/assign", admin(), Map.of("courierId", courierId), 409); // not ready yet
        adminStatus(id, "READY_FOR_DELIVERY", 200);
        post("/api/v1/admin/orders/" + id + "/assign", admin(), Map.of("courierId", courierId), 201);

        JsonNode mine = get("/api/v1/courier/assignments", courier, 200);
        assertThat(mine).hasSize(1);
        String assignmentId = mine.get(0).get("assignmentId").asText();
        assertThat(mine.get(0).get("collectCash").asBoolean()).isTrue();

        // another courier cannot touch it, location needs consent
        put("/api/v1/courier/location", courier, Map.of("latitude", 43.25, "longitude", 76.95), 403);
        post("/api/v1/courier/orders/" + id + "/status", courier, Map.of("status", "PICKED_UP"), 404);
        post("/api/v1/courier/assignments/" + assignmentId + "/accept", courier, null, 204);
        assertThat(get("/api/v1/admin/orders/" + id, admin(), 200).get("order").get("status").asText()).isEqualTo("ASSIGNED_TO_COURIER");

        // customer tracking: honest, privacy preserving
        JsonNode t = get("/api/v1/orders/" + id + "/tracking", c.token(), 200);
        assertThat(t.get("liveTracking").asBoolean()).isFalse();
        assertThat(t.has("eta")).isFalse();
        assertThat(t.get("courier").get("name").asText()).isEqualTo("Test Courier");
        assertThat(t.get("courier").get("maskedPhone").asText()).doesNotContain(staff.get("email").asText()).hasSizeLessThan(12);

        put("/api/v1/courier/tracking-consent", courier, Map.of("enabled", true), 204);
        put("/api/v1/courier/location", courier, Map.of("latitude", 43.25, "longitude", 76.95), 204);
        assertThat(get("/api/v1/orders/" + id + "/tracking", c.token(), 200).get("courier").get("lastKnownLocation").get("latitude").asDouble()).isEqualTo(43.25);

        post("/api/v1/courier/orders/" + id + "/status", courier, Map.of("status", "PICKED_UP"), 204);
        JsonNode afterPickup = productAdmin(p);
        assertThat(afterPickup.get("stockMilli").asLong()).isEqualTo(7000);   // deducted at pick-up
        assertThat(afterPickup.get("reservedMilli").asLong()).isZero();
        post("/api/v1/courier/orders/" + id + "/status", courier, Map.of("status", "DELIVERED"), 409); // must be ON_THE_WAY first
        post("/api/v1/courier/orders/" + id + "/status", courier, Map.of("status", "ON_THE_WAY"), 204);
        post("/api/v1/courier/orders/" + id + "/issues", courier, Map.of("description", "Customer not answering the door"), 201);
        post("/api/v1/courier/orders/" + id + "/status", courier, Map.of("status", "DELIVERED"), 204);

        JsonNode done = get("/api/v1/orders/" + id, c.token(), 200);
        assertThat(done.get("status").asText()).isEqualTo("DELIVERED");
        assertThat(done.get("paymentStatus").asText()).isEqualTo("SUCCEEDED");   // cash settled at hand-over
        post("/api/v1/orders/" + id + "/cancel", c.token(), null, 409);

        // reorder puts the items back into the cart
        JsonNode re = post("/api/v1/orders/" + id + "/reorder", c.token(), null, 200);
        assertThat(re.get("cart").get("lines")).hasSize(1);
        // location data is dropped when consent is withdrawn
        put("/api/v1/courier/tracking-consent", courier, Map.of("enabled", false), 204);
    }

    @Test
    void onlinePaymentIsOnlyConfirmedByASignedNotificationAndIsIdempotent() throws Exception {
        String city = createZone(0, 0, null);
        String slot = createSlot(10, 0);
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 10, "PIECE", false, 1000);
        Customer c = registerCustomer();
        String addr = createAddress(c, city);
        addToCart(c, p, 2000, 200);

        JsonNode methods = get("/api/v1/payments/methods", c.token(), 200);
        boolean online = false;
        for (JsonNode m : methods) if (m.get("method").asText().equals("ONLINE")) { online = true; assertThat(m.get("developmentOnly").asBoolean()).isTrue(); }
        assertThat(online).isTrue();

        JsonNode order = checkout(c, "k" + rnd(), checkoutBody(addr, slot, "ONLINE"), 201);
        String id = order.get("id").asText();
        assertThat(order.get("status").asText()).isEqualTo("PENDING_PAYMENT");

        JsonNode pay = post("/api/v1/payments/orders/" + id + "/initiate", c.token(), null, 200);
        assertThat(pay.get("developmentOnly").asBoolean()).isTrue();
        // a second initiate returns the same open attempt
        assertThat(post("/api/v1/payments/orders/" + id + "/initiate", c.token(), null, 200).get("id").asText()).isEqualTo(pay.get("id").asText());
        // nothing but the provider can confirm: unsigned / badly signed / replayed amounts are rejected
        String ref = fetchProviderRef(id);
        String event = "{\"eventId\":\"e-" + rnd() + "\",\"providerRef\":\"" + ref + "\",\"type\":\"SUCCEEDED\",\"amountMinor\":200000}";
        webhook(event, null, 401);
        webhook(event, "deadbeef", 401);
        assertThat(get("/api/v1/orders/" + id, c.token(), 200).get("status").asText()).isEqualTo("PENDING_PAYMENT");

        // wrong amount: signed but must not mark the order as paid
        String wrongAmount = "{\"eventId\":\"e-" + rnd() + "\",\"providerRef\":\"" + ref + "\",\"type\":\"SUCCEEDED\",\"amountMinor\":1}";
        assertThat(webhook(wrongAmount, mock.sign(wrongAmount.getBytes(StandardCharsets.UTF_8)), 200).get("result").asText()).isEqualTo("IGNORED");
        assertThat(get("/api/v1/orders/" + id, c.token(), 200).get("paymentStatus").asText()).isEqualTo("PENDING");

        // valid notification applies once; the replay is a no-op
        assertThat(webhook(event, mock.sign(event.getBytes(StandardCharsets.UTF_8)), 200).get("result").asText()).isEqualTo("APPLIED");
        assertThat(webhook(event, mock.sign(event.getBytes(StandardCharsets.UTF_8)), 200).get("result").asText()).isEqualTo("DUPLICATE");
        JsonNode paid = get("/api/v1/orders/" + id, c.token(), 200);
        assertThat(paid.get("status").asText()).isEqualTo("CONFIRMED");
        assertThat(paid.get("paymentStatus").asText()).isEqualTo("SUCCEEDED");
        assertThat(get("/api/v1/notifications", c.token(), 200).get("items").toString()).contains("PAYMENT_SUCCEEDED");

        // refund path: cancel the paid order, then refund through the provider
        adminStatus(id, "CANCELLED", 200);
        assertThat(get("/api/v1/admin/orders/" + id, admin(), 200).get("order").get("paymentStatus").asText()).isEqualTo("SUCCEEDED");
        JsonNode refunded = post("/api/v1/admin/orders/" + id + "/refund", admin(), null, 200);
        assertThat(refunded.get("order").get("status").asText()).isEqualTo("REFUNDED");
        assertThat(refunded.get("order").get("paymentStatus").asText()).isEqualTo("REFUNDED");
        post("/api/v1/admin/orders/" + id + "/refund", admin(), null, 409);
    }

    @Test
    void failedPaymentAllowsRetryAndAbandonedOrdersAreCancelled() throws Exception {
        String city = createZone(0, 0, null);
        String slot = createSlot(10, 0);
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 10, "PIECE", false, 1000);
        Customer c = registerCustomer();
        String addr = createAddress(c, city);
        addToCart(c, p, 1000, 200);
        String id = checkout(c, "k" + rnd(), checkoutBody(addr, slot, "ONLINE"), 201).get("id").asText();
        String payId = post("/api/v1/payments/orders/" + id + "/initiate", c.token(), null, 200).get("id").asText();
        post("/api/v1/dev/payments/" + payId + "/simulate?outcome=failure", c.token(), null, 200);
        JsonNode failed = get("/api/v1/orders/" + id, c.token(), 200);
        assertThat(failed.get("status").asText()).isEqualTo("PENDING_PAYMENT");
        assertThat(failed.get("paymentStatus").asText()).isEqualTo("FAILED");
        // retry creates a fresh attempt
        String payId2 = post("/api/v1/payments/orders/" + id + "/initiate", c.token(), null, 200).get("id").asText();
        assertThat(payId2).isNotEqualTo(payId);
        post("/api/v1/dev/payments/" + payId2 + "/simulate?outcome=success", c.token(), null, 200);
        assertThat(get("/api/v1/orders/" + id, c.token(), 200).get("status").asText()).isEqualTo("CONFIRMED");

        // another customer cannot drive someone else's payment
        Customer other = registerCustomer();
        post("/api/v1/dev/payments/" + payId2 + "/simulate?outcome=success", other.token(), null, 404);
        post("/api/v1/payments/orders/" + id + "/initiate", other.token(), null, 404);

        // abandoned: the expiry job cancels unpaid online orders and releases the reservation
        addToCart(c, p, 1000, 200);
        String abandoned = checkout(c, "k" + rnd(), checkoutBody(addr, slot, "ONLINE"), 201).get("id").asText();
        long reservedBefore = productAdmin(p).get("reservedMilli").asLong();
        expireService.cancelIfStillUnpaid(java.util.UUID.fromString(abandoned));
        assertThat(get("/api/v1/orders/" + abandoned, c.token(), 200).get("status").asText()).isEqualTo("CANCELLED");
        assertThat(productAdmin(p).get("reservedMilli").asLong()).isEqualTo(reservedBefore - 1000);
    }

    @Autowired kz.jemis.order.OrderService expireService;
    @Autowired org.springframework.jdbc.core.JdbcTemplate jdbc;

    private String fetchProviderRef(String orderId) {
        return jdbc.queryForObject("select provider_ref from payments where order_id = ?::uuid and status = 'PENDING'", String.class, orderId);
    }

    private JsonNode webhook(String body, String signature, int expected) throws Exception {
        var b = MockMvcRequestBuilders.post("/api/v1/payments/webhooks/mock").contentType(MediaType.APPLICATION_JSON).content(body);
        if (signature != null) b.header("X-Jemis-Signature", signature);
        var res = mvc.perform(b).andReturn().getResponse();
        assertThat(res.getStatus()).isEqualTo(expected);
        String s = res.getContentAsString();
        return s.isBlank() ? json.createObjectNode() : json.readTree(s);
    }

    @Test
    void serverRecalculatesAndBlocksStaleOrInvalidCheckouts() throws Exception {
        String city = createZone(1000, 5000, null);
        String other = createZone(500, 0, null);
        String slot = createSlot(10, 200);
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 10, "PIECE", false, 1000);
        Customer c = registerCustomer();
        String addr = createAddress(c, city);
        String unserviceable = createAddress(c, "Nowhere" + rnd());

        // minimum order not met -> blocked
        addToCart(c, p, 2000, 200);
        JsonNode blocked = checkout(c, "k" + rnd(), checkoutBody(addr, slot, "CASH"), 409);
        assertThat(blocked.get("code").asText()).isEqualTo("CHECKOUT_BLOCKED");
        assertThat(blocked.get("details").get("issues").toString()).contains("MIN_ORDER_NOT_MET");

        // address outside every delivery zone
        addToCart(c, p, 6000, 200);
        JsonNode nowhere = checkout(c, "k" + rnd(), checkoutBody(unserviceable, slot, "CASH"), 409);
        assertThat(nowhere.get("details").get("issues").toString()).contains("ADDRESS_NOT_SERVICEABLE");

        // stock drops after the item was put in the cart -> explicit, per-item error instead of overselling
        post("/api/v1/admin/products/" + p + "/stock", admin(), Map.of("deltaMilli", -8000, "reason", "write-off"), 200);
        JsonNode lowStock = checkout(c, "k" + rnd(), checkoutBody(addr, slot, "CASH"), 409);
        assertThat(lowStock.get("details").get("issues").toString()).contains("UNAVAILABLE_ITEMS");
        assertThat(get("/api/v1/cart", c.token(), 200).get("lines").get(0).get("issue").asText()).isEqualTo("INSUFFICIENT_STOCK");
        // and the delivery slot fee is added server-side
        post("/api/v1/admin/products/" + p + "/stock", admin(), Map.of("deltaMilli", 8000, "reason", "restock"), 200);
        JsonNode ok = checkout(c, "k" + rnd(), checkoutBody(addr, slot, "CASH"), 201);
        assertThat(ok.get("deliveryFeeMinor").asLong()).isEqualTo(100_000 + 20_000);
    }

    @Test
    void priceChangeBetweenCartAndCheckoutIsReportedNotSilentlyApplied() throws Exception {
        String city = createZone(0, 0, null);
        String slot = createSlot(10, 0);
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 10, "PIECE", false, 1000);
        Customer c = registerCustomer();
        String addr = createAddress(c, city);
        addToCart(c, p, 2000, 200);
        long seenTotal = get("/api/v1/cart", c.token(), 200).get("subtotalMinor").asLong();
        assertThat(seenTotal).isEqualTo(200_000);

        // operator raises the price
        JsonNode prod = productAdmin(p);
        var upd = new java.util.HashMap<String, Object>();
        upd.put("categoryId", prod.get("categoryId").asText());
        upd.put("sku", prod.get("sku").asText());
        upd.put("nameRu", prod.get("nameRu").asText());
        upd.put("nameKk", prod.get("nameKk").asText());
        upd.put("nameEn", prod.get("nameEn").asText());
        upd.put("unit", "PIECE");
        upd.put("weighted", false);
        upd.put("stepMilli", 1000);
        upd.put("priceMinor", 150_000);
        upd.put("lowStockMilli", 1000);
        upd.put("active", true);
        put("/api/v1/admin/products/" + p, admin(), upd, 200);

        Map<String, Object> body = new java.util.HashMap<>(checkoutBody(addr, slot, "CASH"));
        body.put("expectedTotalMinor", seenTotal);
        JsonNode changed = checkout(c, "k" + rnd(), body, 409);
        assertThat(changed.get("code").asText()).isEqualTo("PRICE_CHANGED");
        assertThat(changed.get("details").get("totalMinor").asLong()).isEqualTo(300_000);
        body.put("expectedTotalMinor", 300_000);
        assertThat(checkout(c, "k" + rnd(), body, 201).get("totalMinor").asLong()).isEqualTo(300_000);
    }

    @Test
    void concurrentCheckoutsCannotOversellTheLastItem() throws Exception {
        String city = createZone(0, 0, null);
        String slot = createSlot(50, 0);
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 1, "PIECE", false, 1000);   // exactly one item
        int n = 6;
        List<Customer> customers = new ArrayList<>();
        List<String> addrs = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            Customer c = registerCustomer();
            customers.add(c);
            addrs.add(createAddress(c, city));
            addToCart(c, p, 1000, 200);
        }
        ExecutorService pool = Executors.newFixedThreadPool(n);
        CountDownLatch go = new CountDownLatch(1);
        List<Future<Integer>> results = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            int idx = i;
            Callable<Integer> task = () -> {
                go.await();
                return mvc.perform(checkoutReq(customers.get(idx), "k" + idx + rnd(), checkoutBody(addrs.get(idx), slot, "CASH")))
                        .andReturn().getResponse().getStatus();
            };
            results.add(pool.submit(task));
        }
        go.countDown();
        int created = 0;
        for (Future<Integer> f : results) if (f.get() == 201) created++;
        pool.shutdown();
        assertThat(created).as("exactly one order may reserve the single item").isEqualTo(1);
        assertThat(productAdmin(p).get("reservedMilli").asLong()).isEqualTo(1000);
    }

    @Test
    void concurrentCheckoutsRespectSlotCapacity() throws Exception {
        String city = createZone(0, 0, null);
        String slot = createSlot(2, 0);   // two places only
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 100, "PIECE", false, 1000);
        int n = 6;
        List<Customer> customers = new ArrayList<>();
        List<String> addrs = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            Customer c = registerCustomer();
            customers.add(c);
            addrs.add(createAddress(c, city));
            addToCart(c, p, 1000, 200);
        }
        ExecutorService pool = Executors.newFixedThreadPool(n);
        CountDownLatch go = new CountDownLatch(1);
        List<Future<Integer>> results = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            int idx = i;
            results.add(pool.submit(() -> {
                go.await();
                return mvc.perform(checkoutReq(customers.get(idx), "k" + idx + rnd(), checkoutBody(addrs.get(idx), slot, "CASH")))
                        .andReturn().getResponse().getStatus();
            }));
        }
        go.countDown();
        int created = 0;
        for (Future<Integer> f : results) if (f.get() == 201) created++;
        pool.shutdown();
        assertThat(created).isEqualTo(2);
    }

    @Test
    void duplicateTapsWithSameKeyProduceOneOrder() throws Exception {
        String city = createZone(0, 0, null);
        String slot = createSlot(50, 0);
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 100, "PIECE", false, 1000);
        Customer c = registerCustomer();
        String addr = createAddress(c, city);
        addToCart(c, p, 1000, 200);
        String key = "dup-" + rnd();
        int n = 5;
        ExecutorService pool = Executors.newFixedThreadPool(n);
        CountDownLatch go = new CountDownLatch(1);
        List<Future<String>> results = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            results.add(pool.submit(() -> {
                go.await();
                var res = mvc.perform(checkoutReq(c, key, checkoutBody(addr, slot, "CASH"))).andReturn().getResponse();
                return res.getStatus() + ":" + json.readTree(res.getContentAsString()).path("id").asText();
            }));
        }
        go.countDown();
        java.util.Set<String> ids = new java.util.HashSet<>();
        for (Future<String> f : results) {
            String r = f.get();
            assertThat(r).startsWith("201:");
            ids.add(r.substring(4));
        }
        pool.shutdown();
        assertThat(ids).hasSize(1);
        assertThat(get("/api/v1/orders", c.token(), 200).get("totalElements").asInt()).isEqualTo(1);
        assertThat(productAdmin(p).get("reservedMilli").asLong()).isEqualTo(1000);
    }

    @Test
    void customersCannotAccessEachOthersData() throws Exception {
        String city = createZone(0, 0, null);
        String slot = createSlot(50, 0);
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 100, "PIECE", false, 1000);
        Customer a = registerCustomer();
        Customer b = registerCustomer();
        String addrA = createAddress(a, city);
        addToCart(a, p, 1000, 200);
        String orderA = checkout(a, "k" + rnd(), checkoutBody(addrA, slot, "CASH"), 201).get("id").asText();

        get("/api/v1/orders/" + orderA, b.token(), 404);
        get("/api/v1/orders/" + orderA + "/tracking", b.token(), 404);
        post("/api/v1/orders/" + orderA + "/cancel", b.token(), null, 404);
        post("/api/v1/orders/" + orderA + "/reorder", b.token(), null, 404);
        post("/api/v1/payments/orders/" + orderA + "/initiate", b.token(), null, 404);
        put("/api/v1/customer/addresses/" + addrA, b.token(), Map.of("city", "X", "street", "Y", "house", "1"), 404);
        call(MockMvcRequestBuilders.delete("/api/v1/customer/addresses/" + addrA), b.token(), null, 404);
        get("/api/v1/customer/addresses/" + addrA + "/serviceability", b.token(), 404);
        // someone else's address cannot be used at checkout
        addToCart(b, p, 1000, 200);
        checkout(b, "k" + rnd(), checkoutBody(addrA, slot, "CASH"), 404);
        // lists only show own data
        assertThat(get("/api/v1/orders", b.token(), 200).get("totalElements").asInt()).isZero();
        assertThat(get("/api/v1/customer/addresses", b.token(), 200)).isEmpty();
    }

    @Test
    void promoRulesAreEnforcedOnTheServer() throws Exception {
        String city = createZone(0, 0, null);
        String slot = createSlot(50, 0);
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 100, "PIECE", false, 1000);
        String discounted = createProduct(cat, 800, 1000L, 100, "PIECE", false, 1000);
        Customer c = registerCustomer();
        String addr = createAddress(c, city);
        String code = "T" + rnd().toUpperCase();
        post("/api/v1/admin/promotions", admin(), Map.of("code", code, "type", "PERCENT", "value", 10, "minOrderMinor", 150_000,
                "perCustomerLimit", 1, "usageLimit", 100, "stackable", false, "active", true), 201);
        post("/api/v1/admin/promotions", admin(), Map.of("code", code, "type", "PERCENT", "value", 10, "active", true), 409);
        String expired = "E" + rnd().toUpperCase();
        post("/api/v1/admin/promotions", admin(), Map.of("code", expired, "type", "FIXED", "value", 5000, "startsAt", "2020-01-01T00:00:00Z",
                "endsAt", "2020-02-01T00:00:00Z", "active", true), 201);

        addToCart(c, p, 1000, 200);   // 1000 KZT < min 1500
        var q = new java.util.HashMap<String, Object>(Map.of("addressId", addr, "promoCode", code));
        JsonNode below = post("/api/v1/checkout/quote", c.token(), q, 200);
        assertThat(below.get("promoError").asText()).isEqualTo("PROMO_MIN_ORDER");
        assertThat(below.get("discountMinor").asLong()).isZero();
        q.put("promoCode", expired);
        assertThat(post("/api/v1/checkout/quote", c.token(), q, 200).get("promoError").asText()).isEqualTo("PROMO_EXPIRED");
        q.put("promoCode", "NOSUCH");
        assertThat(post("/api/v1/checkout/quote", c.token(), q, 200).get("promoError").asText()).isEqualTo("PROMO_NOT_FOUND");

        // 1 x 1000 + 1 x 800 (already discounted -> excluded): eligible 1000 -> 10% = 100 KZT
        addToCart(c, discounted, 1000, 200);
        addToCart(c, p, 1000, 200);
        q.put("promoCode", code);
        JsonNode ok = post("/api/v1/checkout/quote", c.token(), q, 200);
        assertThat(ok.get("discountMinor").asLong()).isEqualTo(10_000);
        assertThat(ok.get("totalMinor").asLong()).isEqualTo(180_000 - 10_000);

        var body = checkoutBody(addr, slot, "CASH");
        body.put("promoCode", code);
        JsonNode order = checkout(c, "k" + rnd(), body, 201);
        assertThat(order.get("discountMinor").asLong()).isEqualTo(10_000);

        // per-customer limit: second use is refused with a clear code
        addToCart(c, p, 2000, 200);
        JsonNode second = checkout(c, "k" + rnd(), body, 400);
        assertThat(second.get("code").asText()).isEqualTo("PROMO_CUSTOMER_LIMIT");
        // cancelling frees the redemption
        post("/api/v1/orders/" + order.get("id").asText() + "/cancel", c.token(), null, 200);
        assertThat(checkout(c, "k" + rnd(), body, 201).get("discountMinor").asLong()).isPositive();
    }

    @Test
    void addressDefaultsFavoritesAndDeliveryAvailability() throws Exception {
        Customer c = registerCustomer();
        JsonNode a1 = post("/api/v1/customer/addresses", c.token(), Map.of("city", "Almaty", "street", "A", "house", "1"), 201);
        JsonNode a2 = post("/api/v1/customer/addresses", c.token(), Map.of("city", "Almaty", "street", "B", "house", "2", "isDefault", true), 201);
        assertThat(a1.get("isDefault").asBoolean()).isTrue();
        assertThat(a2.get("isDefault").asBoolean()).isTrue();
        int defaults = 0;
        for (JsonNode a : get("/api/v1/customer/addresses", c.token(), 200)) if (a.get("isDefault").asBoolean()) defaults++;
        assertThat(defaults).isEqualTo(1);
        post("/api/v1/customer/addresses", c.token(), Map.of("city", "", "street", "A", "house", "1"), 400);
        get("/api/v1/customer/addresses/" + a1.get("id").asText() + "/serviceability", c.token(), 200);

        String cat = createCategory();
        String p = createProduct(cat, 500, null, 5, "PIECE", false, 1000);
        put("/api/v1/customer/favorites/" + p, c.token(), null, 204);
        put("/api/v1/customer/favorites/" + p, c.token(), null, 204); // idempotent
        assertThat(get("/api/v1/customer/favorites", c.token(), 200)).hasSize(1);
        call(MockMvcRequestBuilders.delete("/api/v1/customer/favorites/" + p), c.token(), null, 204);
        assertThat(get("/api/v1/customer/favorites", c.token(), 200)).isEmpty();

        createSlot(3, 0);
        JsonNode av = get("/api/v1/delivery/availability", null, 200);
        assertThat(av.get("timezone").asText()).isEqualTo("Asia/Almaty");
        assertThat(av.get("days")).isNotEmpty();
    }

    @Test
    void adminDashboardCountsPaidRevenueOnly() throws Exception {
        long before = get("/api/v1/admin/dashboard", admin(), 200).get("paidRevenueTodayMinor").asLong();
        String city = createZone(0, 0, null);
        String slot = createSlot(50, 0);
        String cat = createCategory();
        String p = createProduct(cat, 1000, null, 100, "PIECE", false, 1000);
        Customer c = registerCustomer();
        String addr = createAddress(c, city);
        addToCart(c, p, 1000, 200);
        checkout(c, "k" + rnd(), checkoutBody(addr, slot, "ONLINE"), 201);   // unpaid online order
        long after = get("/api/v1/admin/dashboard", admin(), 200).get("paidRevenueTodayMinor").asLong();
        assertThat(after).as("unpaid orders are never revenue").isEqualTo(before);
        assertThat(get("/api/v1/admin/dashboard", admin(), 200).get("ordersToday").asLong()).isPositive();
        JsonNode list = get("/api/v1/admin/orders?status=PENDING_PAYMENT&size=5", admin(), 200);
        assertThat(list.get("totalElements").asInt()).isPositive();
    }
}
