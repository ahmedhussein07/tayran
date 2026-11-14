package com.tayran.config.security;

/** The authenticated principal: only the user id taken from the access token. */
public record AuthUser(long id) {
}
