package com.tayran.dao.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/** A dark store. Each has its own published catalog (prices and availability differ per store). */
@Getter
@Setter
@Entity
@Table(name = "stores")
public class Store {

    @Id
    private Long id;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "catalog_version", nullable = false)
    private int catalogVersion;

    @Column(name = "catalog_dirty", nullable = false)
    private boolean catalogDirty;
}
