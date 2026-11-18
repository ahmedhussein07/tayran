package com.tayran.controller.admin;

import com.tayran.model.ResponsePojo;
import com.tayran.model.admin.CatalogDtos.ActiveRequest;
import com.tayran.model.admin.CatalogDtos.CategoryRequest;
import com.tayran.model.admin.CatalogDtos.ReorderRequest;
import com.tayran.model.admin.CatalogDtos.SubcategoryRequest;
import com.tayran.service.AdminCatalogService;
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
import org.springframework.web.bind.annotation.RestController;

/** Categories and, nested under them, subcategories. */
@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/categories")
public class AdminCategoryController {

    private final AdminCatalogService catalog;

    @GetMapping
    public ResponseEntity<ResponsePojo> list() {
        return ResponseEntity.ok(ResponsePojo.ok(catalog.listCategories()));
    }

    @PostMapping
    public ResponseEntity<ResponsePojo> create(@RequestBody @Valid CategoryRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(catalog.createCategory(request)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ResponsePojo> update(@PathVariable long id, @RequestBody @Valid CategoryRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(catalog.updateCategory(id, request)));
    }

    @PutMapping("/{id}/active")
    public ResponseEntity<ResponsePojo> setActive(@PathVariable long id, @RequestBody @Valid ActiveRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(catalog.setCategoryActive(id, request.active())));
    }

    @PutMapping("/order")
    public ResponseEntity<ResponsePojo> reorder(@RequestBody @Valid ReorderRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(catalog.reorderCategories(request.ids())));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponsePojo> delete(@PathVariable long id) {
        catalog.deleteCategory(id);
        return ResponseEntity.ok(ResponsePojo.ok(null));
    }

    @GetMapping("/{categoryId}/subcategories")
    public ResponseEntity<ResponsePojo> listSubcategories(@PathVariable long categoryId) {
        return ResponseEntity.ok(ResponsePojo.ok(catalog.listSubcategories(categoryId)));
    }

    @PostMapping("/{categoryId}/subcategories")
    public ResponseEntity<ResponsePojo> createSubcategory(@PathVariable long categoryId, @RequestBody @Valid SubcategoryRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(catalog.createSubcategory(categoryId, request)));
    }

    @PutMapping("/{categoryId}/subcategories/{id}")
    public ResponseEntity<ResponsePojo> updateSubcategory(@PathVariable long categoryId, @PathVariable long id,
                                                          @RequestBody @Valid SubcategoryRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(catalog.updateSubcategory(categoryId, id, request)));
    }

    @PutMapping("/{categoryId}/subcategories/{id}/active")
    public ResponseEntity<ResponsePojo> setSubcategoryActive(@PathVariable long categoryId, @PathVariable long id,
                                                             @RequestBody @Valid ActiveRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(catalog.setSubcategoryActive(categoryId, id, request.active())));
    }

    @PutMapping("/{categoryId}/subcategories/order")
    public ResponseEntity<ResponsePojo> reorderSubcategories(@PathVariable long categoryId, @RequestBody @Valid ReorderRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(catalog.reorderSubcategories(categoryId, request.ids())));
    }

    @DeleteMapping("/{categoryId}/subcategories/{id}")
    public ResponseEntity<ResponsePojo> deleteSubcategory(@PathVariable long categoryId, @PathVariable long id) {
        catalog.deleteSubcategory(categoryId, id);
        return ResponseEntity.ok(ResponsePojo.ok(null));
    }
}
