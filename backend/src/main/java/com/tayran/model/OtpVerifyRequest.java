package com.tayran.model;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OtpVerifyRequest {
    @NotNull(message = TayranConst.VALIDATION_ERROR)
    private UUID challengeId;

    @NotNull(message = TayranConst.VALIDATION_ERROR)
    @Pattern(regexp = "^\\d{4}$", message = TayranConst.VALIDATION_ERROR)
    private String code;
}
