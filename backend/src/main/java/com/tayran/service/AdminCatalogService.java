package com.tayran.service;

import com.tayran.model.admin.CatalogDtos.AdminCategoryDto;
import com.tayran.model.admin.CatalogDtos.AdminSubcategoryDto;
import com.tayran.model.admin.CatalogDtos.CategoryRequest;
import com.tayran.model.admin.CatalogDtos.SubcategoryRequest;

import java.util.List;

/** Categories and subcategories. Deleting is allowed only when empty; deactivating always is. */
public interface AdminCatalogService {

    List<AdminCategoryDto> listCategories();

    AdminCategoryDto createCategory(CategoryRequest request);

    AdminCategoryDto updateCategory(long id, CategoryRequest request);

    AdminCategoryDto setCategoryActive(long id, boolean active);

    List<AdminCategoryDto> reorderCategories(List<Long> ids);

    void deleteCategory(long id);

    List<AdminSubcategoryDto> listSubcategories(long categoryId);

    AdminSubcategoryDto createSubcategory(long categoryId, SubcategoryRequest request);

    AdminSubcategoryDto updateSubcategory(long categoryId, long id, SubcategoryRequest request);

    AdminSubcategoryDto setSubcategoryActive(long categoryId, long id, boolean active);

    List<AdminSubcategoryDto> reorderSubcategories(long categoryId, List<Long> ids);

    void deleteSubcategory(long categoryId, long id);
}
