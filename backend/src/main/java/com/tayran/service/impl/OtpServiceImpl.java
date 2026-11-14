package com.tayran.service.impl;

import com.tayran.config.properties.OtpProperties;
import com.tayran.dao.entity.OtpChallenge;
import com.tayran.dao.repository.OtpChallengeRepository;
import com.tayran.exception.BusinessException;
import com.tayran.integration.otp.OtpSender;
import com.tayran.model.OtpChallengeResponse;
import com.tayran.model.TayranConst;
import com.tayran.service.OtpService;
import com.tayran.utils.HashUtils;
import com.tayran.utils.PhoneUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OtpServiceImpl implements OtpService {

    private final OtpChallengeRepository otpChallengeRepository;
    private final OtpSender otpSender;
    private final OtpProperties otpProperties;
    private final Clock clock;

    @Override
    @Transactional
    public OtpChallengeResponse requestOtp(String rawPhone) {
        String phone = PhoneUtils.normalize(rawPhone);
        otpChallengeRepository.lockPhone(phone);
        Instant now = clock.instant();

        Optional<OtpChallenge> latest = otpChallengeRepository.findFirstByPhoneOrderByCreatedOnDesc(phone);
        if (latest.isPresent() && now.isBefore(latest.get().getResendAvailableAt())) {
            throw new BusinessException(TayranConst.OTP_RESEND_TOO_SOON,
                    Map.of("retryAfterSeconds", secondsUntil(now, latest.get().getResendAvailableAt())));
        }

        Instant windowStart = now.minus(otpProperties.requestWindow());
        if (otpChallengeRepository.countByPhoneAndCreatedOnAfter(phone, windowStart) >= otpProperties.maxRequestsPerWindow()) {
            Instant retryAt = otpChallengeRepository.findFirstByPhoneAndCreatedOnAfterOrderByCreatedOnAsc(phone, windowStart)
                    .map(oldest -> oldest.getCreatedOn().plus(otpProperties.requestWindow()))
                    .orElse(now.plus(otpProperties.requestWindow()));
            throw new BusinessException(TayranConst.OTP_RATE_LIMITED, Map.of("retryAfterSeconds", secondsUntil(now, retryAt)));
        }

        // Only the newest code for a phone can be used.
        otpChallengeRepository.supersedeOpenChallenges(phone, now);

        String code = HashUtils.randomDigits(otpProperties.length());
        UUID challengeId = UUID.randomUUID();
        otpChallengeRepository.save(OtpChallenge.builder()
                .id(challengeId)
                .phone(phone)
                .codeHash(hash(challengeId, code))
                .attempts(0)
                .expiresAt(now.plus(otpProperties.ttl()))
                .resendAvailableAt(now.plus(otpProperties.resendAfter()))
                .createdOn(now)
                .build());

        otpSender.send(phone, code);
        return new OtpChallengeResponse(challengeId, otpProperties.ttl().toSeconds(), otpProperties.resendAfter().toSeconds());
    }

    /** A wrong guess must stay counted, so business errors don't roll the transaction back. */
    @Override
    @Transactional(noRollbackFor = BusinessException.class)
    public String verifyOtp(UUID challengeId, String code) {
        OtpChallenge challenge = otpChallengeRepository.findByIdForUpdate(challengeId)
                .orElseThrow(() -> new BusinessException(TayranConst.OTP_EXPIRED));
        Instant now = clock.instant();

        if (challenge.isClosed() || !now.isBefore(challenge.getExpiresAt())) {
            throw new BusinessException(TayranConst.OTP_EXPIRED);
        }
        if (challenge.getAttempts() >= otpProperties.maxAttempts()) {
            throw new BusinessException(TayranConst.OTP_TOO_MANY_ATTEMPTS);
        }
        if (code == null || !HashUtils.constantTimeEquals(hash(challengeId, code), challenge.getCodeHash())) {
            challenge.setAttempts(challenge.getAttempts() + 1);
            otpChallengeRepository.save(challenge);
            int remaining = otpProperties.maxAttempts() - challenge.getAttempts();
            if (remaining <= 0) {
                throw new BusinessException(TayranConst.OTP_TOO_MANY_ATTEMPTS);
            }
            throw new BusinessException(TayranConst.OTP_INVALID, Map.of("remainingAttempts", remaining));
        }

        challenge.setConsumedAt(now);
        otpChallengeRepository.save(challenge);
        return challenge.getPhone();
    }

    private String hash(UUID challengeId, String code) {
        return HashUtils.hmacSha256Hex(otpProperties.hashSecret(), challengeId + ":" + code);
    }

    private static long secondsUntil(Instant now, Instant target) {
        long millis = Duration.between(now, target).toMillis();
        return Math.max(1, (millis + 999) / 1000);
    }
}
