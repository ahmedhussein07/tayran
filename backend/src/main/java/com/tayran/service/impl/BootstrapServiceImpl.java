package com.tayran.service.impl;

import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.LoadingCache;
import com.tayran.config.properties.AppProperties;
import com.tayran.dao.entity.Address;
import com.tayran.dao.entity.User;
import com.tayran.dao.repository.AddressRepository;
import com.tayran.dao.repository.CategoryRepository;
import com.tayran.dao.repository.UserRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.BootstrapResponse;
import com.tayran.model.BootstrapResponse.AddressDto;
import com.tayran.model.BootstrapResponse.CategoryDto;
import com.tayran.model.TayranConst;
import com.tayran.service.BootstrapService;
import com.tayran.service.NextStepResolver;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class BootstrapServiceImpl implements BootstrapService {

    private final UserRepository userRepository;
    private final AddressRepository addressRepository;
    private final CategoryRepository categoryRepository;
    private final NextStepResolver nextStepResolver;
    /** The main categories rarely change, so they are cached in memory. */
    private final LoadingCache<String, List<CategoryDto>> categoriesCache;

    public BootstrapServiceImpl(UserRepository userRepository, AddressRepository addressRepository,
                                CategoryRepository categoryRepository, NextStepResolver nextStepResolver,
                                AppProperties appProperties) {
        this.userRepository = userRepository;
        this.addressRepository = addressRepository;
        this.categoryRepository = categoryRepository;
        this.nextStepResolver = nextStepResolver;
        this.categoriesCache = Caffeine.newBuilder()
                .maximumSize(1)
                .expireAfterWrite(appProperties.categoriesCacheTtl())
                .build(key -> categoryRepository.findByActiveTrueOrderBySortOrderAscIdAsc().stream()
                        .map(CategoryDto::new).toList());
    }

    @Override
    @Transactional(readOnly = true)
    public BootstrapResponse bootstrap(long userId) {
        User user = userRepository.findById(userId).orElseThrow(() -> new BusinessException(TayranConst.UNAUTHORIZED));
        Optional<Address> address = addressRepository.findDefaultWithLocation(userId);
        return new BootstrapResponse(
                nextStepResolver.resolve(user, address.isPresent()),
                user.getFirstName(),
                address.map(AddressDto::new).orElse(null),
                TayranConst.ETA_TEXT,
                TayranConst.ETA_MINUTES,
                categoriesCache.get("main"));
    }
}
