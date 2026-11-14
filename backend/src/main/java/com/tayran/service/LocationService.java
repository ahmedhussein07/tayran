package com.tayran.service;

import com.tayran.model.LocationsResponse;

public interface LocationService {

    /** The cached locations payload and its ETag. */
    Snapshot getLocations();

    record Snapshot(LocationsResponse body, String etag) {
    }
}
