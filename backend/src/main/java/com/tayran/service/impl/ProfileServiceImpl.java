package com.tayran.service.impl;

import com.tayran.dao.entity.Address;
import com.tayran.dao.entity.Street;
import com.tayran.dao.entity.User;
import com.tayran.dao.entity.Village;
import com.tayran.dao.repository.AddressRepository;
import com.tayran.dao.repository.StreetRepository;
import com.tayran.dao.repository.UserRepository;
import com.tayran.dao.repository.VillageRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.AddAddressRequest;
import com.tayran.model.NextStepResponse;
import com.tayran.model.TayranConst;
import com.tayran.model.UpdateNameRequest;
import com.tayran.service.NextStepResolver;
import com.tayran.service.ProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ProfileServiceImpl implements ProfileService {

    private final UserRepository userRepository;
    private final AddressRepository addressRepository;
    private final VillageRepository villageRepository;
    private final StreetRepository streetRepository;
    private final NextStepResolver nextStepResolver;

    @Override
    @Transactional
    public NextStepResponse updateName(long userId, UpdateNameRequest request) {
        User user = findUser(userId);
        user.setFirstName(request.getFirstName().strip());
        user.setLastName(request.getLastName().strip());
        userRepository.save(user);
        return new NextStepResponse(nextStepResolver.resolve(user, addressRepository.existsByUserIdAndDefaultAddressTrue(userId)));
    }

    @Override
    @Transactional
    public NextStepResponse saveDefaultAddress(long userId, AddAddressRequest request) {
        User user = findUser(userId);
        Village village = villageRepository.findByIdAndActiveTrue(request.getVillageId())
                .orElseThrow(() -> new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of("villageId"))));
        Street street = streetRepository.findByIdAndVillageIdAndActiveTrue(request.getStreetId(), village.getId())
                .orElseThrow(() -> new BusinessException(TayranConst.INVALID_STREET));

        Address address = addressRepository.findByUserIdAndDefaultAddressTrue(userId).orElseGet(Address::new);
        address.setUserId(userId);
        address.setVillage(village);
        address.setStreet(street);
        address.setLandmark(request.getLandmark().strip());
        address.setDefaultAddress(true);
        addressRepository.save(address);

        return new NextStepResponse(nextStepResolver.resolve(user, true));
    }

    private User findUser(long userId) {
        return userRepository.findById(userId).orElseThrow(() -> new BusinessException(TayranConst.UNAUTHORIZED));
    }
}
