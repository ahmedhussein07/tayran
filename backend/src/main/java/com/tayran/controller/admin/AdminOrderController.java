package com.tayran.controller.admin;

import com.tayran.config.security.AuthUser;
import com.tayran.model.ResponsePojo;
import com.tayran.model.order.OrderDtos.CancelRequest;
import com.tayran.model.order.OrderDtos.DeliverRequest;
import com.tayran.model.order.OrderDtos.EditItemsRequest;
import com.tayran.model.order.OrderDtos.OutForDeliveryRequest;
import com.tayran.model.order.OrderDtos.VersionRequest;
import com.tayran.model.order.OrderStatus;
import com.tayran.service.AdminOrderService;
import com.tayran.service.impl.order.AdminOrderStream;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/** Orders for the store team. Every change carries the version the admin saw (409 if it moved). */
@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/orders")
public class AdminOrderController {

    private final AdminOrderService orders;
    private final AdminOrderStream stream;

    @GetMapping
    public ResponseEntity<ResponsePojo> list(@RequestParam(required = false) OrderStatus status,
                                             @RequestParam(required = false) String cursor,
                                             @RequestParam(required = false) String search) {
        return ResponseEntity.ok(ResponsePojo.ok(orders.list(status, cursor, search)));
    }

    @GetMapping("/counts")
    public ResponseEntity<ResponsePojo> counts() {
        return ResponseEntity.ok(ResponsePojo.ok(orders.counts()));
    }

    /**
     * Live feed (Server-Sent Events). The portal reads it with fetch and the normal Authorization
     * header, so no token ever goes in a URL.
     */
    @GetMapping(path = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream() {
        return stream.connect();
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponsePojo> get(@PathVariable long id) {
        return ResponseEntity.ok(ResponsePojo.ok(orders.get(id)));
    }

    @PutMapping("/{id}/items")
    public ResponseEntity<ResponsePojo> editItems(@AuthenticationPrincipal AuthUser admin, @PathVariable long id,
                                                  @RequestBody @Valid EditItemsRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(orders.editItems(admin.id(), id, request)));
    }

    @PostMapping("/{id}/confirm")
    public ResponseEntity<ResponsePojo> confirm(@AuthenticationPrincipal AuthUser admin, @PathVariable long id,
                                                @RequestBody @Valid VersionRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(orders.confirm(admin.id(), id, request.version())));
    }

    @PostMapping("/{id}/out-for-delivery")
    public ResponseEntity<ResponsePojo> outForDelivery(@AuthenticationPrincipal AuthUser admin, @PathVariable long id,
                                                       @RequestBody @Valid OutForDeliveryRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(orders.outForDelivery(admin.id(), id, request)));
    }

    @PostMapping("/{id}/deliver")
    public ResponseEntity<ResponsePojo> deliver(@AuthenticationPrincipal AuthUser admin, @PathVariable long id,
                                                @RequestBody @Valid DeliverRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(orders.deliver(admin.id(), id, request)));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ResponsePojo> cancel(@AuthenticationPrincipal AuthUser admin, @PathVariable long id,
                                               @RequestBody @Valid CancelRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(orders.cancel(admin.id(), id, request)));
    }
}
