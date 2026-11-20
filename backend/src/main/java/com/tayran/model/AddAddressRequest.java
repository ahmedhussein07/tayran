package com.tayran.model;

import com.tayran.utils.validation.TrimmedSize;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AddAddressRequest {
    @NotNull(message = TayranConst.VALIDATION_ERROR)
    private Long villageId;

    @NotNull(message = TayranConst.VALIDATION_ERROR)
    private Long streetId;

    @TrimmedSize(min = 5, max = 150)
    private String landmark;

    /** Optional name for the address, e.g. "home". */
    @jakarta.validation.constraints.Size(max = 30, message = TayranConst.VALIDATION_ERROR)
    private String label;

    public AddAddressRequest(Long villageId, Long streetId, String landmark) {
        this(villageId, streetId, landmark, null);
    }
}
