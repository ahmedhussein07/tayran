package com.tayran.service;

import com.tayran.model.PaginatedResponse;
import com.tayran.model.admin.CatalogDtos.AdminProductDto;
import com.tayran.model.admin.CatalogDtos.ProductFilter;
import com.tayran.model.admin.CatalogDtos.ProductRequest;

/** Products and their price, old price and availability in the (single) store. */
public interface AdminProductService {

    PaginatedResponse<AdminProductDto> list(ProductFilter filter);

    AdminProductDto get(long id);

    AdminProductDto create(ProductRequest request);

    AdminProductDto update(long id, ProductRequest request);

    /** Soft delete: hidden everywhere, kept for future order history. */
    void delete(long id);
}
