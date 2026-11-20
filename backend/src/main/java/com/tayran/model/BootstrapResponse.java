package com.tayran.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.tayran.dao.entity.Address;

import java.util.List;

/**
 * Everything the home screen needs, in one call: the customer, the delivery promise, the active
 * categories (so home renders before the catalog arrives), where the store's catalog is, and the
 * image URL templates.
 */
public record BootstrapResponse(
        NextStep nextStep,
        String firstName,
        String lastName,
        /* The signed-in phone (+20…), shown read-only on the profile. */
        String phone,
        /* "ar" or "en": the language push texts are sent in. */
        String language,
        /* The default address, or null before the address step. */
        AddressDto address,
        String etaText,
        int etaMinutes,
        List<CategoryDto> categories,
        /* Null until the store's catalog has been published once. */
        CatalogRef catalog,
        ImageTemplates images,
        /* Fees, free-delivery threshold, minimum order and ETA of the customer's store. */
        com.tayran.service.impl.StoreSettingsService.StoreSettingsDto settings,
        /* Saved addresses, default first. */
        List<com.tayran.model.ProfileDtos.SavedAddressDto> addresses,
        /* Orders not yet delivered or cancelled, newest first. */
        List<com.tayran.model.order.OrderDtos.OrderSummaryDto> activeOrders,
        boolean onlinePaymentEnabled) {

    public record AddressDto(long id, long villageId, String villageNameAr, String villageNameEn,
                             long streetId, String streetNameAr, String streetNameEn, String landmark) {
        public static AddressDto of(Address address) {
            return new AddressDto(address.getId(),
                    address.getVillage().getId(), address.getVillage().getNameAr(), address.getVillage().getNameEn(),
                    address.getStreet().getId(), address.getStreet().getNameAr(), address.getStreet().getNameEn(),
                    address.getLandmark());
        }
    }

    /** img is the image hash; with {@link ImageTemplates#category()} it becomes a URL. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record CategoryDto(long id, String nameAr, String nameEn, String img, String bg, String tile) {
    }

    /** store: whose catalog it is (the app caches one file per store). */
    public record CatalogRef(long store, int version, String url) {
    }

    /** URL templates with {hash} and {w}; the app picks the smallest width that covers the layout. */
    public record ImageTemplates(String product, List<Integer> productWidths, String category, List<Integer> categoryWidths) {
    }
}
