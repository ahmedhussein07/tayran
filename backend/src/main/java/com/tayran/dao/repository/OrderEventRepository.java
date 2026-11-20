package com.tayran.dao.repository;

import com.tayran.dao.entity.OrderEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface OrderEventRepository extends JpaRepository<OrderEvent, Long> {

    List<OrderEvent> findByOrderIdOrderByAtAscIdAsc(Long orderId);

    List<OrderEvent> findByOrderIdInOrderByAtAscIdAsc(Collection<Long> orderIds);
}
