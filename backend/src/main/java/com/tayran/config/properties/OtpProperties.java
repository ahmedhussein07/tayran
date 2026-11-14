package com.tayran.config.properties;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import java.time.Duration;

@Validated
@ConfigurationProperties(prefix = "otp")
public record OtpProperties(
        @NotBlank String hashSecret,
        @Min(4) int length,
        @NotNull Duration ttl,
        @NotNull Duration resendAfter,
        @Min(1) int maxAttempts,
        @Min(1) int maxRequestsPerWindow,
        @NotNull Duration requestWindow,
        boolean logCode) {
}
