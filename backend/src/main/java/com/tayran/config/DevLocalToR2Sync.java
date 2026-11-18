package com.tayran.config;

import com.tayran.config.properties.StorageProperties;
import com.tayran.integration.storage.ObjectStorage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Stream;

/**
 * Dev only, when switching a dev database from local storage to R2 (profiles dev + r2): copies
 * what the local folder holds (image variants, catalog files) into the bucket, so images and
 * catalog versions already referenced by the database don't 404. Copies only what's missing,
 * keeping each file's content type and cache header; safe to run on every start.
 */
@Slf4j
@Order(5)
@Component
@Profile("dev & r2")
@RequiredArgsConstructor
public class DevLocalToR2Sync implements ApplicationRunner {

    private final ObjectStorage storage;
    private final StorageProperties properties;

    @Override
    public void run(ApplicationArguments args) throws IOException {
        String configured = properties.localRoot() == null || properties.localRoot().isBlank() ? ".local-cdn" : properties.localRoot();
        Path root = Path.of(configured).toAbsolutePath().normalize();
        if (!Files.isDirectory(root)) {
            return;
        }
        List<Path> files;
        try (Stream<Path> walk = Files.walk(root)) {
            files = walk.filter(Files::isRegularFile)
                    .filter(f -> !f.getFileName().toString().endsWith(".meta"))
                    .filter(f -> !f.getFileName().toString().endsWith(".tmp"))
                    .toList();
        }
        int copied = 0;
        for (Path file : files) {
            String key = root.relativize(file).toString().replace('\\', '/');
            if (storage.exists(key)) {
                continue;
            }
            String contentType = key.endsWith(".json") ? "application/json" : "image/webp";
            String cacheControl = ObjectStorage.IMMUTABLE;
            Path meta = file.resolveSibling(file.getFileName() + ".meta");
            if (Files.isRegularFile(meta)) {
                String[] lines = Files.readString(meta, StandardCharsets.UTF_8).split("\n", 2);
                if (lines.length == 2) {
                    contentType = lines[0].trim();
                    cacheControl = lines[1].trim();
                }
            }
            storage.put(key, Files.readAllBytes(file), contentType, cacheControl);
            copied++;
        }
        log.info("Dev local storage -> R2: {} of {} files copied ({} already there)", copied, files.size(), files.size() - copied);
    }
}
