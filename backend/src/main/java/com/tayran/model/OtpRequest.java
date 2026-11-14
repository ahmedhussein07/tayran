package com.tayran.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OtpRequest {
    /** Validated and normalized by the service, so any bad value returns INVALID_PHONE. */
    private String phone;
}
