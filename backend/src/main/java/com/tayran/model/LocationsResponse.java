package com.tayran.model;

import com.tayran.dao.entity.Street;
import com.tayran.dao.entity.Village;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/** All active villages, each with its active streets: the whole address picker in one response. */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LocationsResponse {
    private List<VillageDto> villages;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class VillageDto {
        private long id;
        private String nameAr;
        private String nameEn;
        private List<StreetDto> streets;

        public VillageDto(Village village, List<StreetDto> streets) {
            this(village.getId(), village.getNameAr(), village.getNameEn(), streets);
        }
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StreetDto {
        private long id;
        private String nameAr;
        private String nameEn;

        public StreetDto(Street street) {
            this(street.getId(), street.getNameAr(), street.getNameEn());
        }
    }
}
