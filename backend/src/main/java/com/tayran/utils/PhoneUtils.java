package com.tayran.utils;

import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Egyptian mobile numbers only: 010, 011, 012, 015. */
public final class PhoneUtils {

    /** 01XXXXXXXXX, +201XXXXXXXXX or 00201XXXXXXXXX once whitespace is removed. */
    private static final Pattern EGYPT_MOBILE = Pattern.compile("^(?:\\+20|0020|0)(1[0125]\\d{8})$");
    private static final Pattern WHITESPACE = Pattern.compile("[\\s\\u00A0\\u200E\\u200F]+");

    private PhoneUtils() {
    }

    /**
     * Normalizes to E.164 (+201XXXXXXXXX).
     *
     * @throws BusinessException INVALID_PHONE when the number is not an Egyptian mobile number
     */
    public static String normalize(String raw) {
        if (raw == null) {
            throw new BusinessException(TayranConst.INVALID_PHONE);
        }
        String compact = WHITESPACE.matcher(toWesternDigits(raw)).replaceAll("");
        Matcher matcher = EGYPT_MOBILE.matcher(compact);
        if (!matcher.matches()) {
            throw new BusinessException(TayranConst.INVALID_PHONE);
        }
        return "+20" + matcher.group(1);
    }

    /** Accepts Arabic-Indic (٠-٩) and Eastern Arabic-Indic (۰-۹) digits too. */
    private static String toWesternDigits(String value) {
        StringBuilder sb = new StringBuilder(value.length());
        for (char c : value.toCharArray()) {
            if (c >= '٠' && c <= '٩') {
                sb.append((char) ('0' + (c - '٠')));
            } else if (c >= '۰' && c <= '۹') {
                sb.append((char) ('0' + (c - '۰')));
            } else {
                sb.append(c);
            }
        }
        return sb.toString();
    }
}
