package com.tayran.service.impl;

import com.tayran.config.properties.StorageProperties;
import com.tayran.dao.entity.Category;
import com.tayran.dao.entity.ImageRecord;
import com.tayran.dao.entity.Subcategory;
import com.tayran.dao.repository.CategoryRepository;
import com.tayran.dao.repository.ProductRepository;
import com.tayran.dao.repository.SubcategoryRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.ImageKind;
import com.tayran.model.TayranConst;
import com.tayran.model.admin.CatalogDtos.AdminCategoryDto;
import com.tayran.model.admin.CatalogDtos.AdminSubcategoryDto;
import com.tayran.model.admin.CatalogDtos.CategoryRequest;
import com.tayran.model.admin.CatalogDtos.SubcategoryRequest;
import com.tayran.service.AdminCatalogService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminCatalogServiceImpl implements AdminCatalogService {

    private final CategoryRepository categoryRepository;
    private final SubcategoryRepository subcategoryRepository;
    private final ProductRepository productRepository;
    private final CatalogChanges changes;
    private final StorageProperties storageProperties;

    // ---- categories ------------------------------------------------------------------------

    @Override
    @Transactional(readOnly = true)
    public List<AdminCategoryDto> listCategories() {
        Map<Long, Long> products = toCounts(productRepository.countLiveByCategory());
        Map<Long, Long> subcategories = subcategoryRepository.findAll().stream()
                .collect(Collectors.groupingBy(Subcategory::getCategoryId, Collectors.counting()));
        return categoryRepository.findAllByOrderBySortOrderAscIdAsc().stream()
                .map(c -> toDto(c, subcategories.getOrDefault(c.getId(), 0L), products.getOrDefault(c.getId(), 0L)))
                .toList();
    }

    @Override
    @Transactional
    public AdminCategoryDto createCategory(CategoryRequest request) {
        Category category = new Category();
        apply(category, request);
        category.setSortOrder(categoryRepository.maxSortOrder() + 1);
        category.setActive(true);
        categoryRepository.save(category);
        changes.markDirty();
        return toDto(category, 0, 0);
    }

    @Override
    @Transactional
    public AdminCategoryDto updateCategory(long id, CategoryRequest request) {
        Category category = findCategory(id);
        apply(category, request);
        categoryRepository.save(category);
        changes.markDirty();
        return dtoWithCounts(category);
    }

    @Override
    @Transactional
    public AdminCategoryDto setCategoryActive(long id, boolean active) {
        Category category = findCategory(id);
        category.setActive(active);
        categoryRepository.save(category);
        changes.markDirty();
        return dtoWithCounts(category);
    }

    @Override
    @Transactional
    public List<AdminCategoryDto> reorderCategories(List<Long> ids) {
        Map<Long, Category> byId = categoryRepository.findAllById(ids).stream()
                .collect(Collectors.toMap(Category::getId, Function.identity()));
        if (byId.size() != ids.size() || new HashSet<>(ids).size() != ids.size()) {
            throw new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of("ids")));
        }
        for (int i = 0; i < ids.size(); i++) {
            byId.get(ids.get(i)).setSortOrder(i + 1);
        }
        categoryRepository.saveAll(byId.values());
        changes.markDirty();
        return listCategories();
    }

    @Override
    @Transactional
    public void deleteCategory(long id) {
        Category category = findCategory(id);
        if (subcategoryRepository.existsByCategoryId(id)) {
            throw new BusinessException(TayranConst.CATEGORY_NOT_EMPTY);
        }
        categoryRepository.delete(category);
        changes.markDirty();
    }

    // ---- subcategories ---------------------------------------------------------------------

    @Override
    @Transactional(readOnly = true)
    public List<AdminSubcategoryDto> listSubcategories(long categoryId) {
        findCategory(categoryId);
        Map<Long, Long> products = toCounts(productRepository.countLiveBySubcategory(categoryId));
        return subcategoryRepository.findByCategoryIdOrderBySortOrderAscIdAsc(categoryId).stream()
                .map(s -> toDto(s, products.getOrDefault(s.getId(), 0L)))
                .toList();
    }

    @Override
    @Transactional
    public AdminSubcategoryDto createSubcategory(long categoryId, SubcategoryRequest request) {
        findCategory(categoryId);
        Subcategory subcategory = new Subcategory();
        subcategory.setCategoryId(categoryId);
        subcategory.setNameAr(request.nameAr().strip());
        subcategory.setNameEn(request.nameEn().strip());
        subcategory.setSortOrder(subcategoryRepository.maxSortOrder(categoryId) + 1);
        subcategory.setActive(true);
        subcategoryRepository.save(subcategory);
        changes.markDirty();
        return toDto(subcategory, 0);
    }

    @Override
    @Transactional
    public AdminSubcategoryDto updateSubcategory(long categoryId, long id, SubcategoryRequest request) {
        Subcategory subcategory = findSubcategory(categoryId, id);
        subcategory.setNameAr(request.nameAr().strip());
        subcategory.setNameEn(request.nameEn().strip());
        subcategoryRepository.save(subcategory);
        changes.markDirty();
        return subcategoryDtoWithCount(subcategory);
    }

    @Override
    @Transactional
    public AdminSubcategoryDto setSubcategoryActive(long categoryId, long id, boolean active) {
        Subcategory subcategory = findSubcategory(categoryId, id);
        subcategory.setActive(active);
        subcategoryRepository.save(subcategory);
        changes.markDirty();
        return subcategoryDtoWithCount(subcategory);
    }

    @Override
    @Transactional
    public List<AdminSubcategoryDto> reorderSubcategories(long categoryId, List<Long> ids) {
        findCategory(categoryId);
        Map<Long, Subcategory> byId = subcategoryRepository.findAllById(ids).stream()
                .filter(s -> s.getCategoryId() == categoryId)
                .collect(Collectors.toMap(Subcategory::getId, Function.identity()));
        if (byId.size() != ids.size() || new HashSet<>(ids).size() != ids.size()) {
            throw new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of("ids")));
        }
        for (int i = 0; i < ids.size(); i++) {
            byId.get(ids.get(i)).setSortOrder(i + 1);
        }
        subcategoryRepository.saveAll(byId.values());
        changes.markDirty();
        return listSubcategories(categoryId);
    }

    @Override
    @Transactional
    public void deleteSubcategory(long categoryId, long id) {
        Subcategory subcategory = findSubcategory(categoryId, id);
        if (productRepository.existsBySubcategoryId(id)) {
            // Soft-deleted products count: orders may still reference them. Deactivating is always allowed.
            throw new BusinessException(TayranConst.SUBCATEGORY_NOT_EMPTY);
        }
        subcategoryRepository.delete(subcategory);
        changes.markDirty();
    }

    // ---- helpers ---------------------------------------------------------------------------

    private void apply(Category category, CategoryRequest request) {
        category.setNameAr(request.nameAr().strip());
        category.setNameEn(request.nameEn().strip());
        category.setTileColor(request.tileColor());
        ImageRecord image = changes.image(request.imageHash(), ImageKind.CATEGORY);
        category.setImageHash(image == null ? null : image.getHash());
        category.setImageBg(image == null ? null : image.getBg());
    }

    private Category findCategory(long id) {
        return categoryRepository.findById(id).orElseThrow(() -> new BusinessException(TayranConst.NOT_FOUND));
    }

    private Subcategory findSubcategory(long categoryId, long id) {
        return subcategoryRepository.findById(id).filter(s -> s.getCategoryId() == categoryId)
                .orElseThrow(() -> new BusinessException(TayranConst.NOT_FOUND));
    }

    private AdminCategoryDto dtoWithCounts(Category c) {
        long subcategories = subcategoryRepository.findByCategoryIdOrderBySortOrderAscIdAsc(c.getId()).size();
        long products = toCounts(productRepository.countLiveByCategory()).getOrDefault(c.getId(), 0L);
        return toDto(c, subcategories, products);
    }

    private AdminSubcategoryDto subcategoryDtoWithCount(Subcategory s) {
        long products = toCounts(productRepository.countLiveBySubcategory(s.getCategoryId())).getOrDefault(s.getId(), 0L);
        return toDto(s, products);
    }

    private AdminCategoryDto toDto(Category c, long subcategories, long products) {
        String url = c.getImageHash() == null ? null : storageProperties.url(ImageKind.CATEGORY.previewKey(c.getImageHash()));
        return new AdminCategoryDto(c.getId(), c.getNameAr(), c.getNameEn(), c.getTileColor(), c.getImageHash(), c.getImageBg(),
                url, c.getSortOrder(), c.isActive(), subcategories, products);
    }

    private static AdminSubcategoryDto toDto(Subcategory s, long products) {
        return new AdminSubcategoryDto(s.getId(), s.getCategoryId(), s.getNameAr(), s.getNameEn(), s.getSortOrder(), s.isActive(), products);
    }

    private static Map<Long, Long> toCounts(List<Object[]> rows) {
        Map<Long, Long> counts = new HashMap<>();
        for (Object[] row : rows) {
            counts.put(((Number) row[0]).longValue(), ((Number) row[1]).longValue());
        }
        return counts;
    }
}
