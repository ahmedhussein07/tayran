package com.tayran.service.impl;

import com.tayran.config.properties.StorageProperties;
import com.tayran.dao.entity.ImageRecord;
import com.tayran.dao.entity.Product;
import com.tayran.dao.entity.StoreProduct;
import com.tayran.dao.entity.Subcategory;
import com.tayran.dao.repository.ProductRepository;
import com.tayran.dao.repository.StoreProductRepository;
import com.tayran.dao.repository.SubcategoryRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.ImageKind;
import com.tayran.model.PaginatedResponse;
import com.tayran.model.TayranConst;
import com.tayran.model.admin.CatalogDtos.AdminProductDto;
import com.tayran.model.admin.CatalogDtos.ProductFilter;
import com.tayran.model.admin.CatalogDtos.ProductRequest;
import com.tayran.service.AdminProductService;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Subquery;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminProductServiceImpl implements AdminProductService {

    private static final long STORE = CatalogChanges.DEFAULT_STORE_ID;
    private static final int MAX_PAGE_SIZE = 100;

    private final ProductRepository productRepository;
    private final SubcategoryRepository subcategoryRepository;
    private final StoreProductRepository storeProductRepository;
    private final CatalogChanges changes;
    private final StorageProperties storageProperties;
    private final Clock clock;

    @Override
    @Transactional(readOnly = true)
    public PaginatedResponse<AdminProductDto> list(ProductFilter f) {
        int size = Math.min(Math.max(f.size(), 1), MAX_PAGE_SIZE);
        int page = Math.max(f.page(), 0);
        Page<Product> result = productRepository.findAll(spec(f), PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "id")));
        List<AdminProductDto> rows = toDtos(result.getContent());
        return new PaginatedResponse<>(rows, page, result.getTotalPages(), result.getTotalElements(), result.getNumberOfElements());
    }

    @Override
    @Transactional(readOnly = true)
    public AdminProductDto get(long id) {
        return toDtos(List.of(find(id))).getFirst();
    }

    @Override
    @Transactional
    public AdminProductDto create(ProductRequest request) {
        Product product = new Product();
        apply(product, request);
        product.setSortOrder(productRepository.maxSortOrder(product.getSubcategoryId()) + 1);
        productRepository.save(product);
        savePrice(product.getId(), request);
        changes.markDirty();
        return get(product.getId());
    }

    @Override
    @Transactional
    public AdminProductDto update(long id, ProductRequest request) {
        Product product = find(id);
        long oldSubcategory = product.getSubcategoryId();
        apply(product, request);
        if (oldSubcategory != product.getSubcategoryId()) {
            product.setSortOrder(productRepository.maxSortOrder(product.getSubcategoryId()) + 1);
        }
        productRepository.save(product);
        savePrice(product.getId(), request);
        changes.markDirty();
        return get(product.getId());
    }

    @Override
    @Transactional
    public void delete(long id) {
        Product product = find(id);
        product.setDeletedAt(clock.instant());
        productRepository.save(product);
        changes.markDirty();
    }

    // ---- helpers ---------------------------------------------------------------------------

    private void apply(Product product, ProductRequest r) {
        if (!subcategoryRepository.existsById(r.subcategoryId())) {
            throw new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of("subcategoryId")));
        }
        if (r.oldPrice() != null && r.oldPrice().compareTo(r.price()) <= 0) {
            throw new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of("oldPrice")));
        }
        product.setSubcategoryId(r.subcategoryId());
        product.setNameAr(r.nameAr().strip());
        product.setNameEn(r.nameEn().strip());
        product.setSizeLabel(r.sizeLabel().strip());
        product.setDescription(blankToNull(r.description()));
        product.setIngredients(blankToNull(r.ingredients()));
        product.setActive(r.active());
        ImageRecord image = changes.image(r.imageHash(), ImageKind.PRODUCT);
        product.setImageHash(image == null ? null : image.getHash());
        product.setImageBg(image == null ? null : image.getBg());
    }

    private void savePrice(long productId, ProductRequest r) {
        StoreProduct price = storeProductRepository.findById(new StoreProduct.Key(STORE, productId))
                .orElseGet(() -> new StoreProduct(STORE, productId));
        price.setPrice(r.price());
        price.setOldPrice(r.oldPrice());
        price.setAvailable(r.available());
        storeProductRepository.save(price);
    }

    private Product find(long id) {
        return productRepository.findByIdAndDeletedAtIsNull(id).orElseThrow(() -> new BusinessException(TayranConst.NOT_FOUND));
    }

    private List<AdminProductDto> toDtos(List<Product> products) {
        if (products.isEmpty()) {
            return List.of();
        }
        List<Long> ids = products.stream().map(Product::getId).toList();
        Map<Long, StoreProduct> prices = storeProductRepository.findByIdStoreIdAndIdProductIdIn(STORE, ids).stream()
                .collect(Collectors.toMap(sp -> sp.getId().getProductId(), Function.identity()));
        Map<Long, Long> categoryOf = subcategoryRepository
                .findAllById(products.stream().map(Product::getSubcategoryId).distinct().toList()).stream()
                .collect(Collectors.toMap(Subcategory::getId, Subcategory::getCategoryId));
        return products.stream().map(p -> {
            StoreProduct sp = prices.get(p.getId());
            String url = p.getImageHash() == null ? null : storageProperties.url(ImageKind.PRODUCT.previewKey(p.getImageHash()));
            return new AdminProductDto(p.getId(), p.getSubcategoryId(), categoryOf.getOrDefault(p.getSubcategoryId(), 0L),
                    p.getNameAr(), p.getNameEn(), p.getSizeLabel(), p.getDescription(), p.getIngredients(),
                    p.getImageHash(), p.getImageBg(), url, p.isActive(), p.getSortOrder(),
                    sp == null ? null : sp.getPrice(), sp == null ? null : sp.getOldPrice(), sp != null && sp.isAvailable(),
                    p.getCreatedOn(), p.getLastUpdatedOn());
        }).toList();
    }

    /** Never shows soft-deleted products; every filter is optional. */
    private static Specification<Product> spec(ProductFilter f) {
        return (root, query, cb) -> {
            List<Predicate> where = new ArrayList<>();
            where.add(cb.isNull(root.get("deletedAt")));
            if (f.q() != null && !f.q().isBlank()) {
                String like = "%" + f.q().strip().toLowerCase(Locale.ROOT) + "%";
                where.add(cb.or(cb.like(cb.lower(root.get("nameAr")), like), cb.like(cb.lower(root.get("nameEn")), like)));
            }
            if (f.subcategoryId() != null) {
                where.add(cb.equal(root.get("subcategoryId"), f.subcategoryId()));
            }
            if (f.categoryId() != null) {
                Subquery<Long> subs = query.subquery(Long.class);
                var s = subs.from(Subcategory.class);
                subs.select(s.get("id")).where(cb.equal(s.get("categoryId"), f.categoryId()));
                where.add(root.get("subcategoryId").in(subs));
            }
            if (f.active() != null) {
                where.add(cb.equal(root.get("active"), f.active()));
            }
            if (f.available() != null) {
                Subquery<Long> priced = query.subquery(Long.class);
                var sp = priced.from(StoreProduct.class);
                priced.select(sp.get("id").get("productId")).where(
                        cb.equal(sp.get("id").get("storeId"), STORE),
                        cb.equal(sp.get("available"), true));
                where.add(f.available() ? root.get("id").in(priced) : cb.not(root.get("id").in(priced)));
            }
            return cb.and(where.toArray(Predicate[]::new));
        };
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.strip();
    }
}
