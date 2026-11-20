package com.tayran.service.impl.order;

import com.tayran.model.order.OrderDtos.OrderStreamEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * The admin portal's live order feed (Server-Sent Events). Sends NEW / UPDATED after each order
 * change commits, and a heartbeat every 25 seconds. Connections live in memory, so this assumes a
 * single backend instance; several instances would need a shared channel (e.g. Postgres NOTIFY).
 */
@Slf4j
@Component
public class AdminOrderStream {

    /** The portal reconnects on its own; a long timeout just recycles idle connections. */
    static final Duration TIMEOUT = Duration.ofMinutes(30);

    private final List<SseEmitter> emitters = new CopyOnWriteArrayList<>();

    public SseEmitter connect() {
        SseEmitter emitter = new SseEmitter(TIMEOUT.toMillis());
        emitter.onCompletion(() -> emitters.remove(emitter));
        emitter.onTimeout(() -> emitters.remove(emitter));
        emitter.onError(e -> emitters.remove(emitter));
        emitters.add(emitter);
        try {
            emitter.send(SseEmitter.event().comment("connected"));
        } catch (IOException e) {
            emitters.remove(emitter);
        }
        return emitter;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onOrderChanged(OrderChanged change) {
        broadcast(new OrderStreamEvent(change.created() ? "NEW" : "UPDATED", change.orderId(), change.number(), change.status(),
                change.version()));
    }

    void broadcast(OrderStreamEvent event) {
        for (SseEmitter emitter : emitters) {
            try {
                emitter.send(SseEmitter.event().name("order").data(event, MediaType.APPLICATION_JSON));
            } catch (IOException | IllegalStateException e) {
                emitters.remove(emitter);
            }
        }
    }

    @Scheduled(fixedRateString = "${app.admin-stream-heartbeat:25s}")
    public void heartbeat() {
        for (SseEmitter emitter : emitters) {
            try {
                emitter.send(SseEmitter.event().comment("hb"));
            } catch (IOException | IllegalStateException e) {
                emitters.remove(emitter);
            }
        }
    }

    int connections() {
        return emitters.size();
    }
}
