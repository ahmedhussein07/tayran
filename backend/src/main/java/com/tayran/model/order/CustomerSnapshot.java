package com.tayran.model.order;

/**
 * Who ordered and where to, copied into the order when it is placed (orders.customer_snapshot).
 * Later profile or address changes never change past orders.
 */
public record CustomerSnapshot(
        String firstName,
        String lastName,
        String phone,
        long villageId,
        String villageNameAr,
        String villageNameEn,
        long streetId,
        String streetNameAr,
        String streetNameEn,
        String landmark,
        String label) {
}
