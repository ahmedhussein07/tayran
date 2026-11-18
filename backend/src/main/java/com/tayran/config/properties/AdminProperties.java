package com.tayran.config.properties;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import java.time.Duration;
import java.util.List;

/**
 * Admin portal settings. The seed admin comes only from the ADMIN_SEED_PHONE /
 * ADMIN_SEED_PASSWORD environment variables; there are no default credentials anywhere.
 */
@Validated
@ConfigurationProperties(prefix = "admin")
public record AdminProperties(
        String seedPhone,
        String seedPassword,
        List<String> allowedOrigins,
        boolean refreshCookieSecure,
        @Min(1) int maxFailedLogins,
        @NotNull Duration lockDuration,
        @Min(1) int ipMaxAttempts,
        @NotNull Duration ipWindow) {
}
