package com.tayran.model;

/** An access token plus the opaque refresh token, for the user they belong to. */
public record TokenPair(long userId, String accessToken, String refreshToken) {
}
