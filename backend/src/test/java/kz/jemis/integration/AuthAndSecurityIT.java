package kz.jemis.integration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

class AuthAndSecurityIT extends IntegrationTestBase {

    @Test
    void registerLoginRefreshLogoutLifecycle() throws Exception {
        String email = "life" + rnd() + "@test.jemis";
        JsonNode reg = post("/api/v1/auth/register", null, Map.of("email", email, "password", PASSWORD, "fullName", "Life Cycle"), 201);
        String access = reg.get("accessToken").asText();
        assertThat(get("/api/v1/customer/me", access, 200).get("email").asText()).isEqualTo(email);

        JsonNode login = post("/api/v1/auth/login", null, Map.of("identifier", email, "password", PASSWORD), 200);
        String refresh = login.get("refreshToken").asText();

        JsonNode rotated = post("/api/v1/auth/refresh", null, Map.of("refreshToken", refresh), 200);
        String refresh2 = rotated.get("refreshToken").asText();
        assertThat(refresh2).isNotEqualTo(refresh);

        // reuse of the rotated token is treated as theft: every session of the user is revoked
        post("/api/v1/auth/refresh", null, Map.of("refreshToken", refresh), 401);
        post("/api/v1/auth/refresh", null, Map.of("refreshToken", refresh2), 401);

        String refresh3 = post("/api/v1/auth/login", null, Map.of("identifier", email, "password", PASSWORD), 200).get("refreshToken").asText();
        post("/api/v1/auth/logout", null, Map.of("refreshToken", refresh3), 204);
        post("/api/v1/auth/refresh", null, Map.of("refreshToken", refresh3), 401);
    }

    @Test
    void wrongPasswordAndUnknownUserGiveTheSameError() throws Exception {
        Customer c = registerCustomer();
        JsonNode wrong = post("/api/v1/auth/login", null, Map.of("identifier", c.email(), "password", "nope-nope-nope"), 401);
        JsonNode unknown = post("/api/v1/auth/login", null, Map.of("identifier", "ghost" + rnd() + "@test.jemis", "password", "nope-nope-nope"), 401);
        assertThat(wrong.get("code").asText()).isEqualTo(unknown.get("code").asText()).isEqualTo("INVALID_CREDENTIALS");
        assertThat(wrong.get("message").asText()).isEqualTo(unknown.get("message").asText());
    }

    @Test
    void passwordResetAlwaysAcceptedAndTokenWorksOnce() throws Exception {
        Customer c = registerCustomer();
        post("/api/v1/auth/password/reset-request", null, Map.of("identifier", "nobody" + rnd() + "@test.jemis"), 202);
        post("/api/v1/auth/password/reset-request", null, Map.of("identifier", c.email()), 202);
        String token = TestBeans.RESET_TOKENS.get(c.id());
        assertThat(token).isNotBlank();
        post("/api/v1/auth/password/reset-confirm", null, Map.of("token", token, "newPassword", "BrandNewPass1!"), 204);
        post("/api/v1/auth/password/reset-confirm", null, Map.of("token", token, "newPassword", "AnotherPass1!"), 400);
        post("/api/v1/auth/login", null, Map.of("identifier", c.email(), "password", PASSWORD), 401);
        login(c.email(), "BrandNewPass1!");
    }

    @Test
    void duplicateRegistrationAndValidation() throws Exception {
        Customer c = registerCustomer();
        post("/api/v1/auth/register", null, Map.of("email", c.email(), "password", PASSWORD, "fullName", "Dup"), 409);
        JsonNode bad = post("/api/v1/auth/register", null, Map.of("email", "not-an-email", "password", "short", "fullName", "x"), 400);
        assertThat(bad.get("code").asText()).isEqualTo("VALIDATION_ERROR");
        assertThat(bad.get("details").has("password")).isTrue();
    }

    @Test
    void accountDeletionRequestLocksTheAccount() throws Exception {
        Customer c = registerCustomer();
        call(MockMvcRequestBuilders.delete("/api/v1/customer/me"), c.token(), null, 202);
        post("/api/v1/auth/login", null, Map.of("identifier", c.email(), "password", PASSWORD), 401);
    }

    @Test
    void authorizationIsEnforcedOnTheBackend() throws Exception {
        Customer c = registerCustomer();
        mvc.perform(MockMvcRequestBuilders.get("/api/v1/cart")).andExpect(status().isUnauthorized());
        mvc.perform(MockMvcRequestBuilders.get("/api/v1/admin/dashboard")).andExpect(status().isUnauthorized());
        get("/api/v1/admin/dashboard", c.token(), 403);
        get("/api/v1/admin/orders", c.token(), 403);
        get("/api/v1/courier/assignments", c.token(), 403);
        get("/api/v1/admin/dashboard", admin(), 200);
        // forged / garbage tokens
        mvc.perform(MockMvcRequestBuilders.get("/api/v1/customer/me").header("Authorization", "Bearer garbage")).andExpect(status().isUnauthorized());
    }

    @Test
    void managerCannotUseAdminOnlyEndpoints() throws Exception {
        String email = "mgr" + rnd() + "@test.jemis";
        post("/api/v1/admin/staff", admin(), Map.of("email", email, "fullName", "Manager", "password", "ManagerPass123!", "role", "MANAGER"), 201);
        String mgr = login(email, "ManagerPass123!");
        get("/api/v1/admin/dashboard", mgr, 200);
        get("/api/v1/admin/staff", mgr, 403);
        get("/api/v1/admin/settings", mgr, 403);
        get("/api/v1/admin/audit-log", mgr, 403);
        post("/api/v1/admin/staff", mgr, Map.of("email", "x" + rnd() + "@test.jemis", "fullName", "X", "password", "ManagerPass123!", "role", "ADMIN"), 403);
    }

    @Test
    void healthEndpointIsPublicAndOpenApiIsDisabledByDefault() throws Exception {
        mvc.perform(MockMvcRequestBuilders.get("/actuator/health")).andExpect(status().isOk());
    }
}
