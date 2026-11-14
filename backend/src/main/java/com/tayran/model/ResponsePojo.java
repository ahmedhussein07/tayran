package com.tayran.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * The unified response wrapper (same shape as the reference project), plus {@code code},
 * a stable error code that is only present on errors.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonPropertyOrder({"success", "code", "messageEn", "messageAr", "content"})
public class ResponsePojo {
    private boolean success;
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private String code;
    private String messageEn;
    private String messageAr;
    private Object content;

    public ResponsePojo(boolean success, String messageEn, String messageAr, Object content) {
        this(success, null, messageEn, messageAr, content);
    }

    public static ResponsePojo ok(Object content) {
        return new ResponsePojo(true, TayranConst.SUCCESS, TayranConst.SUCCESS_AR, content);
    }

    public static ResponsePojo error(ErrorDto error, Object content) {
        return new ResponsePojo(false, error.getErrorKey(), error.getMessageEn(), error.getMessageAr(), content);
    }
}
