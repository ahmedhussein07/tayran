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
import com.tayran.model.ProfileDtos.SavedAddressDto;
import com.tayran.dao.entity.UserDevice;
import com.tayran.dao.repository.UserDeviceRepository;
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
    private final UserDeviceRepository deviceRepository;
    private final java.time.Clock clock;

    @jakarta.persistence.PersistenceContext
    private jakarta.persistence.EntityManager entityManager;

    @Override
    @Transactional
    public NextStepResponse updateName(long userId, UpdateNameRequest request) {
        User user = findUser(userId);
        user.setFirstName(request.getFirstName().strip());
        user.setLastName(request.getLastName().strip());
        userRepository.save(user);
        return new NextStepResponse(nextStepResolver.resolve(user, addressRepository.existsByUserIdAndDefaultAddressTrueAndDeletedAtIsNull(userId)));
    }

    @Override
    @Transactional
    public NextStepResponse saveDefaultAddress(long userId, AddAddressRequest request) {
        User user = findUser(userId);
        Address address = addressRepository.findByUserIdAndDefaultAddressTrueAndDeletedAtIsNull(userId).orElseGet(Address::new);
        apply(address, userId, request);
        address.setDefaultAddress(true);
        addressRepository.save(address);
        return new NextStepResponse(nextStepResolver.resolve(user, true));
    }

    @Override
    @Transactional(readOnly = true)
    public List<SavedAddressDto> addresses(long userId) {
        return addressRepository.findLive(userId).stream().map(SavedAddressDto::of).toList();
    }

    @Override
    @Transactional
    public SavedAddressDto addAddress(long userId, AddAddressRequest request) {
        findUser(userId);
        Address address = new Address();
        apply(address, userId, request);
        address.setDefaultAddress(!addressRepository.existsByUserIdAndDefaultAddressTrueAndDeletedAtIsNull(userId));
        return SavedAddressDto.of(addressRepository.save(address));
    }

    @Override
    @Transactional
    public SavedAddressDto updateAddress(long userId, long addressId, AddAddressRequest request) {
        Address address = live(userId, addressId);
        apply(address, userId, request);
        return SavedAddressDto.of(addressRepository.save(address));
    }

    @Override
    @Transactional
    public void deleteAddress(long userId, long addressId) {
        Address address = live(userId, addressId);
        if (addressRepository.countByUserIdAndDeletedAtIsNull(userId) <= 1) {
            throw new BusinessException(TayranConst.LAST_ADDRESS);
        }
        boolean wasDefault = address.isDefaultAddress();
        address.setDeletedAt(clock.instant());
        address.setDefaultAddress(false);
        addressRepository.saveAndFlush(address);
        if (wasDefault) {
            addressRepository.findLive(userId).stream().findFirst().ifPresent(next -> {
                next.setDefaultAddress(true);
                addressRepository.save(next);
            });
        }
    }

    @Override
    @Transactional
    public SavedAddressDto setDefaultAddress(long userId, long addressId) {
        Address target = live(userId, addressId);
        if (!target.isDefaultAddress()) {
            // Clear the old default first: one default per customer is a unique index.
            addressRepository.findByUserIdAndDefaultAddressTrueAndDeletedAtIsNull(userId).ifPresent(current -> {
                current.setDefaultAddress(false);
                addressRepository.saveAndFlush(current);
            });
            target.setDefaultAddress(true);
            addressRepository.save(target);
        }
        return SavedAddressDto.of(target);
    }

    @Override
    @Transactional
    public void updateLanguage(long userId, String language) {
        User user = findUser(userId);
        user.setPreferredLanguage(language);
        userRepository.save(user);
    }

    @Override
    @Transactional
    public void registerDevice(long userId, String fcmToken, String platform) {
        UserDevice device = deviceRepository.findByFcmToken(fcmToken).orElseGet(UserDevice::new);
        device.setUserId(userId);
        device.setFcmToken(fcmToken);
        device.setPlatform(platform);
        device.setUpdatedAt(clock.instant());
        deviceRepository.save(device);
    }

    @Override
    @Transactional
    public void unregisterDevice(long userId, String fcmToken) {
        deviceRepository.deleteByTokenAndUser(fcmToken, userId);
    }

    private void apply(Address address, long userId, AddAddressRequest request) {
        Village village = villageRepository.findByIdAndActiveTrue(request.getVillageId())
                .orElseThrow(() -> new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of("villageId"))));
        Street street = streetRepository.findByIdAndVillageIdAndActiveTrue(request.getStreetId(), village.getId())
                .orElseThrow(() -> new BusinessException(TayranConst.INVALID_STREET));
        address.setUserId(userId);
        address.setVillage(village);
        address.setStreet(street);
        address.setLandmark(request.getLandmark().strip());
        String label = request.getLabel() == null ? null : request.getLabel().strip();
        address.setLabel(label == null || label.isEmpty() ? null : label);
    }

    private Address live(long userId, long addressId) {
        return addressRepository.findLive(addressId, userId).orElseThrow(() -> new BusinessException(TayranConst.INVALID_ADDRESS));
    }

    private User findUser(long userId) {
        return userRepository.findById(userId).orElseThrow(() -> new BusinessException(TayranConst.UNAUTHORIZED));
    }
}
