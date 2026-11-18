package com.tayran.integration.storage;

import com.tayran.config.properties.StorageProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Optional;

/**
 * Stores objects in a local folder (every profile except r2). {@link CdnController} serves them at
 * /cdn/** with the Content-Type and Cache-Control they were written with, like production.
 * Each object gets a small sidecar file {@code <key>.meta} holding those two headers.
 */
@Slf4j
@Component
@Profile("!r2")
public class LocalFileStorage implements ObjectStorage {

    public record StoredObject(Path file, String contentType, String cacheControl) {
    }

    private final Path root;

    public LocalFileStorage(StorageProperties properties) {
        String configured = properties.localRoot() == null || properties.localRoot().isBlank() ? ".local-cdn" : properties.localRoot();
        this.root = Path.of(configured).toAbsolutePath().normalize();
        log.info("Local object storage at {}", root);
    }

    @Override
    public void put(String key, byte[] bytes, String contentType, String cacheControl) {
        Path file = resolve(key);
        try {
            Files.createDirectories(file.getParent());
            Path tmp = Files.createTempFile(file.getParent(), ".upload", ".tmp");
            Files.write(tmp, bytes);
            Files.move(tmp, file, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
            Files.writeString(meta(file), contentType + "\n" + cacheControl, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException("Could not store " + key, e);
        }
    }

    @Override
    public boolean exists(String key) {
        return Files.isRegularFile(resolve(key));
    }

    @Override
    public void delete(String key) {
        Path file = resolve(key);
        try {
            Files.deleteIfExists(file);
            Files.deleteIfExists(meta(file));
        } catch (IOException e) {
            throw new UncheckedIOException("Could not delete " + key, e);
        }
    }

    /** For CdnController: the file and its headers, if it exists. */
    public Optional<StoredObject> read(String key) {
        Path file;
        try {
            file = resolve(key);
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
        if (!Files.isRegularFile(file)) {
            return Optional.empty();
        }
        String contentType = "application/octet-stream";
        String cacheControl = "no-cache";
        try {
            String[] lines = Files.readString(meta(file), StandardCharsets.UTF_8).split("\n", 2);
            contentType = lines[0];
            cacheControl = lines.length > 1 ? lines[1] : cacheControl;
        } catch (IOException ignored) {
            // no sidecar: serve with safe defaults
        }
        return Optional.of(new StoredObject(file, contentType, cacheControl));
    }

    private Path resolve(String key) {
        Path file = root.resolve(key).normalize();
        if (!file.startsWith(root) || key.endsWith(".meta")) {
            throw new IllegalArgumentException("Invalid key");
        }
        return file;
    }

    private static Path meta(Path file) {
        return file.resolveSibling(file.getFileName() + ".meta");
    }
}
