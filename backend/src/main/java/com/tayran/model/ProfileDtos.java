package com.tayran.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.tayran.dao.entity.Address;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Saved addresses, preferences and push devices. */
public final class ProfileDtos {

    private ProfileDtos() {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record SavedAddressDto(long id, String label, boolean isDefault, long villageId, String villageNameAr,
                                  String villageNameEn, long streetId, String streetNameAr, String streetNameEn, String landmark) {
        public static SavedAddressDto of(Address a) {
            return new SavedAddressDto(a.getId(), a.getLabel(), a.isDefaultAddress(), a.getVillage().getId(),
                    a.getVillage().getNameAr(), a.getVillage().getNameEn(), a.getStreet().getId(), a.getStreet().getNameAr(),
                    a.getStreet().getNameEn(), a.getLandmark());
        }
    }

    public record PreferencesRequest(
            @NotBlank(message = TayranConst.VALIDATION_ERROR)
            @Pattern(regexp = "ar|en", message = TayranConst.VALIDATION_ERROR) String language) {
    }

    public record DeviceRequest(
            @NotBlank(message = TayranConst.VALIDATION_ERROR) @Size(max = 512, message = TayranConst.VALIDATION_ERROR) String fcmToken,
            @NotBlank(message = TayranConst.VALIDATION_ERROR)
            @Pattern(regexp = "ANDROID|IOS|WEB", message = TayranConst.VALIDATION_ERROR) String platform) {
    }
}
