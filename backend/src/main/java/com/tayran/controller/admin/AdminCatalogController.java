package com.tayran.controller.admin;

import com.tayran.model.ResponsePojo;
import com.tayran.service.impl.CatalogChanges;
import com.tayran.service.impl.CatalogPublisher;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The published catalog as the admin sees it: which version the app is on, whether edits are
 * waiting for the next scheduled run, and "publish now" for when they shouldn't wait.
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/catalog")
public class AdminCatalogController {

    private final CatalogPublisher publisher;

    @GetMapping("/status")
    public ResponseEntity<ResponsePojo> status() {
        return ResponseEntity.ok(ResponsePojo.ok(publisher.status(CatalogChanges.DEFAULT_STORE_ID)));
    }

    /** Publishes pending edits right away (no-op when nothing changed) and returns the new status. */
    @PostMapping("/publish")
    public ResponseEntity<ResponsePojo> publish() {
        publisher.publish(CatalogChanges.DEFAULT_STORE_ID);
        return ResponseEntity.ok(ResponsePojo.ok(publisher.status(CatalogChanges.DEFAULT_STORE_ID)));
    }
}
