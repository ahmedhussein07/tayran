package com.tayran.integration.storage;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class R2StorageTest {

    @Test
    void defaultsToTheAccountEndpoint() {
        assertThat(R2Storage.endpoint(null, "abc123")).isEqualTo("https://abc123.r2.cloudflarestorage.com");
        assertThat(R2Storage.endpoint("  ", "abc123")).isEqualTo("https://abc123.r2.cloudflarestorage.com");
    }

    @Test
    void dropsABucketPathCopiedFromTheDashboard() {
        // The dashboard shows ".../<bucket>"; the client adds the bucket itself.
        assertThat(R2Storage.endpoint("https://abc123.r2.cloudflarestorage.com/tayran-media", "abc123"))
                .isEqualTo("https://abc123.r2.cloudflarestorage.com");
        assertThat(R2Storage.endpoint("https://abc123.r2.cloudflarestorage.com/", "abc123"))
                .isEqualTo("https://abc123.r2.cloudflarestorage.com");
        assertThat(R2Storage.endpoint(" https://abc123.eu.r2.cloudflarestorage.com ", "abc123"))
                .isEqualTo("https://abc123.eu.r2.cloudflarestorage.com");
    }

    @Test
    void keepsAnExplicitPortForLocalS3Stand_ins() {
        assertThat(R2Storage.endpoint("http://localhost:9000/bucket", "x")).isEqualTo("http://localhost:9000");
    }

    @Test
    void rejectsSomethingThatIsNotAUrl() {
        assertThatThrownBy(() -> R2Storage.endpoint("abc123.r2.cloudflarestorage.com", "abc123"))
                .isInstanceOf(IllegalStateException.class);
    }
}
