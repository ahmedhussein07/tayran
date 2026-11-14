package com.tayran.controller;

import com.tayran.model.OtpRequest;
import com.tayran.model.OtpVerifyRequest;
import com.tayran.model.RefreshRequest;
import com.tayran.model.ResponsePojo;
import com.tayran.model.TayranConst;
import com.tayran.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/otp/request")
    public ResponseEntity<ResponsePojo> requestOtp(@RequestBody OtpRequest request) {
        return ResponseEntity.ok(new ResponsePojo(true, TayranConst.OTP_HAS_BEEN_SENT, TayranConst.OTP_HAS_BEEN_SENT_AR,
                authService.requestOtp(request.getPhone())));
    }

    @PostMapping("/otp/verify")
    public ResponseEntity<ResponsePojo> verifyOtp(@RequestBody @Valid OtpVerifyRequest request) {
        return ResponseEntity.ok(new ResponsePojo(true, TayranConst.LOGIN_SUCCESSFULLY, TayranConst.LOGIN_SUCCESSFULLY_AR,
                authService.verifyOtp(request.getChallengeId(), request.getCode())));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ResponsePojo> refresh(@RequestBody @Valid RefreshRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(authService.refresh(request.getRefreshToken())));
    }
}
