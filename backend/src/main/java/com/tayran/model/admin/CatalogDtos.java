package com.tayran.model.admin;

import com.tayran.model.TayranConst;
import com.tayran.utils.validation.TrimmedSize;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/** Admin catalog requests and responses. */
public final class CatalogDtos {

    private CatalogDtos() {
    }

    /** The category tile pastels from tokens.json, or "neutral" until one is chosen. */
    public static final String TILE_COLOR_PATTERN = "^(pastel-(mint|wheat|sky|blush|butter|lilac|aqua|rose)|neutral)$";

    public record CategoryRequest(
            @TrimmedSize(min = 2, max = 50) String nameAr,
            @TrimmedSize(min = 2, max = 50) String nameEn,
            @NotNull(message = TayranConst.VALIDATION_ERROR)
            @Pattern(regexp = TILE_COLOR_PATTERN, message = TayranConst.VALIDATION_ERROR) String tileColor,
            /* From POST /admin/images?kind=CATEGORY; null for no image. */
            String imageHash) {
    }

    public record SubcategoryRequest(
            @TrimmedSize(min = 2, max = 50) String nameAr,
            @TrimmedSize(min = 2, max = 50) String nameEn) {
    }

    public record ActiveRequest(@NotNull(message = TayranConst.VALIDATION_ERROR) Boolean active) {
    }

    public record ReorderRequest(@NotEmpty(message = TayranConst.VALIDATION_ERROR) List<Long> ids) {
    }

    public record ProductRequest(
            @NotNull(message = TayranConst.VALIDATION_ERROR) Long subcategoryId,
            @TrimmedSize(min = 2, max = 100) String nameAr,
            @TrimmedSize(min = 2, max = 100) String nameEn,
            @TrimmedSize(min = 1, max = 40) String sizeLabel,
            @Size(max = 600, message = TayranConst.VALIDATION_ERROR) String description,
            @Size(max = 600, message = TayranConst.VALIDATION_ERROR) String ingredients,
            /* From POST /admin/images?kind=PRODUCT; null for no image. */
            String imageHash,
            @NotNull(message = TayranConst.VALIDATION_ERROR) Boolean active,
            @NotNull(message = TayranConst.VALIDATION_ERROR)
            @DecimalMin(value = "0.00", message = TayranConst.VALIDATION_ERROR)
            @Digits(integer = 8, fraction = 2, message = TayranConst.VALIDATION_ERROR) BigDecimal price,
            @DecimalMin(value = "0.00", inclusive = false, message = TayranConst.VALIDATION_ERROR)
            @Digits(integer = 8, fraction = 2, message = TayranConst.VALIDATION_ERROR) BigDecimal oldPrice,
            @NotNull(message = TayranConst.VALIDATION_ERROR) Boolean available) {
    }

    public record AdminCategoryDto(long id, String nameAr, String nameEn, String tileColor, String imageHash, String imageBg,
                                   String imageUrl, int sortOrder, boolean active, long subcategoryCount, long productCount) {
    }

    public record AdminSubcategoryDto(long id, long categoryId, String nameAr, String nameEn, int sortOrder, boolean active,
                                      long productCount) {
    }

    public record AdminProductDto(long id, long subcategoryId, long categoryId, String nameAr, String nameEn, String sizeLabel,
                                  String description, String ingredients, String imageHash, String imageBg, String imageUrl,
                                  boolean active, int sortOrder, BigDecimal price, BigDecimal oldPrice, boolean available,
                                  Instant createdOn, Instant lastUpdatedOn) {
    }

    public record ProductFilter(String q, Long categoryId, Long subcategoryId, Boolean active, Boolean available,
                                int page, int size) {
    }
}
