package com.tayran.integration.storage;

import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** Serves LocalFileStorage at /cdn/** in dev, with the headers the files were stored with. */
@RestController
@Profile("!r2")
@RequiredArgsConstructor
public class CdnController {

    private static final String PREFIX = "/cdn/";

    private final LocalFileStorage storage;

    @GetMapping("/cdn/**")
    public ResponseEntity<Resource> get(HttpServletRequest request) {
        String path = request.getRequestURI().substring(request.getContextPath().length());
        String key = path.startsWith(PREFIX) ? path.substring(PREFIX.length()) : "";
        return storage.read(key)
                .map(object -> ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(object.contentType()))
                        .header(HttpHeaders.CACHE_CONTROL, object.cacheControl())
                        .<Resource>body(new FileSystemResource(object.file())))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
