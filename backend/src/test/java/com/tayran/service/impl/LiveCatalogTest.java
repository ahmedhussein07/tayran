package com.tayran.service.impl;

import com.tayran.config.properties.AppProperties;
import com.tayran.exception.BusinessException;
import com.tayran.service.impl.CatalogPublisher.CatalogJson;
import com.tayran.service.impl.CatalogPublisher.CategoryJson;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Duration;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LiveCatalogTest {

    private CatalogPublisher publisher;
    private LiveCatalog live;

    @BeforeEach
    void setUp() {
        publisher = mock(CatalogPublisher.class);
        AppProperties props = mock(AppProperties.class);
        when(props.categoriesCacheTtl()).thenReturn(Duration.ofHours(1));
        live = new LiveCatalog(publisher, mock(JdbcTemplate.class), props);
        when(publisher.loadCategory(1L, 7L)).thenReturn(new CatalogJson(0, 1L,
                List.of(new CategoryJson(7L, "ألبان", "Dairy", null, null, null)), List.of(), List.of()));
        when(publisher.loadCategory(1L, 8L)).thenReturn(new CatalogJson(0, 1L, List.of(), List.of(), List.of()));
    }

    @Test
    void aCategoryIsLoadedOnceThenServedFromMemory() {
        live.category(1L, 7L);
        live.category(1L, 7L);
        live.category(1L, 7L);
        verify(publisher, times(1)).loadCategory(1L, 7L);
    }

    @Test
    void anAdminEditClearsTheCacheSoTheNextReadReloads() {
        live.category(1L, 7L);
        live.onEdited(new LiveCatalog.CatalogEdited());
        live.category(1L, 7L);
        verify(publisher, times(2)).loadCategory(1L, 7L);
    }

    @Test
    void aHiddenCategoryIsNotFoundAndThatIsCachedToo() {
        assertThatThrownBy(() -> live.category(1L, 8L)).isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> live.category(1L, 8L)).isInstanceOf(BusinessException.class);
        verify(publisher, times(1)).loadCategory(1L, 8L);
    }

    @Test
    void tooManyIdsAreRejected() {
        assertThatThrownBy(() -> live.products(1L, java.util.stream.LongStream.rangeClosed(1, 101).boxed().toList()))
                .isInstanceOf(BusinessException.class);
    }
}
