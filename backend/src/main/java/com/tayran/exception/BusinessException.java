package com.tayran.exception;

import lombok.Getter;

import java.util.Map;

/**
 * Thrown with a stable error code from {@link com.tayran.model.TayranConst}.
 * {@code details} becomes the response's {@code content} (for example retryAfterSeconds).
 */
@Getter
public class BusinessException extends RuntimeException {

    private final transient Map<String, Object> details;

    public BusinessException(String code) {
        this(code, null);
    }

    public BusinessException(String code, Map<String, Object> details) {
        super(code);
        this.details = details;
    }

    public String getCode() {
        return getMessage();
    }
}
