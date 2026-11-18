package com.tayran.dao.repository;

import com.tayran.dao.entity.StoreProduct;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface StoreProductRepository extends JpaRepository<StoreProduct, StoreProduct.Key> {

    List<StoreProduct> findByIdStoreIdAndIdProductIdIn(Long storeId, Collection<Long> productIds);
}
