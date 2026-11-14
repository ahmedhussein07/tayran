package com.tayran.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OtpChallengeResponse {
    private UUID challengeId;
    private long expiresInSeconds;
    private long resendAfterSeconds;
}
