package com.tayran.controller;

import com.tayran.config.security.AuthUser;
import com.tayran.model.AddAddressRequest;
import com.tayran.model.ResponsePojo;
import com.tayran.model.UpdateNameRequest;
import com.tayran.service.ProfileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/me")
public class MeController {

    private final ProfileService profileService;

    @PutMapping("/name")
    @PreAuthorize("hasAuthority('CUSTOMER')")
    public ResponseEntity<ResponsePojo> updateName(@AuthenticationPrincipal AuthUser user,
                                                   @RequestBody @Valid UpdateNameRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(profileService.updateName(user.id(), request)));
    }

    @PostMapping("/address")
    @PreAuthorize("hasAuthority('CUSTOMER')")
    public ResponseEntity<ResponsePojo> saveAddress(@AuthenticationPrincipal AuthUser user,
                                                    @RequestBody @Valid AddAddressRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(profileService.saveDefaultAddress(user.id(), request)));
    }
}
