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
    private final StoreSettingsService settingsService;
    private final com.tayran.service.OrderService orderService;
    private final boolean onlinePaymentEnabled;

    public BootstrapServiceImpl(UserRepository userRepository, AddressRepository addressRepository,
                                CategoryRepository categoryRepository, StoreRepository storeRepository,
                                NextStepResolver nextStepResolver, StorageProperties storageProperties,
                                AppProperties appProperties, StoreSettingsService settingsService,
                                com.tayran.service.OrderService orderService,
                                @org.springframework.beans.factory.annotation.Value("${payments.online.enabled:false}") boolean onlinePaymentEnabled) {
        this.settingsService = settingsService;
        this.orderService = orderService;
        this.onlinePaymentEnabled = onlinePaymentEnabled;
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
        var settings = settingsService.get(storeId);
        return new BootstrapResponse(
                nextStepResolver.resolve(user, address.isPresent()),
                user.getFirstName(),
                user.getLastName(),
                user.getPhone(),
                user.getPreferredLanguage(),
                address.map(AddressDto::of).orElse(null),
                arabicDigits(settings.getEtaMinutes()) + " دقيقة",
                settings.getEtaMinutes(),
                store.categories(),
                store.catalog(),
                imageTemplates,
                StoreSettingsService.StoreSettingsDto.of(settings),
                addressRepository.findLive(userId).stream().map(com.tayran.model.ProfileDtos.SavedAddressDto::of).toList(),
                orderService.active(userId),
                onlinePaymentEnabled);
    }

    private static String arabicDigits(int value) {
        StringBuilder sb = new StringBuilder();
        for (char c : String.valueOf(value).toCharArray()) {
            sb.append((char) ('٠' + (c - '0')));
        }
        return sb.toString();
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
