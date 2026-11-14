package com.tayran.service.impl;

import com.tayran.config.properties.JwtProperties;
import com.tayran.config.security.JwtUtil;
import com.tayran.dao.entity.RefreshToken;
import com.tayran.dao.repository.RefreshTokenRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import com.tayran.model.TokenPair;
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
    private final JwtUtil jwtUtil;
    private final JwtProperties jwtProperties;
    private final Clock clock;

    @Override
    @Transactional
    public TokenPair issue(long userId) {
        String raw = HashUtils.randomToken(REFRESH_TOKEN_BYTES);
        save(userId, raw, UUID.randomUUID(), clock.instant());
        return new TokenPair(userId, jwtUtil.generateAccessToken(userId), raw);
    }

    /** Revoking a reused token's family must stick, so business errors don't roll back. */
    @Override
    @Transactional(noRollbackFor = BusinessException.class)
    public TokenPair rotate(String refreshToken) {
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

        String raw = HashUtils.randomToken(REFRESH_TOKEN_BYTES);
        RefreshToken next = save(current.getUserId(), raw, current.getFamilyId(), now);
        current.setRevokedAt(now);
        current.setReplacedById(next.getId());
        refreshTokenRepository.save(current);
        return new TokenPair(current.getUserId(), jwtUtil.generateAccessToken(current.getUserId()), raw);
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
