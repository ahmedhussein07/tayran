package com.tayran.model;

public final class TayranConst {

    private TayranConst() {
    }

    public static final String SUCCESS = "SUCCESS";
    public static final String SUCCESS_AR = "تم بنجاح";
    public static final String OTP_HAS_BEEN_SENT = "OTP has been sent successfully";
    public static final String OTP_HAS_BEEN_SENT_AR = "تم ارسال الكود بنجاح";
    public static final String LOGIN_SUCCESSFULLY = "Logged in successfully";
    public static final String LOGIN_SUCCESSFULLY_AR = "تم تسجيل الدخول بنجاح";

    /** Static for now; replaced by the store's real estimate later. */
    public static final String ETA_TEXT = "٢٠ دقيقة";
    public static final int ETA_MINUTES = 20;

    public static final String ROLE_CUSTOMER = "CUSTOMER";

    // Stable error codes. Each one has an entry in files/error-map.json.
    public static final String INVALID_PHONE = "INVALID_PHONE";
    public static final String OTP_INVALID = "OTP_INVALID";
    public static final String OTP_EXPIRED = "OTP_EXPIRED";
    public static final String OTP_TOO_MANY_ATTEMPTS = "OTP_TOO_MANY_ATTEMPTS";
    public static final String OTP_RESEND_TOO_SOON = "OTP_RESEND_TOO_SOON";
    public static final String OTP_RATE_LIMITED = "OTP_RATE_LIMITED";
    public static final String VALIDATION_ERROR = "VALIDATION_ERROR";
    public static final String INVALID_STREET = "INVALID_STREET";
    public static final String UNAUTHORIZED = "UNAUTHORIZED";
    public static final String TOKEN_EXPIRED = "TOKEN_EXPIRED";
    public static final String NOT_FOUND = "NOT_FOUND";
    public static final String METHOD_NOT_ALLOWED = "METHOD_NOT_ALLOWED";
    public static final String INTERNAL_ERROR = "INTERNAL_ERROR";

    // Admin
    public static final String FORBIDDEN = "FORBIDDEN";
    public static final String INVALID_CREDENTIALS = "INVALID_CREDENTIALS";
    public static final String ACCOUNT_LOCKED = "ACCOUNT_LOCKED";
    public static final String LOGIN_RATE_LIMITED = "LOGIN_RATE_LIMITED";
    public static final String WEAK_PASSWORD = "WEAK_PASSWORD";
    public static final String PHONE_TAKEN = "PHONE_TAKEN";
    public static final String CANNOT_DELETE_SELF = "CANNOT_DELETE_SELF";
    public static final String CANNOT_DEACTIVATE_SELF = "CANNOT_DEACTIVATE_SELF";

    // Catalog
    public static final String CATEGORY_NOT_EMPTY = "CATEGORY_NOT_EMPTY";
    public static final String SUBCATEGORY_NOT_EMPTY = "SUBCATEGORY_NOT_EMPTY";
    public static final String UNKNOWN_IMAGE = "UNKNOWN_IMAGE";
    public static final String IMAGE_TYPE_UNSUPPORTED = "IMAGE_TYPE_UNSUPPORTED";
    public static final String IMAGE_TOO_LARGE = "IMAGE_TOO_LARGE";
    public static final String IMAGE_DIMENSIONS_TOO_LARGE = "IMAGE_DIMENSIONS_TOO_LARGE";
    public static final String IMAGE_UNREADABLE = "IMAGE_UNREADABLE";
}
