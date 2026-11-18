package com.tayran.service.impl;

import com.tayran.dao.entity.User;
import com.tayran.dao.repository.UserRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import com.tayran.model.UserRole;
import com.tayran.model.admin.AdminDtos.AdminUserDto;
import com.tayran.model.admin.AdminDtos.CreateAdminRequest;
import com.tayran.model.admin.AdminDtos.UpdateAdminRequest;
import com.tayran.service.AdminUserService;
import com.tayran.service.TokenService;
import com.tayran.utils.PasswordPolicy;
import com.tayran.utils.PhoneUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.List;

/** Admin users. No roles or permissions inside the portal: every admin can do everything. */
@Service
@RequiredArgsConstructor
public class AdminUserServiceImpl implements AdminUserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;
    private final Clock clock;

    @Override
    @Transactional(readOnly = true)
    public List<AdminUserDto> list() {
        Instant now = clock.instant();
        return userRepository.findByRoleOrderByIdAsc(UserRole.ADMIN).stream().map(u -> AdminUserDto.of(u, now)).toList();
    }

    @Override
    @Transactional
    public AdminUserDto create(CreateAdminRequest request) {
        String phone = PhoneUtils.normalize(request.phone());
        PasswordPolicy.check(request.password());
        if (userRepository.existsByPhoneAndRole(phone, UserRole.ADMIN)) {
            throw new BusinessException(TayranConst.PHONE_TAKEN);
        }
        User admin = new User(phone, UserRole.ADMIN);
        admin.setFirstName(request.name().strip());
        admin.setPasswordHash(passwordEncoder.encode(request.password()));
        return AdminUserDto.of(userRepository.save(admin), clock.instant());
    }

    @Override
    @Transactional
    public AdminUserDto update(long currentAdminId, long id, UpdateAdminRequest request) {
        User admin = find(id);
        if (id == currentAdminId && !request.active()) {
            throw new BusinessException(TayranConst.CANNOT_DEACTIVATE_SELF);
        }
        admin.setFirstName(request.name().strip());
        boolean deactivated = admin.isActive() && !request.active();
        admin.setActive(request.active());
        userRepository.save(admin);
        if (deactivated) {
            tokenService.revokeAll(id);
        }
        return AdminUserDto.of(admin, clock.instant());
    }

    @Override
    @Transactional
    public void resetPassword(long id, String password) {
        User admin = find(id);
        PasswordPolicy.check(password);
        admin.setPasswordHash(passwordEncoder.encode(password));
        admin.setFailedLoginCount(0);
        admin.setLockedUntil(null);
        userRepository.save(admin);
        tokenService.revokeAll(id);
    }

    @Override
    @Transactional
    public void delete(long currentAdminId, long id) {
        if (id == currentAdminId) {
            throw new BusinessException(TayranConst.CANNOT_DELETE_SELF);
        }
        userRepository.delete(find(id));
    }

    private User find(long id) {
        return userRepository.findByIdAndRole(id, UserRole.ADMIN)
                .orElseThrow(() -> new BusinessException(TayranConst.NOT_FOUND));
    }
}
