package com.tayran.model;

import lombok.Getter;
import lombok.Setter;

/** One entry of files/error-map.json. */
@Getter
@Setter
public class ErrorDto {
    private String errorKey;
    private int httpStatus;
    private String messageAr;
    private String messageEn;
}
