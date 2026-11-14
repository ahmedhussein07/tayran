package com.tayran.model;

import com.tayran.utils.validation.TrimmedSize;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateNameRequest {
    @TrimmedSize(min = 2, max = 30)
    private String firstName;

    @TrimmedSize(min = 2, max = 30)
    private String lastName;
}
