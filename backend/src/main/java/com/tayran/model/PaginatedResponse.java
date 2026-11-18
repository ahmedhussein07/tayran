package com.tayran.model;

import java.util.List;

/** A page of results (same shape as the reference project's PaginatedResponse). */
public record PaginatedResponse<T>(List<T> data, int page, int totalPages, long totalElements, int numberOfElements) {
}
