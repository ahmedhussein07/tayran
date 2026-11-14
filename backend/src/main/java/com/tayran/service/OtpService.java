package com.tayran.service;

import com.tayran.model.OtpChallengeResponse;

import java.util.UUID;

public interface OtpService {

    /** Normalizes the phone, applies the resend window and hourly limit, and sends a new code. */
    OtpChallengeResponse requestOtp(String rawPhone);

    /**
     * Checks the code and consumes the challenge.
     *
     * @return the verified phone in E.164
     */
    String verifyOtp(UUID challengeId, String code);
}
