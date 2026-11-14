package com.tayran.service.impl;

import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.LoadingCache;
import com.tayran.config.properties.AppProperties;
import com.tayran.dao.repository.StreetRepository;
import com.tayran.dao.repository.VillageRepository;
import com.tayran.model.LocationsResponse;
import com.tayran.model.LocationsResponse.StreetDto;
import com.tayran.model.LocationsResponse.VillageDto;
import com.tayran.service.LocationService;
import com.tayran.utils.HashUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Villages and streets rarely change: they are loaded once into an in-memory Caffeine cache,
 * with an ETag computed from the payload so the app can revalidate cheaply.
 */
@Service
public class LocationServiceImpl implements LocationService {

    private static final String KEY = "locations";

    private final VillageRepository villageRepository;
    private final StreetRepository streetRepository;
    private final ObjectMapper objectMapper;
    private final TransactionTemplate readOnlyTx;
    private final LoadingCache<String, Snapshot> cache;

    public LocationServiceImpl(VillageRepository villageRepository, StreetRepository streetRepository,
                               ObjectMapper objectMapper, PlatformTransactionManager transactionManager,
                               AppProperties appProperties) {
        this.villageRepository = villageRepository;
        this.streetRepository = streetRepository;
        this.objectMapper = objectMapper;
        this.readOnlyTx = new TransactionTemplate(transactionManager);
        this.readOnlyTx.setReadOnly(true);
        this.cache = Caffeine.newBuilder()
                .maximumSize(1)
                .expireAfterWrite(appProperties.locationsCacheTtl())
                .build(key -> load());
    }

    @Override
    public Snapshot getLocations() {
        return cache.get(KEY);
    }

    private Snapshot load() {
        LocationsResponse body = readOnlyTx.execute(status -> {
            Map<Long, List<StreetDto>> streetsByVillage = streetRepository.findByActiveTrueOrderBySortOrderAscIdAsc().stream()
                    .collect(Collectors.groupingBy(street -> street.getVillageId(),
                            Collectors.mapping(StreetDto::new, Collectors.toList())));
            List<VillageDto> villages = villageRepository.findByActiveTrueOrderBySortOrderAscIdAsc().stream()
                    .map(village -> new VillageDto(village, streetsByVillage.getOrDefault(village.getId(), List.of())))
                    .toList();
            return new LocationsResponse(villages);
        });
        String etag = "\"" + HashUtils.sha256Hex(objectMapper.writeValueAsString(body)).substring(0, 32) + "\"";
        return new Snapshot(body, etag);
    }
}
