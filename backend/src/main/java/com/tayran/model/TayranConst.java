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

    // Orders
    public static final String CART_CHANGED = "CART_CHANGED";
    public static final String MIN_ORDER_NOT_MET = "MIN_ORDER_NOT_MET";
    public static final String PAYMENT_METHOD_NOT_AVAILABLE = "PAYMENT_METHOD_NOT_AVAILABLE";
    public static final String IDEMPOTENCY_KEY_REQUIRED = "IDEMPOTENCY_KEY_REQUIRED";
    public static final String ORDER_STATE_CHANGED = "ORDER_STATE_CHANGED";
    public static final String INVALID_ADDRESS = "INVALID_ADDRESS";
    public static final String LAST_ADDRESS = "LAST_ADDRESS";
    public static final String REPLACEMENT_NOT_ALLOWED = "REPLACEMENT_NOT_ALLOWED";
    public static final String EMPTY_ORDER = "EMPTY_ORDER";
    public static final String INVALID_COURIER_PHONE = "INVALID_COURIER_PHONE";
}
