package com.tayran.controller;

import com.tayran.config.security.AuthUser;
import com.tayran.model.ResponsePojo;
import com.tayran.service.BootstrapService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/app")
public class AppController {

    private final BootstrapService bootstrapService;

    /** One call powers the whole home screen. */
    @GetMapping("/bootstrap")
    @PreAuthorize("hasAuthority('CUSTOMER')")
    public ResponseEntity<ResponsePojo> bootstrap(@AuthenticationPrincipal AuthUser user) {
        return ResponseEntity.ok(ResponsePojo.ok(bootstrapService.bootstrap(user.id())));
    }
}
