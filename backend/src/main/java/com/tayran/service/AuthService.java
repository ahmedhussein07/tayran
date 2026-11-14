package com.tayran.service;

import com.tayran.model.AuthResponse;
import com.tayran.model.OtpChallengeResponse;

import java.util.UUID;

public interface AuthService {

    OtpChallengeResponse requestOtp(String phone);

    /** Sign-in and sign-up are the same: a verified phone with no account gets one. */
    AuthResponse verifyOtp(UUID challengeId, String code);

    AuthResponse refresh(String refreshToken);
}
