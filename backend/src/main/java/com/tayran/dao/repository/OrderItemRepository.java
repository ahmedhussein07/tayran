package com.tayran.dao.repository;

import com.tayran.dao.entity.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {

    List<OrderItem> findByOrderIdOrderBySortOrderAscIdAsc(Long orderId);

    List<OrderItem> findByOrderIdInOrderBySortOrderAscIdAsc(Collection<Long> orderIds);
}
