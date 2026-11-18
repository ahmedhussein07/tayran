package com.tayran.model.admin;

import com.tayran.dao.entity.User;
import com.tayran.model.TayranConst;
import com.tayran.utils.validation.TrimmedSize;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

/** Request and response bodies for admin auth and admin users. */
public final class AdminDtos {

    private AdminDtos() {
    }

    public record LoginRequest(String phone, String password) {
    }

    /** The refresh token travels in an httpOnly cookie, never in the body. */
    public record LoginResponse(String accessToken, long expiresInSeconds, AdminUserDto admin) {
    }

    public record ChangePasswordRequest(
            @NotBlank(message = TayranConst.VALIDATION_ERROR) String currentPassword,
            @NotBlank(message = TayranConst.VALIDATION_ERROR) String newPassword) {
    }

    public record CreateAdminRequest(
            @TrimmedSize(min = 2, max = 30) String name,
            @NotBlank(message = TayranConst.VALIDATION_ERROR) String phone,
            @NotBlank(message = TayranConst.VALIDATION_ERROR) String password) {
    }

    public record UpdateAdminRequest(
            @TrimmedSize(min = 2, max = 30) String name,
            @NotNull(message = TayranConst.VALIDATION_ERROR) Boolean active) {
    }

    public record ResetPasswordRequest(@NotBlank(message = TayranConst.VALIDATION_ERROR) String password) {
    }

    public record AdminUserDto(long id, String name, String phone, boolean active, boolean locked, Instant createdOn) {
        public static AdminUserDto of(User user, Instant now) {
            boolean locked = user.getLockedUntil() != null && now.isBefore(user.getLockedUntil());
            return new AdminUserDto(user.getId(), user.getFirstName(), user.getPhone(), user.isActive(), locked, user.getCreatedOn());
        }
    }
}
