package com.tayran.service.impl;

import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.LoadingCache;
import com.tayran.config.properties.AppProperties;
import com.tayran.config.properties.StorageProperties;
import com.tayran.dao.entity.Address;
import com.tayran.dao.entity.Store;
import com.tayran.dao.entity.User;
import com.tayran.dao.repository.AddressRepository;
import com.tayran.dao.repository.CategoryRepository;
import com.tayran.dao.repository.StoreRepository;
import com.tayran.dao.repository.UserRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.BootstrapResponse;
import com.tayran.model.BootstrapResponse.AddressDto;
import com.tayran.model.BootstrapResponse.CatalogRef;
import com.tayran.model.BootstrapResponse.CategoryDto;
import com.tayran.model.BootstrapResponse.ImageTemplates;
import com.tayran.model.ImageKind;
import com.tayran.model.TayranConst;
import com.tayran.service.BootstrapService;
import com.tayran.service.NextStepResolver;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class BootstrapServiceImpl implements BootstrapService {

    /** The store-level part of the bootstrap: the same for every customer of a store. */
    record StorePart(List<CategoryDto> categories, CatalogRef catalog) {
    }

    private final UserRepository userRepository;
    private final AddressRepository addressRepository;
    private final CategoryRepository categoryRepository;
    private final StoreRepository storeRepository;
    private final NextStepResolver nextStepResolver;
    private final StorageProperties storageProperties;
    private final ImageTemplates imageTemplates;
    private final LoadingCache<Long, StorePart> storeParts;

    public BootstrapServiceImpl(UserRepository userRepository, AddressRepository addressRepository,
                                CategoryRepository categoryRepository, StoreRepository storeRepository,
                                NextStepResolver nextStepResolver, StorageProperties storageProperties,
                                AppProperties appProperties) {
        this.userRepository = userRepository;
        this.addressRepository = addressRepository;
        this.categoryRepository = categoryRepository;
        this.storeRepository = storeRepository;
        this.nextStepResolver = nextStepResolver;
        this.storageProperties = storageProperties;
        this.imageTemplates = new ImageTemplates(
                ImageKind.PRODUCT.template(storageProperties.cdnBaseUrl()), ImageKind.PRODUCT.widths(),
                ImageKind.CATEGORY.template(storageProperties.cdnBaseUrl()), ImageKind.CATEGORY.widths());
        // Evicted whenever the store's catalog is republished; the TTL is only a safety net.
        this.storeParts = Caffeine.newBuilder()
                .maximumSize(100)
                .expireAfterWrite(appProperties.categoriesCacheTtl())
                .build(this::loadStorePart);
    }

    @Override
    @Transactional(readOnly = true)
    public BootstrapResponse bootstrap(long userId) {
        User user = userRepository.findById(userId).orElseThrow(() -> new BusinessException(TayranConst.UNAUTHORIZED));
        Optional<Address> address = addressRepository.findDefaultWithLocation(userId);
        long storeId = address.map(a -> a.getVillage().getStoreId()).orElse(CatalogChanges.DEFAULT_STORE_ID);
        StorePart store = storeParts.get(storeId);
        return new BootstrapResponse(
                nextStepResolver.resolve(user, address.isPresent()),
                user.getFirstName(),
                address.map(AddressDto::of).orElse(null),
                TayranConst.ETA_TEXT,
                TayranConst.ETA_MINUTES,
                store.categories(),
                store.catalog(),
                imageTemplates);
    }

    @EventListener
    public void onCatalogPublished(CatalogPublisher.CatalogPublished event) {
        storeParts.invalidate(event.storeId());
    }

    private StorePart loadStorePart(Long storeId) {
        List<CategoryDto> categories = categoryRepository.findByActiveTrueOrderBySortOrderAscIdAsc().stream()
                .map(c -> new CategoryDto(c.getId(), c.getNameAr(), c.getNameEn(), c.getImageHash(), c.getImageBg(), c.getTileColor()))
                .toList();
        CatalogRef catalog = storeRepository.findById(storeId)
                .filter(s -> s.getCatalogVersion() > 0)
                .map(Store::getCatalogVersion)
                .map(v -> new CatalogRef(storeId, v, storageProperties.url(CatalogPublisher.key(storeId, v))))
                .orElse(null);
        return new StorePart(categories, catalog);
    }
}
