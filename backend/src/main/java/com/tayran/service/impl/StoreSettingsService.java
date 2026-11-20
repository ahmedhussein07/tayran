package com.tayran.service.impl;

import com.tayran.dao.entity.StoreSettings;
import com.tayran.dao.repository.StoreSettingsRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;

/** Fees, thresholds and the ETA for a store (one store for now). */
@Service
@RequiredArgsConstructor
public class StoreSettingsService {

    public record StoreSettingsDto(BigDecimal deliveryFee, BigDecimal freeDeliveryThreshold, BigDecimal minOrderAmount,
                                   BigDecimal onlinePaymentFee, int etaMinutes) {
        public static StoreSettingsDto of(StoreSettings s) {
            return new StoreSettingsDto(s.getDeliveryFee(), s.getFreeDeliveryThreshold(), s.getMinOrderAmount(),
                    s.getOnlinePaymentFee(), s.getEtaMinutes());
        }
    }

    public record UpdateSettingsRequest(
            @NotNull(message = TayranConst.VALIDATION_ERROR) @DecimalMin(value = "0", message = TayranConst.VALIDATION_ERROR)
            @Digits(integer = 8, fraction = 2, message = TayranConst.VALIDATION_ERROR) BigDecimal deliveryFee,
            @NotNull(message = TayranConst.VALIDATION_ERROR) @DecimalMin(value = "0", message = TayranConst.VALIDATION_ERROR)
            @Digits(integer = 8, fraction = 2, message = TayranConst.VALIDATION_ERROR) BigDecimal freeDeliveryThreshold,
            @NotNull(message = TayranConst.VALIDATION_ERROR) @DecimalMin(value = "0", message = TayranConst.VALIDATION_ERROR)
            @Digits(integer = 8, fraction = 2, message = TayranConst.VALIDATION_ERROR) BigDecimal minOrderAmount,
            @NotNull(message = TayranConst.VALIDATION_ERROR) @DecimalMin(value = "0", message = TayranConst.VALIDATION_ERROR)
            @Digits(integer = 8, fraction = 2, message = TayranConst.VALIDATION_ERROR) BigDecimal onlinePaymentFee,
            @NotNull(message = TayranConst.VALIDATION_ERROR) @Min(value = 5, message = TayranConst.VALIDATION_ERROR)
            @Max(value = 240, message = TayranConst.VALIDATION_ERROR) Integer etaMinutes) {
    }

    private final StoreSettingsRepository repository;
    private final Clock clock;

    @Transactional(readOnly = true)
    public StoreSettings get(long storeId) {
        return repository.findById(storeId).orElseThrow(() -> new IllegalStateException("No settings for store " + storeId));
    }

    @Transactional
    public StoreSettingsDto update(long storeId, long adminId, UpdateSettingsRequest request) {
        StoreSettings s = repository.findById(storeId).orElseThrow(() -> new BusinessException(TayranConst.NOT_FOUND));
        s.setDeliveryFee(OrderPricing.money(request.deliveryFee()));
        s.setFreeDeliveryThreshold(OrderPricing.money(request.freeDeliveryThreshold()));
        s.setMinOrderAmount(OrderPricing.money(request.minOrderAmount()));
        s.setOnlinePaymentFee(OrderPricing.money(request.onlinePaymentFee()));
        s.setEtaMinutes(request.etaMinutes());
        s.setUpdatedAt(clock.instant());
        s.setUpdatedBy(adminId);
        return StoreSettingsDto.of(repository.save(s));
    }
}
