package com.tayran.controller.admin;

import com.tayran.config.security.AuthUser;
import com.tayran.model.ResponsePojo;
import com.tayran.service.impl.CatalogChanges;
import com.tayran.service.impl.StoreSettingsService;
import com.tayran.service.impl.StoreSettingsService.StoreSettingsDto;
import com.tayran.service.impl.StoreSettingsService.UpdateSettingsRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Delivery fee, free-delivery threshold, minimum order, online payment fee, ETA. */
@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/settings")
public class AdminSettingsController {

    private final StoreSettingsService settings;

    @GetMapping
    public ResponseEntity<ResponsePojo> get() {
        return ResponseEntity.ok(ResponsePojo.ok(StoreSettingsDto.of(settings.get(CatalogChanges.DEFAULT_STORE_ID))));
    }

    @PutMapping
    public ResponseEntity<ResponsePojo> update(@AuthenticationPrincipal AuthUser admin, @RequestBody @Valid UpdateSettingsRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(settings.update(CatalogChanges.DEFAULT_STORE_ID, admin.id(), request)));
    }
}
