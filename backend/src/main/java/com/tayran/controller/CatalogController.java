package com.tayran.controller;

import com.tayran.model.ResponsePojo;
import com.tayran.service.impl.LiveCatalog;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * The live catalog, served from memory (no database call unless an admin just edited it). The
 * store comes from the bootstrap's {@code catalog.store}.
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/catalog/stores/{storeId}")
@PreAuthorize("hasAuthority('CUSTOMER')")
public class CatalogController {

    private final LiveCatalog liveCatalog;

    /** The category screen: the category, its subcategories and products, prices as of now. */
    @GetMapping("/categories/{categoryId}")
    public ResponseEntity<ResponsePojo> category(@PathVariable long storeId, @PathVariable long categoryId) {
        return ResponseEntity.ok(ResponsePojo.ok(liveCatalog.category(storeId, categoryId)));
    }

    /** The cart: current price and availability for the products in it (ids=1,2,3; at most 100). */
    @GetMapping("/products")
    public ResponseEntity<ResponsePojo> products(@PathVariable long storeId, @RequestParam List<Long> ids) {
        return ResponseEntity.ok(ResponsePojo.ok(liveCatalog.products(storeId, ids)));
    }
}
