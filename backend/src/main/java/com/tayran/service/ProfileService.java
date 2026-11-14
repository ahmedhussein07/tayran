package com.tayran.service;

import com.tayran.model.AddAddressRequest;
import com.tayran.model.NextStepResponse;
import com.tayran.model.UpdateNameRequest;

public interface ProfileService {

    NextStepResponse updateName(long userId, UpdateNameRequest request);

    /** Saves the default address; calling it again replaces it, so retries are safe. */
    NextStepResponse saveDefaultAddress(long userId, AddAddressRequest request);
}
