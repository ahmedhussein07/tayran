package com.tayran.dao.entity;

import com.tayran.model.order.ActorType;
import com.tayran.model.order.EventKind;
import com.tayran.model.order.OrderStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/** A status change or an item edit: the tracking timestamps and the audit trail. */
@Getter
@NoArgsConstructor
@Entity
@Table(name = "order_events")
public class OrderEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false, updatable = false)
    private Long orderId;

    @Enumerated(EnumType.STRING)
    @Column(name = "kind", nullable = false, length = 20, updatable = false)
    private EventKind kind;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20, updatable = false)
    private OrderStatus status;

    @Enumerated(EnumType.STRING)
    @Column(name = "actor_type", nullable = false, length = 10, updatable = false)
    private ActorType actorType;

    @Column(name = "actor_id", updatable = false)
    private Long actorId;

    @Column(name = "note", length = 300, updatable = false)
    private String note;

    @Column(name = "at", nullable = false, updatable = false)
    private Instant at;

    public OrderEvent(Long orderId, EventKind kind, OrderStatus status, ActorType actorType, Long actorId, String note, Instant at) {
        this.orderId = orderId;
        this.kind = kind;
        this.status = status;
        this.actorType = actorType;
        this.actorId = actorId;
        this.note = note;
        this.at = at;
    }
}
