package com.tayran.controller.admin;

import com.tayran.model.ResponsePojo;
import com.tayran.model.admin.CatalogDtos.ProductFilter;
import com.tayran.model.admin.CatalogDtos.ProductRequest;
import com.tayran.service.AdminProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/products")
public class AdminProductController {

    private final AdminProductService products;

    @GetMapping
    public ResponseEntity<ResponsePojo> list(@RequestParam(required = false) String q,
                                             @RequestParam(required = false) Long categoryId,
                                             @RequestParam(required = false) Long subcategoryId,
                                             @RequestParam(required = false) Boolean active,
                                             @RequestParam(required = false) Boolean available,
                                             @RequestParam(defaultValue = "0") int page,
                                             @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ResponsePojo.ok(products.list(new ProductFilter(q, categoryId, subcategoryId, active, available, page, size))));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponsePojo> get(@PathVariable long id) {
        return ResponseEntity.ok(ResponsePojo.ok(products.get(id)));
    }

    @PostMapping
    public ResponseEntity<ResponsePojo> create(@RequestBody @Valid ProductRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(products.create(request)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ResponsePojo> update(@PathVariable long id, @RequestBody @Valid ProductRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(products.update(id, request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponsePojo> delete(@PathVariable long id) {
        products.delete(id);
        return ResponseEntity.ok(ResponsePojo.ok(null));
    }
}
