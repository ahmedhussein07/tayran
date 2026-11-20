package com.tayran.model.order;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.tayran.model.TayranConst;
import com.tayran.utils.validation.TrimmedSize;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/** Request and response bodies for orders (customer and admin). */
public final class OrderDtos {

    private OrderDtos() {
    }

    // ---- customer requests -------------------------------------------------------------------

    public record PlaceOrderRequest(
            @NotNull(message = TayranConst.VALIDATION_ERROR) Long addressId,
            @NotNull(message = TayranConst.VALIDATION_ERROR) PaymentMethod paymentMethod,
            @NotEmpty(message = TayranConst.VALIDATION_ERROR) @Size(max = 100, message = TayranConst.VALIDATION_ERROR)
            List<@Valid CartLine> items,
            @Size(max = 300, message = TayranConst.VALIDATION_ERROR) String notes,
            @DecimalMin(value = "1", message = TayranConst.VALIDATION_ERROR)
            @Digits(integer = 8, fraction = 2, message = TayranConst.VALIDATION_ERROR) BigDecimal cashChangeFor,
            @NotNull(message = TayranConst.VALIDATION_ERROR)
            @Digits(integer = 8, fraction = 2, message = TayranConst.VALIDATION_ERROR) BigDecimal expectedTotal) {
    }

    public record CartLine(
            @NotNull(message = TayranConst.VALIDATION_ERROR) Long productId,
            @Min(value = 1, message = TayranConst.VALIDATION_ERROR) @Max(value = 99, message = TayranConst.VALIDATION_ERROR) int qty,
            SubstitutionPref substitutionPref,
            /* The price the app showed; if it differs from the current one the line is PRICE_CHANGED. */
            BigDecimal unitPrice) {
    }

    /** 409 CART_CHANGED content: every line as the server sees it, and the right totals. Nothing was created. */
    public record CartChanged(List<CartLineCheck> lines, BigDecimal subtotal, BigDecimal deliveryFee, BigDecimal onlineFee,
                              BigDecimal total, BigDecimal minOrderAmount) {
    }

    /** status: OK, PRICE_CHANGED (price is the new one) or UNAVAILABLE. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record CartLineCheck(long productId, String status, BigDecimal price, BigDecimal oldPrice, int qty) {
    }

    // ---- customer responses ------------------------------------------------------------------

    /** The whole order: enough for the success screen and tracking without another call. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record OrderDto(long id, long number, OrderStatus status, int stage, PaymentMethod paymentMethod, Instant createdAt,
                           int etaMinutes, Instant expectedDeliveryAt, BigDecimal subtotal, BigDecimal deliveryFee,
                           BigDecimal onlineFee, BigDecimal discount, BigDecimal total, BigDecimal originalTotal,
                           boolean itemsChanged, BigDecimal cashChangeFor, String notes, DeliveryAddress address,
                           Courier courier, String cancelReason, ActorType cancelledBy, int version, int itemCount,
                           List<OrderItemDto> items, List<StageTime> timeline) {
    }

    /** A compact row for the orders list and the home cards. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record OrderSummaryDto(long id, long number, OrderStatus status, int stage, BigDecimal total, int itemCount,
                                  List<String> images, Instant createdAt, int etaMinutes, Instant expectedDeliveryAt,
                                  int version) {
    }

    public record OrderPage(List<OrderSummaryDto> orders, String nextCursor) {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record OrderItemDto(long id, long productId, String nameAr, String nameEn, String size, String img,
                               BigDecimal unitPrice, int qty, int originalQty, SubstitutionPref substitutionPref,
                               LineStatus lineStatus, Long replacedByItemId, boolean replacement, BigDecimal lineTotal,
                               /* The 160px variant, for the portal; the app builds URLs from its templates. */
                               String imageUrl) {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record DeliveryAddress(String villageNameAr, String villageNameEn, String streetNameAr, String streetNameEn,
                                  String landmark, String label) {
        public static DeliveryAddress of(CustomerSnapshot s) {
            return new DeliveryAddress(s.villageNameAr(), s.villageNameEn(), s.streetNameAr(), s.streetNameEn(), s.landmark(), s.label());
        }
    }

    public record Courier(String name, String phone) {
    }

    /** When the order reached a stage (from order_events). */
    public record StageTime(OrderStatus status, int stage, Instant at) {
    }

    // ---- admin -------------------------------------------------------------------------------

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record AdminOrderDto(long id, long number, OrderStatus status, int stage, PaymentMethod paymentMethod,
                                Instant createdAt, int etaMinutes, CustomerSnapshot customer, String notes,
                                BigDecimal cashChangeFor, BigDecimal subtotal, BigDecimal deliveryFee, BigDecimal onlineFee,
                                BigDecimal discount, BigDecimal total, BigDecimal originalTotal, boolean itemsChanged,
                                Courier courier, String cancelReason, Boolean cashCollected, int version,
                                List<OrderItemDto> items, List<AdminEventDto> events) {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record AdminOrderRow(long id, long number, OrderStatus status, String customerName, String phone,
                                String village, int itemCount, BigDecimal total, PaymentMethod paymentMethod,
                                Instant createdAt, int version) {
    }

    public record AdminOrderPage(List<AdminOrderRow> orders, String nextCursor) {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record AdminEventDto(EventKind kind, OrderStatus status, ActorType actorType, Long actorId, String actorName,
                                String note, Instant at) {
    }

    public record VersionRequest(@NotNull(message = TayranConst.VALIDATION_ERROR) Integer version) {
    }

    public record OutForDeliveryRequest(
            @NotNull(message = TayranConst.VALIDATION_ERROR) Integer version,
            @TrimmedSize(min = 2, max = 50) String courierName,
            @NotNull(message = TayranConst.VALIDATION_ERROR) String courierPhone) {
    }

    public record DeliverRequest(@NotNull(message = TayranConst.VALIDATION_ERROR) Integer version, boolean cashCollected) {
    }

    public record CancelRequest(@NotNull(message = TayranConst.VALIDATION_ERROR) Integer version,
                                @TrimmedSize(min = 3, max = 300) String reason) {
    }

    /** REDUCE (qty), REMOVE, or REPLACE (productId, optional qty). */
    public record EditItemsRequest(@NotNull(message = TayranConst.VALIDATION_ERROR) Integer version,
                                   @NotEmpty(message = TayranConst.VALIDATION_ERROR) List<@Valid ItemEdit> edits) {
    }

    public record ItemEdit(
            @NotNull(message = TayranConst.VALIDATION_ERROR) Long lineId,
            @NotNull(message = TayranConst.VALIDATION_ERROR)
            @Pattern(regexp = "REDUCE|REMOVE|REPLACE", message = TayranConst.VALIDATION_ERROR) String action,
            Integer qty,
            Long productId) {
    }

    // ---- live feed ---------------------------------------------------------------------------

    /** What the admin stream sends for each change. */
    public record OrderStreamEvent(String type, long orderId, long number, OrderStatus status, int version) {
    }
}
