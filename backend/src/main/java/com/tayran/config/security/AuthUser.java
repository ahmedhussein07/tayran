package com.tayran.config.security;

import com.tayran.model.UserRole;

/** The authenticated principal, taken from the access token alone (no database lookup). */
public record AuthUser(long id, UserRole role) {
}
