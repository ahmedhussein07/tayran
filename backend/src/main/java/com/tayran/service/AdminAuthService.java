package com.tayran.service;

import com.tayran.model.TokenPair;
import com.tayran.model.admin.AdminDtos.AdminUserDto;

public interface AdminAuthService {

    /** Phone + password sign-in for admins. One generic INVALID_CREDENTIALS for every failure. */
    TokenPair login(String phone, String password, String clientIp);

    TokenPair refresh(String refreshToken);

    void logout(String refreshToken);

    AdminUserDto me(long adminId);

    void changePassword(long adminId, String currentPassword, String newPassword);
}
