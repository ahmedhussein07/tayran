package com.tayran;

import com.tayran.integration.otp.OtpSender;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * The whole Phase 1 API flow against a real PostgreSQL (Testcontainers), over real HTTP.
 * Skipped automatically when Docker is not available.
 */
@Testcontainers(disabledWithoutDocker = true)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "security.jwt.secret=integration-test-jwt-secret-0123456789abcdef",
        "otp.hash-secret=integration-test-otp-secret",
        "otp.resend-after=1s",
        "spring.flyway.locations=classpath:db/migration,classpath:db/testdata"
})
class AuthFlowIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:17-alpine");

    @TestConfiguration
    static class CapturingOtpSenderConfig {
        @Bean
        @Primary
        CapturingOtpSender capturingOtpSender() {
            return new CapturingOtpSender();
        }
    }

    static class CapturingOtpSender implements OtpSender {
        final Map<String, String> lastCodeByPhone = new ConcurrentHashMap<>();

        @Override
        public void send(String phone, String code) {
            lastCodeByPhone.put(phone, code);
        }
    }

    private static final String PHONE = "+201012345678";

    @LocalServerPort
    int port;
    @Autowired
    ObjectMapper objectMapper;
    @Autowired
    CapturingOtpSender otpSender;

    private final HttpClient http = HttpClient.newHttpClient();

    @Test
    void newUserSignsUpThenReturningUserGoesStraightHome() throws Exception {
        // 1. Request an OTP (any accepted format is normalized).
        Res otp = post("/auth/otp/request", Map.of("phone", "010 1234 5678"), null);
        assertThat(otp.status).isEqualTo(200);
        String challengeId = otp.content().get("challengeId").asString();
        assertThat(otp.content().get("expiresInSeconds").asInt()).isEqualTo(300);
        String code = otpSender.lastCodeByPhone.get(PHONE);
        assertThat(code).matches("\\d{4}");

        // Asking again inside the resend window is refused and doesn't replace the code.
        Res tooSoon = post("/auth/otp/request", Map.of("phone", "+20 10 1234 5678"), null);
        assertThat(tooSoon.status).isEqualTo(429);
        assertThat(tooSoon.code()).isEqualTo("OTP_RESEND_TOO_SOON");
        assertThat(tooSoon.content().get("retryAfterSeconds").asInt()).isEqualTo(1);

        assertThat(post("/auth/otp/request", Map.of("phone", "01312345678"), null).code()).isEqualTo("INVALID_PHONE");

        // 2. A wrong code is counted.
        Res wrong = post("/auth/otp/verify", Map.of("challengeId", challengeId, "code", code.equals("0000") ? "1111" : "0000"), null);
        assertThat(wrong.status).isEqualTo(400);
        assertThat(wrong.code()).isEqualTo("OTP_INVALID");
        assertThat(wrong.content().get("remainingAttempts").asInt()).isEqualTo(4);

        // 3. The right code signs a new user up: next step is NAME.
        Res verified = post("/auth/otp/verify", Map.of("challengeId", challengeId, "code", code), null);
        assertThat(verified.status).isEqualTo(200);
        assertThat(verified.content().get("nextStep").asString()).isEqualTo("NAME");
        String accessToken = verified.content().get("accessToken").asString();
        String refreshToken = verified.content().get("refreshToken").asString();

        // Protected endpoints need a valid token.
        assertThat(get("/app/bootstrap", null, null).status).isEqualTo(401);
        Res badToken = get("/app/bootstrap", "not-a-jwt", null);
        assertThat(badToken.status).isEqualTo(401);
        assertThat(badToken.code()).isEqualTo("UNAUTHORIZED");

        // 4. Name: trimmed, 2-30 characters each.
        Res badName = put("/me/name", Map.of("firstName", "  أ ", "lastName", "حسين"), accessToken);
        assertThat(badName.code()).isEqualTo("VALIDATION_ERROR");
        assertThat(badName.content().get("fields").get(0).asString()).isEqualTo("firstName");
        Res named = put("/me/name", Map.of("firstName", "  أحمد ", "lastName", "حسين"), accessToken);
        assertThat(named.content().get("nextStep").asString()).isEqualTo("ADDRESS");

        // 5. Locations: one response, cacheable, revalidated with the ETag.
        Res locations = get("/locations", null, null);
        assertThat(locations.status).isEqualTo(200);
        String etag = locations.headers.firstValue("ETag").orElseThrow();
        assertThat(locations.headers.firstValue("Cache-Control").orElseThrow()).contains("max-age=3600").contains("public");
        JsonNode villages = locations.content().get("villages");
        assertThat(villages.size()).isGreaterThanOrEqualTo(4);
        JsonNode village = villages.get(0);
        JsonNode otherVillage = villages.get(1);
        assertThat(village.get("streets").size()).isGreaterThan(0);
        assertThat(get("/locations", null, etag).status).isEqualTo(304);

        // 6. Address: the street must belong to the village.
        long villageId = village.get("id").asLong();
        long foreignStreetId = otherVillage.get("streets").get(0).get("id").asLong();
        Res invalidStreet = post("/me/address",
                Map.of("villageId", villageId, "streetId", foreignStreetId, "landmark", "جنب جامع النور"), accessToken);
        assertThat(invalidStreet.status).isEqualTo(400);
        assertThat(invalidStreet.code()).isEqualTo("INVALID_STREET");
        assertThat(post("/me/address", Map.of("villageId", villageId,
                "streetId", village.get("streets").get(0).get("id").asLong(), "landmark", "قريب"), accessToken).code())
                .isEqualTo("VALIDATION_ERROR");

        long streetId = village.get("streets").get(1).get("id").asLong();
        Res address = post("/me/address",
                Map.of("villageId", villageId, "streetId", streetId, "landmark", " جنب جامع النور، البيت اللي بابه أخضر "), accessToken);
        assertThat(address.status).isEqualTo(200);
        assertThat(address.content().get("nextStep").asString()).isEqualTo("HOME");

        // 7. Bootstrap powers the home screen.
        Res bootstrap = get("/app/bootstrap", accessToken, null);
        assertThat(bootstrap.status).isEqualTo(200);
        JsonNode home = bootstrap.content();
        assertThat(home.get("nextStep").asString()).isEqualTo("HOME");
        assertThat(home.get("firstName").asString()).isEqualTo("أحمد");
        assertThat(home.get("address").get("villageNameAr").asString()).isEqualTo(village.get("nameAr").asString());
        assertThat(home.get("address").get("streetId").asLong()).isEqualTo(streetId);
        assertThat(home.get("address").get("landmark").asString()).isEqualTo("جنب جامع النور، البيت اللي بابه أخضر");
        assertThat(home.get("etaText").asString()).isEqualTo("٢٠ دقيقة");
        JsonNode categories = home.get("categories");
        assertThat(categories.size()).isEqualTo(8);
        assertThat(List.of(categories.get(0).get("nameAr").asString(), categories.get(7).get("nameAr").asString()))
                .containsExactly("خضار وفاكهة", "عناية شخصية");
        assertThat(categories.get(0).get("colorToken").asString()).isEqualTo("pastel-mint");

        // 8. Refresh rotates the token; reusing the old one revokes the whole family.
        Res refreshed = post("/auth/refresh", Map.of("refreshToken", refreshToken), null);
        assertThat(refreshed.status).isEqualTo(200);
        assertThat(refreshed.content().get("nextStep").asString()).isEqualTo("HOME");
        String newRefreshToken = refreshed.content().get("refreshToken").asString();
        assertThat(newRefreshToken).isNotEqualTo(refreshToken);
        assertThat(get("/app/bootstrap", refreshed.content().get("accessToken").asString(), null).status).isEqualTo(200);

        Res reused = post("/auth/refresh", Map.of("refreshToken", refreshToken), null);
        assertThat(reused.status).isEqualTo(401);
        assertThat(reused.code()).isEqualTo("UNAUTHORIZED");
        assertThat(post("/auth/refresh", Map.of("refreshToken", newRefreshToken), null).status).isEqualTo(401);

        // 9. Returning user: request, verify, and go straight home.
        Thread.sleep(1_100); // otp.resend-after is 1s in this test; make sure the window has passed
        String returningChallenge = post("/auth/otp/request", Map.of("phone", "00201012345678"), null)
                .content().get("challengeId").asString();
        Res returning = post("/auth/otp/verify",
                Map.of("challengeId", returningChallenge, "code", otpSender.lastCodeByPhone.get(PHONE)), null);
        assertThat(returning.content().get("nextStep").asString()).isEqualTo("HOME");
    }

    // ---- tiny HTTP helpers -------------------------------------------------------------------

    record Res(int status, java.net.http.HttpHeaders headers, JsonNode body) {
        JsonNode content() {
            return body.get("content");
        }

        String code() {
            return body.get("code").asString();
        }
    }

    private Res post(String path, Object body, String token) throws Exception {
        return send(request(path, token).POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(body))));
    }

    private Res put(String path, Object body, String token) throws Exception {
        return send(request(path, token).PUT(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(body))));
    }

    private Res get(String path, String token, String ifNoneMatch) throws Exception {
        HttpRequest.Builder builder = request(path, token).GET();
        if (ifNoneMatch != null) {
            builder.header("If-None-Match", ifNoneMatch);
        }
        return send(builder);
    }

    private HttpRequest.Builder request(String path, String token) {
        HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create("http://localhost:" + port + "/api/v1" + path))
                .header("Content-Type", "application/json");
        if (token != null) {
            builder.header("Authorization", "Bearer " + token);
        }
        return builder;
    }

    private Res send(HttpRequest.Builder builder) throws Exception {
        HttpResponse<String> response = http.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        JsonNode body = response.body() == null || response.body().isBlank() ? null : objectMapper.readTree(response.body());
        return new Res(response.statusCode(), response.headers(), body);
    }
}
