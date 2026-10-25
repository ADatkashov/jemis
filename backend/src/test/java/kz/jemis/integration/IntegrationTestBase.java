package kz.jemis.integration;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeAll;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

/** Runs against a real PostgreSQL (see application-test.yml); every test creates its own uniquely named data. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@org.springframework.context.annotation.Import(TestBeans.class)
abstract class IntegrationTestBase {
    static final String ADMIN_EMAIL = "admin-test@jemis.local";
    static final String ADMIN_PASSWORD = "TestAdmin12345!";
    static final String PASSWORD = "Passw0rd!x";

    @Autowired protected MockMvc mvc;
    @Autowired protected ObjectMapper json;

    protected static String adminToken;

    protected JsonNode call(MockHttpServletRequestBuilder b, String token, Object body, int expected) throws Exception {
        if (token != null) b.header("Authorization", "Bearer " + token);
        if (body != null) b.contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsBytes(body));
        var res = mvc.perform(b).andExpect(status().is(expected)).andReturn().getResponse();
        String s = res.getContentAsString(java.nio.charset.StandardCharsets.UTF_8);
        return s.isBlank() ? json.createObjectNode() : json.readTree(s);
    }

    protected JsonNode get(String url, String token, int expected) throws Exception { return call(MockMvcRequestBuilders.get(url), token, null, expected); }
    protected JsonNode post(String url, String token, Object body, int expected) throws Exception { return call(MockMvcRequestBuilders.post(url), token, body, expected); }
    protected JsonNode put(String url, String token, Object body, int expected) throws Exception { return call(MockMvcRequestBuilders.put(url), token, body, expected); }

    protected String admin() throws Exception {
        if (adminToken == null) adminToken = login(ADMIN_EMAIL, ADMIN_PASSWORD);
        return adminToken;
    }

    protected String login(String id, String pw) throws Exception {
        return post("/api/v1/auth/login", null, Map.of("identifier", id, "password", pw), 200).get("accessToken").asText();
    }

    protected record Customer(String email, String token, UUID id) {}

    protected Customer registerCustomer() throws Exception {
        String email = "c" + UUID.randomUUID().toString().substring(0, 8) + "@test.jemis";
        JsonNode r = post("/api/v1/auth/register", null, Map.of("email", email, "password", PASSWORD, "fullName", "Test Customer"), 201);
        String token = r.get("accessToken").asText();
        UUID id = UUID.fromString(get("/api/v1/customer/me", token, 200).get("id").asText());
        return new Customer(email, token, id);
    }

    protected String rnd() { return UUID.randomUUID().toString().substring(0, 8); }

    protected String createCategory() throws Exception {
        String s = rnd();
        return post("/api/v1/admin/categories", admin(), Map.of("slug", "cat-" + s, "nameRu", "Кат " + s, "nameKk", "Санат " + s,
                "nameEn", "Cat " + s, "sortOrder", 0, "active", true), 201).get("id").asText();
    }

    /** Creates a product; priceTenge in KZT, stock in whole units. */
    protected String createProduct(String categoryId, long priceTenge, Long oldPriceTenge, long stockUnits, String unit, boolean weighted, int step) throws Exception {
        String s = rnd();
        var body = new java.util.HashMap<String, Object>();
        body.put("categoryId", categoryId);
        body.put("sku", "SKU-" + s);
        body.put("brand", "TestBrand");
        body.put("nameRu", "Товар " + s);
        body.put("nameKk", "Тауар " + s);
        body.put("nameEn", "Item " + s);
        body.put("unit", unit);
        body.put("weighted", weighted);
        body.put("stepMilli", step);
        body.put("priceMinor", priceTenge * 100);
        if (oldPriceTenge != null) body.put("oldPriceMinor", oldPriceTenge * 100);
        body.put("lowStockMilli", 1000);
        body.put("active", true);
        String id = post("/api/v1/admin/products", admin(), body, 201).get("id").asText();
        if (stockUnits > 0) {
            post("/api/v1/admin/products/" + id + "/stock", admin(), Map.of("deltaMilli", stockUnits * 1000, "reason", "initial"), 200);
        }
        return id;
    }

    /** Unique city with its own zone, so tests do not interfere. Returns the city name. */
    protected String createZone(long feeTenge, long minOrderTenge, Long freeFromTenge) throws Exception {
        String city = "City" + rnd();
        var body = new java.util.HashMap<String, Object>();
        body.put("name", city);
        body.put("city", city);
        body.put("feeMinor", feeTenge * 100);
        body.put("minOrderMinor", minOrderTenge * 100);
        if (freeFromTenge != null) body.put("freeDeliveryThresholdMinor", freeFromTenge * 100);
        body.put("active", true);
        post("/api/v1/admin/delivery/zones", admin(), body, 201);
        return city;
    }

    protected String createSlot(int capacity, long extraFeeTenge) throws Exception {
        return post("/api/v1/admin/delivery/slots", admin(), Map.of("startTime", "10:00", "endTime", "12:00", "capacity", capacity,
                "daysOfWeek", "1,2,3,4,5,6,7", "extraFeeMinor", extraFeeTenge * 100, "active", true), 201).get("id").asText();
    }

    protected String tomorrow() { return LocalDate.now(ZoneId.of("Asia/Almaty")).plusDays(1).toString(); }

    protected String createAddress(Customer c, String city) throws Exception {
        return post("/api/v1/customer/addresses", c.token(), Map.of("city", city, "street", "Test street", "house", "1", "apartment", "2"), 201)
                .get("id").asText();
    }

    protected void addToCart(Customer c, String productId, long quantityMilli, int expected) throws Exception {
        put("/api/v1/cart/items/" + productId, c.token(), Map.of("quantityMilli", quantityMilli), expected);
    }

    protected MockHttpServletRequestBuilder checkoutReq(Customer c, String key, Map<String, Object> body) throws Exception {
        return MockMvcRequestBuilders.post("/api/v1/checkout").header("Idempotency-Key", key).header("Authorization", "Bearer " + c.token())
                .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsBytes(body));
    }

    protected JsonNode checkout(Customer c, String key, Map<String, Object> body, int expected) throws Exception {
        var res = mvc.perform(checkoutReq(c, key, body)).andExpect(status().is(expected)).andReturn().getResponse();
        return json.readTree(res.getContentAsString(java.nio.charset.StandardCharsets.UTF_8));
    }

    protected Map<String, Object> checkoutBody(String addressId, String slotId, String method) {
        var m = new java.util.HashMap<String, Object>();
        m.put("addressId", addressId);
        m.put("slotTemplateId", slotId);
        m.put("slotDate", tomorrow());
        m.put("paymentMethod", method);
        return m;
    }

    protected JsonNode productAdmin(String id) throws Exception { return get("/api/v1/admin/products/" + id, admin(), 200); }

    protected void adminStatus(String orderId, String status, int expected) throws Exception {
        post("/api/v1/admin/orders/" + orderId + "/status", admin(), Map.of("status", status), expected);
    }
}
