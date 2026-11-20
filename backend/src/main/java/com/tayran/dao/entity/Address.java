package com.tayran.dao.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "addresses")
public class Address extends AbstractPersistableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "village_id", nullable = false)
    private Village village;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "street_id", nullable = false)
    private Street street;

    @Column(name = "landmark", nullable = false, length = 150)
    private String landmark;

    @Column(name = "is_default", nullable = false)
    private boolean defaultAddress;

    /** Optional, e.g. "home" or "work". */
    @Column(name = "label", length = 30)
    private String label;

    /** Soft delete; past orders keep their own snapshot. */
    @Column(name = "deleted_at")
    private java.time.Instant deletedAt;
}
