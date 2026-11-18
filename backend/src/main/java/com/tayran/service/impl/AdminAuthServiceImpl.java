package com.tayran.service.impl;

import com.tayran.config.properties.AdminProperties;
import com.tayran.dao.entity.User;
import com.tayran.dao.repository.UserRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import com.tayran.model.TokenPair;
import com.tayran.model.UserRole;
import com.tayran.model.admin.AdminDtos.AdminUserDto;
import com.tayran.service.AdminAuthService;
import com.tayran.service.TokenService;
import com.tayran.utils.PasswordPolicy;
import com.tayran.utils.PhoneUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.Optional;

@Slf4j
@Service
public class AdminAuthServiceImpl implements AdminAuthService {

    private final UserRepository userRepository;
    private final TokenService tokenService;
    private final PasswordEncoder passwordEncoder;
    private final LoginAttemptGuard guard;
    private final AdminProperties properties;
    private final Clock clock;
    /** Compared against when the phone is unknown, so both paths take a BCrypt check's time. */
    private final String dummyHash;

    public AdminAuthServiceImpl(UserRepository userRepository, TokenService tokenService, PasswordEncoder passwordEncoder,
                                LoginAttemptGuard guard, AdminProperties properties, Clock clock) {
        this.userRepository = userRepository;
        this.tokenService = tokenService;
        this.passwordEncoder = passwordEncoder;
        this.guard = guard;
        this.properties = properties;
        this.clock = clock;
        this.dummyHash = passwordEncoder.encode("not-a-real-password-0");
    }

    /** Counters must persist even though the request fails, so business errors don't roll back. */
    @Override
    @Transactional(noRollbackFor = BusinessException.class)
    public TokenPair login(String rawPhone, String password, String clientIp) {
        guard.hitIp(clientIp == null ? "unknown" : clientIp);
        String pass = password == null ? "" : password;
        Optional<String> phone = normalize(rawPhone);
        Optional<User> found = phone.flatMap(p -> userRepository.findByPhoneAndRole(p, UserRole.ADMIN));

        if (found.isEmpty()) {
            String key = phone.orElse(String.valueOf(rawPhone));
            guard.checkUnknownPhone(key);
            passwordEncoder.matches(pass, dummyHash);
            guard.failUnknownPhone(key);
            throw new BusinessException(TayranConst.INVALID_CREDENTIALS);
        }

        User admin = found.get();
        Instant now = clock.instant();
        if (admin.getLockedUntil() != null && now.isBefore(admin.getLockedUntil())) {
            throw guard.locked(admin.getLockedUntil());
        }
        boolean matches = admin.getPasswordHash() != null && passwordEncoder.matches(pass, admin.getPasswordHash());
        if (!matches || !admin.isActive()) {
            int failures = admin.getFailedLoginCount() + 1;
            if (failures >= properties.maxFailedLogins()) {
                admin.setFailedLoginCount(0);
                admin.setLockedUntil(now.plus(properties.lockDuration()));
                log.warn("Admin account {} locked after {} failed logins", admin.getId(), failures);
            } else {
                admin.setFailedLoginCount(failures);
            }
            userRepository.save(admin);
            throw new BusinessException(TayranConst.INVALID_CREDENTIALS);
        }

        admin.setFailedLoginCount(0);
        admin.setLockedUntil(null);
        userRepository.save(admin);
        return tokenService.issue(admin);
    }

    @Override
    public TokenPair refresh(String refreshToken) {
        if (refreshToken == null || refreshToken.isBlank()) {
            throw new BusinessException(TayranConst.UNAUTHORIZED);
        }
        return tokenService.rotate(refreshToken, UserRole.ADMIN);
    }

    @Override
    public void logout(String refreshToken) {
        if (refreshToken != null && !refreshToken.isBlank()) {
            tokenService.revoke(refreshToken);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public AdminUserDto me(long adminId) {
        return AdminUserDto.of(findAdmin(adminId), clock.instant());
    }

    @Override
    @Transactional
    public void changePassword(long adminId, String currentPassword, String newPassword) {
        User admin = findAdmin(adminId);
        if (admin.getPasswordHash() == null || !passwordEncoder.matches(currentPassword, admin.getPasswordHash())) {
            throw new BusinessException(TayranConst.INVALID_CREDENTIALS);
        }
        PasswordPolicy.check(newPassword);
        admin.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(admin);
    }

    private User findAdmin(long id) {
        return userRepository.findByIdAndRole(id, UserRole.ADMIN).filter(User::isActive)
                .orElseThrow(() -> new BusinessException(TayranConst.UNAUTHORIZED));
    }

    private static Optional<String> normalize(String rawPhone) {
        try {
            return Optional.of(PhoneUtils.normalize(rawPhone));
        } catch (BusinessException e) {
            return Optional.empty();
        }
    }
}
