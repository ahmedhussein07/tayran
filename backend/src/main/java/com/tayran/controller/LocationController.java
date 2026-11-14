package com.tayran.controller;

import com.tayran.config.properties.AppProperties;
import com.tayran.model.ResponsePojo;
import com.tayran.service.LocationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;

@RestController
@RequiredArgsConstructor
@RequestMapping("/locations")
public class LocationController {

    private final LocationService locationService;
    private final AppProperties appProperties;

    /** All active villages with their streets. Answers 304 when the app's copy is still current. */
    @GetMapping
    public ResponseEntity<ResponsePojo> getLocations(
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        LocationService.Snapshot snapshot = locationService.getLocations();
        CacheControl cacheControl = CacheControl.maxAge(appProperties.locationsCacheTtl()).cachePublic();
        if (matches(ifNoneMatch, snapshot.etag())) {
            return ResponseEntity.status(HttpStatus.NOT_MODIFIED).eTag(snapshot.etag()).cacheControl(cacheControl).build();
        }
        return ResponseEntity.ok().eTag(snapshot.etag()).cacheControl(cacheControl).body(ResponsePojo.ok(snapshot.body()));
    }

    private static boolean matches(String ifNoneMatch, String etag) {
        if (ifNoneMatch == null || ifNoneMatch.isBlank()) {
            return false;
        }
        return Arrays.stream(ifNoneMatch.split(","))
                .map(String::trim)
                .map(tag -> tag.startsWith("W/") ? tag.substring(2) : tag)
                .anyMatch(tag -> tag.equals("*") || tag.equals(etag));
    }
}
