package com.tayran.dao.entity;

import com.tayran.model.ImageKind;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

/** One normalized image, by content hash. Its WebP variants live in object storage. */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "images")
public class ImageRecord {

    @Id
    @Column(name = "hash", length = 12)
    private String hash;

    @Enumerated(EnumType.STRING)
    @Column(name = "kind", nullable = false, length = 16)
    private ImageKind kind;

    @Column(name = "bg", nullable = false, length = 7)
    private String bg;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "last_referenced_at", nullable = false)
    private Instant lastReferencedAt;
}
