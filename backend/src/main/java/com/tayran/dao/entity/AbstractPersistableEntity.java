package com.tayran.dao.entity;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import lombok.Getter;

import java.time.Instant;

/** created_on / last_updated_on, filled on insert and update (same columns as the reference project). */
@Getter
@MappedSuperclass
public abstract class AbstractPersistableEntity {

    @Column(name = "created_on", nullable = false, updatable = false)
    protected Instant createdOn;

    @Column(name = "last_updated_on", nullable = false)
    protected Instant lastUpdatedOn;

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        createdOn = now;
        lastUpdatedOn = now;
    }

    @PreUpdate
    void onUpdate() {
        lastUpdatedOn = Instant.now();
    }
}
