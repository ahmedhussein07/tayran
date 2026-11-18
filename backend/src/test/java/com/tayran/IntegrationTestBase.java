package com.tayran;

import com.tayran.integration.otp.OtpSender;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpHeaders;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Shared by every integration test: one PostgreSQL container and one Spring context for the whole
 * suite, real HTTP, a captured OTP sender, and a seed admin from TEST-ONLY properties.
 * Skipped automatically when Docker is not available.
 */
@Testcontainers(disabledWithoutDocker = true)
@Import(IntegrationTestBase.TestBeans.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "security.jwt.secret=integration-test-jwt-secret-0123456789abcdef",
        "otp.hash-secret=integration-test-otp-secret",
        "otp.resend-after=1s",
        "spring.flyway.locations=classpath:db/migration,classpath:db/testdata",
        "storage.cdn-base-url=" + IntegrationTestBase.CDN,
        "admin.seed-phone=" + IntegrationTestBase.ADMIN_PHONE,
        "admin.seed-password=" + IntegrationTestBase.ADMIN_PASSWORD,
        "admin.ip-max-attempts=100000",
        // The publisher is driven by the tests, not by the schedule.
        "app.catalog-publish-interval=1h"
})
public abstract class IntegrationTestBase {

    static final String CDN = "http://cdn.test/cdn";
    static final String ADMIN_PHONE = "01055555555";
    static final String ADMIN_PASSWORD = "IntegrationTest1234";

    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:17-alpine");

    static final Path CDN_DIR;

    static {
        if (DockerClientFactory.instance().isDockerAvailable()) {
            POSTGRES.start();
        }
        try {
            CDN_DIR = Files.createTempDirectory("tayran-test-cdn");
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    @DynamicPropertySource
    static void storage(DynamicPropertyRegistry registry) {
        registry.add("storage.local-root", CDN_DIR::toString);
    }

    @TestConfiguration
    static class TestBeans {
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

    @LocalServerPort
    int port;
    @Autowired
    ObjectMapper objectMapper;
    @Autowired
    CapturingOtpSender otpSender;

    final HttpClient http = HttpClient.newHttpClient();

    // ---- sign-in helpers -------------------------------------------------------------------

    /** Signs a customer in with OTP and returns the access token. */
    String customerToken(String localPhone) throws Exception {
        String e164 = "+2" + localPhone;
        Res otp = post("/auth/otp/request", Map.of("phone", localPhone), null);
        String challenge = otp.content().get("challengeId").asString();
        return post("/auth/otp/verify", Map.of("challengeId", challenge, "code", otpSender.lastCodeByPhone.get(e164)), null)
                .content().get("accessToken").asString();
    }

    String adminToken() throws Exception {
        return post("/admin/auth/login", Map.of("phone", ADMIN_PHONE, "password", ADMIN_PASSWORD), null)
                .content().get("accessToken").asString();
    }

    /** Reads a published object (catalog JSON) straight from the test CDN folder. */
    JsonNode readCdnJson(String url) throws IOException {
        String key = url.substring(CDN.length() + 1);
        return objectMapper.readTree(Files.readString(CDN_DIR.resolve(key)));
    }

    // ---- tiny HTTP helpers -----------------------------------------------------------------

    record Res(int status, HttpHeaders headers, JsonNode body) {
        JsonNode content() {
            return body.get("content");
        }

        String code() {
            return body.get("code").asString();
        }
    }

    Res post(String path, Object body, String token) throws Exception {
        return send(request(path, token).POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(body))));
    }

    Res put(String path, Object body, String token) throws Exception {
        return send(request(path, token).PUT(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(body))));
    }

    Res delete(String path, String token) throws Exception {
        return send(request(path, token).DELETE());
    }

    Res get(String path, String token, String ifNoneMatch) throws Exception {
        HttpRequest.Builder builder = request(path, token).GET();
        if (ifNoneMatch != null) {
            builder.header("If-None-Match", ifNoneMatch);
        }
        return send(builder);
    }

    /** multipart/form-data upload of one file field named "file". */
    Res upload(String path, byte[] file, String filename, String contentType, String token) throws Exception {
        String boundary = "----tayran" + UUID.randomUUID();
        byte[] head = ("--" + boundary + "\r\nContent-Disposition: form-data; name=\"file\"; filename=\"" + filename
                + "\"\r\nContent-Type: " + contentType + "\r\n\r\n").getBytes();
        byte[] tail = ("\r\n--" + boundary + "--\r\n").getBytes();
        byte[] bodyBytes = new byte[head.length + file.length + tail.length];
        System.arraycopy(head, 0, bodyBytes, 0, head.length);
        System.arraycopy(file, 0, bodyBytes, head.length, file.length);
        System.arraycopy(tail, 0, bodyBytes, head.length + file.length, tail.length);
        HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create("http://localhost:" + port + "/api/v1" + path))
                .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                .header("Authorization", "Bearer " + token)
                .POST(HttpRequest.BodyPublishers.ofByteArray(bodyBytes));
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

    Res send(HttpRequest.Builder builder) throws Exception {
        HttpResponse<String> response = http.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        JsonNode body = response.body() == null || response.body().isBlank() ? null : objectMapper.readTree(response.body());
        return new Res(response.statusCode(), response.headers(), body);
    }
}
