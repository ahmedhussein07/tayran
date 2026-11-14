package com.tayran.service;

import com.tayran.model.TokenPair;

public interface TokenService {

    /** Starts a new refresh-token family (a new sign-in). */
    TokenPair issue(long userId);

    /**
     * Rotates a refresh token: the old one stops working and a new pair is returned.
     * Reusing an already-rotated token revokes the whole family.
     */
    TokenPair rotate(String refreshToken);
}
