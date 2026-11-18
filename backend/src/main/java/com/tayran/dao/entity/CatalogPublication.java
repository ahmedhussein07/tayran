package com.tayran.dao.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;
import java.time.Instant;

/** One published catalog file, kept so old versions can be deleted without listing the bucket. */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "catalog_publications")
public class CatalogPublication {

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    @Embeddable
    public static class Key implements Serializable {
        @Column(name = "store_id")
        private Long storeId;

        @Column(name = "version")
        private Integer version;
    }

    @EmbeddedId
    private Key id;

    @Column(name = "object_key", nullable = false)
    private String objectKey;

    @Column(name = "published_at", nullable = false)
    private Instant publishedAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;
}
