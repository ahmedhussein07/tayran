package com.tayran.service.impl;

import com.tayran.config.properties.JwtProperties;
import com.tayran.config.security.JwtUtil;
import com.tayran.dao.entity.RefreshToken;
import com.tayran.dao.entity.User;
import com.tayran.dao.repository.RefreshTokenRepository;
import com.tayran.dao.repository.UserRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import com.tayran.model.TokenPair;
import com.tayran.model.UserRole;
import com.tayran.service.TokenService;
import com.tayran.utils.HashUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class TokenServiceImpl implements TokenService {

    private static final int REFRESH_TOKEN_BYTES = 32;

    private final RefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final JwtProperties jwtProperties;
    private final Clock clock;

    @Override
    @Transactional
    public TokenPair issue(User user) {
        String raw = HashUtils.randomToken(REFRESH_TOKEN_BYTES);
        save(user.getId(), raw, UUID.randomUUID(), clock.instant());
        return new TokenPair(user.getId(), user.getRole(), jwtUtil.generateAccessToken(user.getId(), user.getRole()), raw);
    }

    /** Revoking a reused token's family must stick, so business errors don't roll back. */
    @Override
    @Transactional(noRollbackFor = BusinessException.class)
    public TokenPair rotate(String refreshToken, UserRole expectedRole) {
        RefreshToken current = refreshTokenRepository.findByTokenHashForUpdate(HashUtils.sha256Hex(refreshToken))
                .orElseThrow(() -> new BusinessException(TayranConst.UNAUTHORIZED));
        Instant now = clock.instant();

        if (current.getRevokedAt() != null) {
            log.warn("Refresh token reuse detected for user {}; revoking its family", current.getUserId());
            refreshTokenRepository.revokeFamily(current.getFamilyId(), now);
            throw new BusinessException(TayranConst.UNAUTHORIZED);
        }
        if (!now.isBefore(current.getExpiresAt())) {
            throw new BusinessException(TayranConst.TOKEN_EXPIRED);
        }
        // A customer token can't be refreshed on the admin endpoint (and the other way round),
        // and a deactivated account gets no new tokens.
        User user = userRepository.findById(current.getUserId())
                .filter(u -> u.getRole() == expectedRole && u.isActive())
                .orElseThrow(() -> new BusinessException(TayranConst.UNAUTHORIZED));

        String raw = HashUtils.randomToken(REFRESH_TOKEN_BYTES);
        RefreshToken next = save(user.getId(), raw, current.getFamilyId(), now);
        current.setRevokedAt(now);
        current.setReplacedById(next.getId());
        refreshTokenRepository.save(current);
        return new TokenPair(user.getId(), user.getRole(), jwtUtil.generateAccessToken(user.getId(), user.getRole()), raw);
    }

    @Override
    @Transactional
    public void revoke(String refreshToken) {
        refreshTokenRepository.findByTokenHashForUpdate(HashUtils.sha256Hex(refreshToken))
                .ifPresent(token -> refreshTokenRepository.revokeFamily(token.getFamilyId(), clock.instant()));
    }

    @Override
    @Transactional
    public void revokeAll(long userId) {
        refreshTokenRepository.revokeAllForUser(userId, clock.instant());
    }

    private RefreshToken save(long userId, String raw, UUID familyId, Instant now) {
        return refreshTokenRepository.save(RefreshToken.builder()
                .userId(userId)
                .tokenHash(HashUtils.sha256Hex(raw))
                .familyId(familyId)
                .expiresAt(now.plus(jwtProperties.refreshTokenTtl()))
                .createdOn(now)
                .build());
    }
}
