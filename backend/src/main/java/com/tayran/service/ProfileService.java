package com.tayran.service;

import com.tayran.model.AddAddressRequest;
import com.tayran.model.NextStepResponse;
import com.tayran.model.ProfileDtos.SavedAddressDto;
import com.tayran.model.UpdateNameRequest;

import java.util.List;

public interface ProfileService {

    NextStepResponse updateName(long userId, UpdateNameRequest request);

    /** Saves the default address; calling it again replaces it, so retries are safe (onboarding). */
    NextStepResponse saveDefaultAddress(long userId, AddAddressRequest request);

    List<SavedAddressDto> addresses(long userId);

    /** Adds an address; it becomes the default when the customer has none. */
    SavedAddressDto addAddress(long userId, AddAddressRequest request);

    SavedAddressDto updateAddress(long userId, long addressId, AddAddressRequest request);

    /** Soft delete; the last address can't be deleted. Deleting the default promotes the newest other one. */
    void deleteAddress(long userId, long addressId);

    SavedAddressDto setDefaultAddress(long userId, long addressId);

    void updateLanguage(long userId, String language);

    /** Saves this phone's push token for the user (moving it from whoever had it). */
    void registerDevice(long userId, String fcmToken, String platform);

    void unregisterDevice(long userId, String fcmToken);
}
