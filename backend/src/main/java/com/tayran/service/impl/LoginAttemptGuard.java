package com.tayran.service.impl;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.tayran.config.properties.AdminProperties;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * In-memory brute-force limits for admin login (one backend instance):
 * <ul>
 *   <li>per IP: at most {@code ipMaxAttempts} attempts per {@code ipWindow};</li>
 *   <li>per unknown phone: locks exactly like a real admin account does, so the lockout
 *       itself never reveals whether a phone belongs to an admin.</li>
 * </ul>
 * Real admin accounts keep their counters in the users table.
 */
@Component
public class LoginAttemptGuard {

    private record Window(Instant start, AtomicInteger count) {
    }

    private record PhoneState(int failures, Instant lockedUntil) {
    }

    private final AdminProperties properties;
    private final Clock clock;
    private final Cache<String, Window> ipWindows;
    private final Cache<String, PhoneState> unknownPhones;

    public LoginAttemptGuard(AdminProperties properties, Clock clock) {
        this.properties = properties;
        this.clock = clock;
        this.ipWindows = Caffeine.newBuilder().maximumSize(100_000).expireAfterWrite(properties.ipWindow()).build();
        this.unknownPhones = Caffeine.newBuilder().maximumSize(100_000)
                .expireAfterAccess(properties.lockDuration().multipliedBy(2)).build();
    }

    /** Counts this attempt for the IP. @throws BusinessException LOGIN_RATE_LIMITED */
    public void hitIp(String ip) {
        Instant now = clock.instant();
        Window window = ipWindows.get(ip, k -> new Window(now, new AtomicInteger()));
        if (window.count().incrementAndGet() > properties.ipMaxAttempts()) {
            long retry = Math.max(1, Duration.between(now, window.start().plus(properties.ipWindow())).toSeconds());
            throw new BusinessException(TayranConst.LOGIN_RATE_LIMITED, Map.of("retryAfterSeconds", retry));
        }
    }

    /** @throws BusinessException ACCOUNT_LOCKED while an unknown phone is "locked". */
    public void checkUnknownPhone(String phone) {
        PhoneState state = unknownPhones.getIfPresent(phone);
        if (state != null && state.lockedUntil() != null && clock.instant().isBefore(state.lockedUntil())) {
            throw locked(state.lockedUntil());
        }
    }

    public void failUnknownPhone(String phone) {
        Instant now = clock.instant();
        unknownPhones.asMap().compute(phone, (k, old) -> {
            int failures = (old == null || (old.lockedUntil() != null && !now.isBefore(old.lockedUntil()))) ? 1 : old.failures() + 1;
            return failures >= properties.maxFailedLogins()
                    ? new PhoneState(0, now.plus(properties.lockDuration()))
                    : new PhoneState(failures, null);
        });
    }

    public BusinessException locked(Instant until) {
        long retry = Math.max(1, Duration.between(clock.instant(), until).toSeconds());
        return new BusinessException(TayranConst.ACCOUNT_LOCKED, Map.of("retryAfterSeconds", retry));
    }
}
