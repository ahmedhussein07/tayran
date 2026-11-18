package com.tayran.controller.admin;

import com.tayran.config.properties.AdminProperties;
import com.tayran.config.properties.JwtProperties;
import com.tayran.config.security.AuthUser;
import com.tayran.config.security.JwtUtil;
import com.tayran.model.ResponsePojo;
import com.tayran.model.TokenPair;
import com.tayran.model.admin.AdminDtos.ChangePasswordRequest;
import com.tayran.model.admin.AdminDtos.LoginRequest;
import com.tayran.model.admin.AdminDtos.LoginResponse;
import com.tayran.service.AdminAuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;

/**
 * Admin sign-in. The refresh token lives only in an httpOnly, SameSite=Strict cookie scoped to
 * this path, so page scripts in the portal can never read it; the access token is returned in the body.
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/admin")
public class AdminAuthController {

    static final String REFRESH_COOKIE = "tayran_admin_rt";
    private static final String COOKIE_PATH = "/api/v1/admin/auth";

    private final AdminAuthService adminAuthService;
    private final AdminProperties adminProperties;
    private final JwtProperties jwtProperties;
    private final JwtUtil jwtUtil;

    @PostMapping("/auth/login")
    public ResponseEntity<ResponsePojo> login(@RequestBody LoginRequest request, HttpServletRequest http) {
        return withTokens(adminAuthService.login(request.phone(), request.password(), http.getRemoteAddr()));
    }

    @PostMapping("/auth/refresh")
    public ResponseEntity<ResponsePojo> refresh(@CookieValue(name = REFRESH_COOKIE, required = false) String refreshToken) {
        return withTokens(adminAuthService.refresh(refreshToken));
    }

    @PostMapping("/auth/logout")
    public ResponseEntity<ResponsePojo> logout(@CookieValue(name = REFRESH_COOKIE, required = false) String refreshToken) {
        adminAuthService.logout(refreshToken);
        return ResponseEntity.ok().header(HttpHeaders.SET_COOKIE, cookie("", Duration.ZERO).toString()).body(ResponsePojo.ok(null));
    }

    @GetMapping("/me")
    public ResponseEntity<ResponsePojo> me(@AuthenticationPrincipal AuthUser admin) {
        return ResponseEntity.ok(ResponsePojo.ok(adminAuthService.me(admin.id())));
    }

    @PutMapping("/me/password")
    public ResponseEntity<ResponsePojo> changePassword(@AuthenticationPrincipal AuthUser admin,
                                                       @RequestBody @Valid ChangePasswordRequest request) {
        adminAuthService.changePassword(admin.id(), request.currentPassword(), request.newPassword());
        return ResponseEntity.ok(ResponsePojo.ok(null));
    }

    private ResponseEntity<ResponsePojo> withTokens(TokenPair pair) {
        LoginResponse body = new LoginResponse(pair.accessToken(), jwtUtil.accessTokenTtlSeconds(), adminAuthService.me(pair.userId()));
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, cookie(pair.refreshToken(), jwtProperties.refreshTokenTtl()).toString())
                .body(ResponsePojo.ok(body));
    }

    private ResponseCookie cookie(String value, Duration maxAge) {
        return ResponseCookie.from(REFRESH_COOKIE, value)
                .httpOnly(true)
                .secure(adminProperties.refreshCookieSecure())
                .sameSite("Strict")
                .path(COOKIE_PATH)
                .maxAge(maxAge)
                .build();
    }
}
