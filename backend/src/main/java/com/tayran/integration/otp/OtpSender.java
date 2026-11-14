package com.tayran.integration.otp;

/** Delivers an OTP to a phone. Swap the implementation for a real SMS provider later. */
public interface OtpSender {

    /**
     * @param phone E.164 number, +201XXXXXXXXX
     * @param code  the plain code; it exists only in memory and in the message
     */
    void send(String phone, String code);
}
