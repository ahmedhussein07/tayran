package com.tayran.service.impl;

import com.tayran.dao.entity.CatalogPublication;
import com.tayran.dao.entity.Store;
import com.tayran.dao.repository.CatalogPublicationRepository;
import com.tayran.dao.repository.StoreRepository;
import com.tayran.integration.storage.ObjectStorage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.SimpleTransactionStatus;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CatalogPublisherTest {

    private static final Instant NOW = Instant.parse("2026-11-10T12:00:00Z");

    private StoreRepository stores;
    private CatalogPublicationRepository publications;
    private ObjectStorage storage;
    private PlatformTransactionManager txManager;
    private ApplicationEventPublisher events;
    private CatalogPublisher publisher;
    private Store store;

    @BeforeEach
    void setUp() {
        stores = mock(StoreRepository.class);
        publications = mock(CatalogPublicationRepository.class);
        storage = mock(ObjectStorage.class);
        txManager = mock(PlatformTransactionManager.class);
        when(txManager.getTransaction(any())).thenReturn(new SimpleTransactionStatus());
        events = mock(ApplicationEventPublisher.class);
        publisher = new CatalogPublisher(stores, publications, storage, mock(JdbcTemplate.class), JsonMapper.builder().build(),
                txManager, events, Clock.fixed(NOW, ZoneOffset.UTC), false);

        store = new Store();
        store.setId(1L);
        store.setName("main");
        store.setCatalogVersion(4);
        store.setCatalogDirty(true);
        when(stores.findByIdForUpdate(1L)).thenReturn(Optional.of(store));
        when(stores.findByCatalogDirtyTrue()).thenReturn(List.of(store));
    }

    @Test
    void failedWriteLeavesVersionAndDirtyFlagAloneAndRollsBack() {
        doThrow(new IllegalStateException("R2 down")).when(storage).put(anyString(), any(), anyString(), anyString());

        assertThatThrownBy(() -> publisher.publish(1L)).isInstanceOf(IllegalStateException.class);

        assertThat(store.getCatalogVersion()).isEqualTo(4);
        assertThat(store.isCatalogDirty()).isTrue();
        verify(publications, never()).save(any());
        verify(stores, never()).save(any());
        verify(events, never()).publishEvent(any(Object.class));
        verify(txManager).rollback(any());
    }

    @Test
    void publishDirtySwallowsTheFailureSoTheStoreIsRetriedNextRun() {
        doThrow(new IllegalStateException("R2 down")).when(storage).put(anyString(), any(), anyString(), anyString());
        assertThat(publisher.publishDirty()).isZero();
        assertThat(store.isCatalogDirty()).isTrue();
    }

    @Test
    void successfulWriteBumpsTheVersionClearsDirtyAndAnnouncesIt() {
        assertThat(publisher.publish(1L)).isTrue();

        verify(storage).put(eq("catalog/store-1/v5.json"), any(), eq("application/json"), eq(ObjectStorage.IMMUTABLE));
        assertThat(store.getCatalogVersion()).isEqualTo(5);
        assertThat(store.isCatalogDirty()).isFalse();
        verify(publications).save(any(CatalogPublication.class));
        verify(events).publishEvent(new CatalogPublisher.CatalogPublished(1L, 5));
        verify(txManager).commit(any());
    }

    @Test
    void cleanStoreIsNotRepublished() {
        store.setCatalogDirty(false);
        assertThat(publisher.publish(1L)).isFalse();
        verify(storage, never()).put(anyString(), any(), anyString(), anyString());
        assertThat(store.getCatalogVersion()).isEqualTo(4);
    }

    @Test
    void versionsOlderThanSevenDaysAreDeleted() {
        CatalogPublication old = new CatalogPublication(new CatalogPublication.Key(1L, 1), "catalog/store-1/v1.json",
                NOW.minus(Duration.ofDays(8)), null);
        when(publications.findByIdStoreIdAndDeletedAtIsNullAndPublishedAtBefore(1L, NOW.minus(Duration.ofDays(7))))
                .thenReturn(List.of(old));

        publisher.publish(1L);

        verify(storage).delete("catalog/store-1/v1.json");
        assertThat(old.getDeletedAt()).isEqualTo(NOW);
    }

    @Test
    void pricesAreWrittenWithoutTrailingZeros() {
        assertThat(CatalogPublisher.number(new BigDecimal("15.00"))).isEqualTo(15L);
        assertThat(CatalogPublisher.number(new BigDecimal("12.50"))).isEqualTo(12.5);
        assertThat(CatalogPublisher.number(new BigDecimal("100"))).isEqualTo(100L);
        assertThat(CatalogPublisher.number(null)).isNull();
    }
}
