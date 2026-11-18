package com.tayran.config.properties;

import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Object storage settings.
 *
 * @param cdnBaseUrl public base URL for reads (CDN_BASE_URL), without a trailing slash
 * @param localRoot  folder used by LocalFileStorage (dev and tests)
 */
@Validated
@ConfigurationProperties(prefix = "storage")
public record StorageProperties(@NotBlank String cdnBaseUrl, String localRoot) {

    public String url(String key) {
        String base = cdnBaseUrl.endsWith("/") ? cdnBaseUrl.substring(0, cdnBaseUrl.length() - 1) : cdnBaseUrl;
        return base + "/" + key;
    }
}
