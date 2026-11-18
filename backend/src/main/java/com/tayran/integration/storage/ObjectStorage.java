package com.tayran.integration.storage;

/**
 * Public object storage behind the CDN (CDN_BASE_URL). Keys are paths such as
 * {@code p/3fa91c0be27d_320.webp} or {@code catalog/store-1/v12.json}.
 */
public interface ObjectStorage {

    /** Cache-Control for content-addressed files that never change. */
    String IMMUTABLE = "public, max-age=31536000, immutable";

    void put(String key, byte[] bytes, String contentType, String cacheControl);

    boolean exists(String key);

    void delete(String key);
}
