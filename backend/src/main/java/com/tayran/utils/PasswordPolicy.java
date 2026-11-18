package com.tayran.utils;

import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;

/** Admin passwords: at least 10 characters, with at least one letter and one digit. */
public final class PasswordPolicy {

    public static final int MIN_LENGTH = 10;

    private PasswordPolicy() {
    }

    public static boolean isAcceptable(String password) {
        if (password == null || password.length() < MIN_LENGTH || password.length() > 128) {
            return false;
        }
        boolean letter = password.codePoints().anyMatch(Character::isLetter);
        boolean digit = password.codePoints().anyMatch(Character::isDigit);
        return letter && digit;
    }

    /** @throws BusinessException WEAK_PASSWORD */
    public static void check(String password) {
        if (!isAcceptable(password)) {
            throw new BusinessException(TayranConst.WEAK_PASSWORD);
        }
    }
}
