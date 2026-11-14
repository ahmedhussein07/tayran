package com.tayran.service;

import com.tayran.model.BootstrapResponse;

public interface BootstrapService {

    /** Everything the home screen needs: first name, default address, ETA and the main categories. */
    BootstrapResponse bootstrap(long userId);
}
