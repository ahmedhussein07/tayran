package com.tayran.service;

import com.tayran.dao.entity.User;
import com.tayran.model.TokenPair;
import com.tayran.model.UserRole;

public interface TokenService {

    /** Starts a new refresh-token family (a new sign-in). */
    TokenPair issue(User user);

    /**
     * Rotates a refresh token: the old one stops working and a new pair is returned.
     * Reusing an already-rotated token revokes the whole family. The token must belong to an
     * active user with {@code expectedRole}.
     */
    TokenPair rotate(String refreshToken, UserRole expectedRole);

    /** Signs out: revokes the token's whole family. Unknown tokens are ignored. */
    void revoke(String refreshToken);

    /** Revokes every refresh token of a user (password reset, deactivation). */
    void revokeAll(long userId);
}
