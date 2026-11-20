package com.tayran.controller;

import com.tayran.config.security.AuthUser;
import com.tayran.model.ResponsePojo;
import com.tayran.model.order.OrderDtos.PlaceOrderRequest;
import com.tayran.service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** The customer's orders. */
@RestController
@RequiredArgsConstructor
@RequestMapping("/orders")
@PreAuthorize("hasAuthority('CUSTOMER')")
public class OrderController {

    private final OrderService orderService;

    /** Idempotency-Key: one per checkout attempt; a repeat returns the same order. */
    @PostMapping
    public ResponseEntity<ResponsePojo> place(@AuthenticationPrincipal AuthUser user,
                                              @RequestHeader(name = "Idempotency-Key", required = false) String idempotencyKey,
                                              @RequestBody @Valid PlaceOrderRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(orderService.place(user.id(), idempotencyKey, request)));
    }

    @GetMapping
    public ResponseEntity<ResponsePojo> list(@AuthenticationPrincipal AuthUser user, @RequestParam(required = false) String cursor) {
        return ResponseEntity.ok(ResponsePojo.ok(orderService.list(user.id(), cursor)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponsePojo> get(@AuthenticationPrincipal AuthUser user, @PathVariable long id) {
        return ResponseEntity.ok(ResponsePojo.ok(orderService.get(user.id(), id)));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ResponsePojo> cancel(@AuthenticationPrincipal AuthUser user, @PathVariable long id) {
        return ResponseEntity.ok(ResponsePojo.ok(orderService.cancel(user.id(), id)));
    }
}
