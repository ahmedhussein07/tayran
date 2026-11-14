package com.tayran.model;

import com.tayran.dao.entity.Address;
import com.tayran.dao.entity.Category;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/** Everything the home screen needs, in one call. */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class BootstrapResponse {
    private NextStep nextStep;
    private String firstName;
    /** The default address, or null before the address step. */
    private AddressDto address;
    private String etaText;
    private int etaMinutes;
    private List<CategoryDto> categories;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AddressDto {
        private long id;
        private long villageId;
        private String villageNameAr;
        private String villageNameEn;
        private long streetId;
        private String streetNameAr;
        private String streetNameEn;
        private String landmark;

        public AddressDto(Address address) {
            this(address.getId(),
                    address.getVillage().getId(), address.getVillage().getNameAr(), address.getVillage().getNameEn(),
                    address.getStreet().getId(), address.getStreet().getNameAr(), address.getStreet().getNameEn(),
                    address.getLandmark());
        }
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategoryDto {
        private long id;
        private String nameAr;
        private String nameEn;
        private String iconKey;
        private String colorToken;
        private int sortOrder;

        public CategoryDto(Category category) {
            this(category.getId(), category.getNameAr(), category.getNameEn(),
                    category.getIconKey(), category.getColorToken(), category.getSortOrder());
        }
    }
}
