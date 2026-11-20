package com.tayran.controller;

import com.tayran.config.security.AuthUser;
import com.tayran.model.AddAddressRequest;
import com.tayran.model.ProfileDtos.DeviceRequest;
import com.tayran.model.ProfileDtos.PreferencesRequest;
import com.tayran.model.ResponsePojo;
import com.tayran.model.UpdateNameRequest;
import com.tayran.service.ProfileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** The customer's own profile: name, addresses, language, push devices. The phone is never editable. */
@RestController
@RequiredArgsConstructor
@RequestMapping("/me")
@PreAuthorize("hasAuthority('CUSTOMER')")
public class MeController {

    private final ProfileService profileService;

    @PutMapping("/name")
    public ResponseEntity<ResponsePojo> updateName(@AuthenticationPrincipal AuthUser user,
                                                   @RequestBody @Valid UpdateNameRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(profileService.updateName(user.id(), request)));
    }

    /** Onboarding: saves (or replaces) the default address. */
    @PostMapping("/address")
    public ResponseEntity<ResponsePojo> saveAddress(@AuthenticationPrincipal AuthUser user,
                                                    @RequestBody @Valid AddAddressRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(profileService.saveDefaultAddress(user.id(), request)));
    }

    // ---- saved addresses ---------------------------------------------------------------------

    @GetMapping("/addresses")
    public ResponseEntity<ResponsePojo> addresses(@AuthenticationPrincipal AuthUser user) {
        return ResponseEntity.ok(ResponsePojo.ok(profileService.addresses(user.id())));
    }

    @PostMapping("/addresses")
    public ResponseEntity<ResponsePojo> addAddress(@AuthenticationPrincipal AuthUser user, @RequestBody @Valid AddAddressRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(profileService.addAddress(user.id(), request)));
    }

    @PutMapping("/addresses/{id}")
    public ResponseEntity<ResponsePojo> updateAddress(@AuthenticationPrincipal AuthUser user, @PathVariable long id,
                                                      @RequestBody @Valid AddAddressRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(profileService.updateAddress(user.id(), id, request)));
    }

    @DeleteMapping("/addresses/{id}")
    public ResponseEntity<ResponsePojo> deleteAddress(@AuthenticationPrincipal AuthUser user, @PathVariable long id) {
        profileService.deleteAddress(user.id(), id);
        return ResponseEntity.ok(ResponsePojo.ok(profileService.addresses(user.id())));
    }

    @PutMapping("/addresses/{id}/default")
    public ResponseEntity<ResponsePojo> setDefault(@AuthenticationPrincipal AuthUser user, @PathVariable long id) {
        profileService.setDefaultAddress(user.id(), id);
        return ResponseEntity.ok(ResponsePojo.ok(profileService.addresses(user.id())));
    }

    // ---- preferences and devices -------------------------------------------------------------

    @PutMapping("/preferences")
    public ResponseEntity<ResponsePojo> preferences(@AuthenticationPrincipal AuthUser user, @RequestBody @Valid PreferencesRequest request) {
        profileService.updateLanguage(user.id(), request.language());
        return ResponseEntity.ok(ResponsePojo.ok(null));
    }

    /** Called on login and when the FCM token refreshes. */
    @PostMapping("/devices")
    public ResponseEntity<ResponsePojo> registerDevice(@AuthenticationPrincipal AuthUser user, @RequestBody @Valid DeviceRequest request) {
        profileService.registerDevice(user.id(), request.fcmToken(), request.platform());
        return ResponseEntity.ok(ResponsePojo.ok(null));
    }

    /** Called on logout. */
    @DeleteMapping("/devices/{token}")
    public ResponseEntity<ResponsePojo> unregisterDevice(@AuthenticationPrincipal AuthUser user, @PathVariable String token) {
        profileService.unregisterDevice(user.id(), token);
        return ResponseEntity.ok(ResponsePojo.ok(null));
    }
}
