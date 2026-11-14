package com.tayran.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;

@Configuration
public class AppConfig {

    /** All time-based rules (OTP expiry, resend window, token TTLs) read this clock, so tests can move time. */
    @Bean
    public Clock clock() {
        return Clock.systemUTC();
    }
}
