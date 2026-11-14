package com.tayran.integration.otp;

import com.tayran.config.properties.OtpProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * No real SMS yet: writes to the log. The code itself is printed only when otp.log-code=true
 * (the dev profile), so it never reaches production logs.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LoggingOtpSender implements OtpSender {

    private final OtpProperties otpProperties;

    @Override
    public void send(String phone, String code) {
        if (otpProperties.logCode()) {
            log.info("[DEV OTP] phone={} code={}", phone, code);
        } else {
            log.info("OTP sent to {}", mask(phone));
        }
    }

    private static String mask(String phone) {
        return phone.length() <= 4 ? "****" : "*".repeat(phone.length() - 4) + phone.substring(phone.length() - 4);
    }
}
