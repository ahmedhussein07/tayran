package com.tayran;

import org.junit.jupiter.api.Test;

import java.net.HttpCookie;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/** Admin login, lockout, the refresh cookie, and role separation, over real HTTP. */
class AdminAuthIntegrationTest extends IntegrationTestBase {

    @Test
    void seedAdminLogsInAndGetsAnHttpOnlyRefreshCookie() throws Exception {
        Res login = post("/admin/auth/login", Map.of("phone", ADMIN_PHONE, "password", ADMIN_PASSWORD), null);
        assertThat(login.status()).isEqualTo(200);
        assertThat(login.content().get("accessToken").asString()).isNotBlank();
        assertThat(login.content().has("refreshToken")).isFalse();
        assertThat(login.content().get("admin").get("phone").asString()).isEqualTo("+2" + ADMIN_PHONE);
        assertThat(login.content().get("admin").has("passwordHash")).isFalse();

        String setCookie = login.headers().firstValue("Set-Cookie").orElseThrow();
        assertThat(setCookie).contains("tayran_admin_rt=").contains("HttpOnly").contains("SameSite=Strict")
                .contains("Path=/api/v1/admin/auth");

        String token = login.content().get("accessToken").asString();
        assertThat(get("/admin/me", token, null).content().get("name").asString()).isEqualTo("Admin");
        assertThat(get("/admin/categories", token, null).status()).isEqualTo(200);
    }

    @Test
    void wrongPasswordAndUnknownPhoneGetTheSameGenericError() throws Exception {
        Res wrong = post("/admin/auth/login", Map.of("phone", ADMIN_PHONE, "password", "NotThePassword99"), null);
        Res unknown = post("/admin/auth/login", Map.of("phone", "01299999999", "password", "NotThePassword99"), null);
        Res garbage = post("/admin/auth/login", Map.of("phone", "not a phone", "password", "x"), null);

        for (Res res : List.of(wrong, unknown, garbage)) {
            assertThat(res.status()).isEqualTo(401);
            assertThat(res.code()).isEqualTo("INVALID_CREDENTIALS");
            assertThat(res.content() == null || res.content().isNull()).isTrue();
        }
        assertThat(wrong.body().get("messageEn").asString()).isEqualTo(unknown.body().get("messageEn").asString());

        // The seed admin isn't affected by one failure.
        assertThat(adminToken()).isNotBlank();
    }

    @Test
    void fiveFailuresLockTheAccountAndTheSixthAttemptIsRefusedEvenWithTheRightPassword() throws Exception {
        String admin = adminToken();
        String phone = "01277777777";
        String password = "LockoutTest1234";
        Res created = post("/admin/users", Map.of("name", "Lock Test", "phone", phone, "password", password), admin);
        assertThat(created.status()).isEqualTo(200);
        long id = created.content().get("id").asLong();

        for (int i = 0; i < 5; i++) {
            assertThat(post("/admin/auth/login", Map.of("phone", phone, "password", "WrongPassword" + i), null).code())
                    .isEqualTo("INVALID_CREDENTIALS");
        }
        Res locked = post("/admin/auth/login", Map.of("phone", phone, "password", password), null);
        assertThat(locked.status()).isEqualTo(423);
        assertThat(locked.code()).isEqualTo("ACCOUNT_LOCKED");
        assertThat(locked.content().get("retryAfterSeconds").asLong()).isBetween(1L, 15L * 60);

        // Another admin can see the lock and clear it with a password reset.
        Res listed = get("/admin/users", admin, null);
        boolean[] seenLocked = {false};
        listed.content().forEach(u -> {
            if (u.get("id").asLong() == id) {
                seenLocked[0] = u.get("locked").asBoolean();
            }
        });
        assertThat(seenLocked[0]).isTrue();
        assertThat(put("/admin/users/" + id + "/password", Map.of("password", "ResetPassword5678"), admin).status()).isEqualTo(200);
        assertThat(post("/admin/auth/login", Map.of("phone", phone, "password", "ResetPassword5678"), null).status()).isEqualTo(200);
    }

    @Test
    void customerTokenIsForbiddenOnAdminEndpointsAndAdminTokenIsNotACustomer() throws Exception {
        String customer = customerToken("01011122233");
        Res forbidden = get("/admin/categories", customer, null);
        assertThat(forbidden.status()).isEqualTo(403);
        assertThat(forbidden.code()).isEqualTo("FORBIDDEN");
        assertThat(post("/admin/users", Map.of("name", "Nope", "phone", "01233333333", "password", "Password12345"), customer)
                .status()).isEqualTo(403);

        assertThat(get("/admin/categories", null, null).status()).isEqualTo(401);
    }

    @Test
    void refreshRotatesTheCookieAndLogoutRevokesIt() throws Exception {
        Res login = post("/admin/auth/login", Map.of("phone", ADMIN_PHONE, "password", ADMIN_PASSWORD), null);
        String cookie = refreshCookie(login);

        Res refreshed = postWithCookie("/admin/auth/refresh", cookie);
        assertThat(refreshed.status()).isEqualTo(200);
        String rotated = refreshCookie(refreshed);
        assertThat(rotated).isNotEqualTo(cookie);

        // The old cookie is spent; reusing it revokes the family.
        assertThat(postWithCookie("/admin/auth/refresh", cookie).status()).isEqualTo(401);
        assertThat(postWithCookie("/admin/auth/refresh", rotated).status()).isEqualTo(401);

        // Without a cookie refresh is refused.
        assertThat(post("/admin/auth/refresh", Map.of(), null).status()).isEqualTo(401);

        // Logout revokes the cookie's token and clears the cookie.
        String fresh = refreshCookie(post("/admin/auth/login", Map.of("phone", ADMIN_PHONE, "password", ADMIN_PASSWORD), null));
        Res logout = postWithCookie("/admin/auth/logout", fresh);
        assertThat(logout.status()).isEqualTo(200);
        assertThat(logout.headers().firstValue("Set-Cookie").orElseThrow()).contains("Max-Age=0");
        assertThat(postWithCookie("/admin/auth/refresh", fresh).status()).isEqualTo(401);
    }

    @Test
    void weakPasswordsAreRefusedWhenCreatingAnAdmin() throws Exception {
        Res weak = post("/admin/users", Map.of("name", "Weak One", "phone", "01244444444", "password", "short1"), adminToken());
        assertThat(weak.status()).isEqualTo(400);
        assertThat(weak.code()).isEqualTo("WEAK_PASSWORD");
    }

    private static String refreshCookie(Res res) {
        return res.headers().allValues("Set-Cookie").stream()
                .flatMap(h -> HttpCookie.parse(h).stream())
                .filter(c -> c.getName().equals("tayran_admin_rt"))
                .map(HttpCookie::getValue)
                .findFirst().orElseThrow();
    }

    private Res postWithCookie(String path, String refreshToken) throws Exception {
        return send(java.net.http.HttpRequest.newBuilder(java.net.URI.create("http://localhost:" + port + "/api/v1" + path))
                .header("Content-Type", "application/json")
                .header("Cookie", "tayran_admin_rt=" + refreshToken)
                .POST(java.net.http.HttpRequest.BodyPublishers.ofString("{}")));
    }
}
