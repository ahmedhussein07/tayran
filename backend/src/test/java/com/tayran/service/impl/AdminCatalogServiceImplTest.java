package com.tayran.service.impl;

import com.tayran.config.properties.StorageProperties;
import com.tayran.dao.entity.Category;
import com.tayran.dao.entity.Subcategory;
import com.tayran.dao.repository.CategoryRepository;
import com.tayran.dao.repository.ProductRepository;
import com.tayran.dao.repository.SubcategoryRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** The delete rules: only empty categories and subcategories can be deleted. */
class AdminCatalogServiceImplTest {

    private CategoryRepository categories;
    private SubcategoryRepository subcategories;
    private ProductRepository products;
    private CatalogChanges changes;
    private AdminCatalogServiceImpl service;

    @BeforeEach
    void setUp() {
        categories = mock(CategoryRepository.class);
        subcategories = mock(SubcategoryRepository.class);
        products = mock(ProductRepository.class);
        changes = mock(CatalogChanges.class);
        service = new AdminCatalogServiceImpl(categories, subcategories, products, changes, new StorageProperties("https://cdn", null));

        Category category = new Category();
        category.setId(7L);
        when(categories.findById(7L)).thenReturn(Optional.of(category));
        Subcategory subcategory = new Subcategory();
        subcategory.setId(70L);
        subcategory.setCategoryId(7L);
        when(subcategories.findById(70L)).thenReturn(Optional.of(subcategory));
    }

    @Test
    void categoryWithSubcategoriesCannotBeDeleted() {
        when(subcategories.existsByCategoryId(7L)).thenReturn(true);
        assertCode(() -> service.deleteCategory(7L), TayranConst.CATEGORY_NOT_EMPTY);
        verify(categories, never()).delete(any());
        verify(changes, never()).markDirty();
    }

    @Test
    void emptyCategoryIsDeletedAndTheCatalogMarkedDirty() {
        when(subcategories.existsByCategoryId(7L)).thenReturn(false);
        service.deleteCategory(7L);
        verify(categories).delete(any(Category.class));
        verify(changes).markDirty();
    }

    @Test
    void subcategoryWithProductsCannotBeDeletedEvenIfTheyAreSoftDeleted() {
        // existsBySubcategoryId ignores deleted_at on purpose.
        when(products.existsBySubcategoryId(70L)).thenReturn(true);
        assertCode(() -> service.deleteSubcategory(7L, 70L), TayranConst.SUBCATEGORY_NOT_EMPTY);
        verify(subcategories, never()).delete(any());
    }

    @Test
    void emptySubcategoryIsDeleted() {
        when(products.existsBySubcategoryId(70L)).thenReturn(false);
        service.deleteSubcategory(7L, 70L);
        verify(subcategories).delete(any(Subcategory.class));
        verify(changes).markDirty();
    }

    @Test
    void subcategoryOfAnotherCategoryIsNotFound() {
        when(categories.findById(8L)).thenReturn(Optional.of(new Category()));
        assertCode(() -> service.deleteSubcategory(8L, 70L), TayranConst.NOT_FOUND);
        assertCode(() -> service.deleteCategory(99L), TayranConst.NOT_FOUND);
    }

    private static void assertCode(Runnable call, String code) {
        assertThatThrownBy(call::run).isInstanceOfSatisfying(BusinessException.class,
                e -> org.assertj.core.api.Assertions.assertThat(e.getCode()).isEqualTo(code));
    }
}
