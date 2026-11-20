package com.tayran.dao.repository;

import com.tayran.dao.entity.Order;
import com.tayran.model.order.OrderStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/** Reads only; every write after creation goes through {@code OrderWriter}'s conditional updates. */
@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    Optional<Order> findByIdAndUserId(Long id, Long userId);

    Optional<Order> findByUserIdAndIdempotencyKey(Long userId, String idempotencyKey);

    /** The customer's orders, newest first (first page). */
    @Query("SELECT o FROM Order o WHERE o.userId = :userId ORDER BY o.createdAt DESC, o.id DESC")
    List<Order> findFirstPage(@Param("userId") Long userId, Pageable pageable);

    /** The next page after the cursor (created_at, id). */
    @Query("""
            SELECT o FROM Order o WHERE o.userId = :userId
              AND (o.createdAt < :beforeAt OR (o.createdAt = :beforeAt AND o.id < :beforeId))
            ORDER BY o.createdAt DESC, o.id DESC
            """)
    List<Order> findPageBefore(@Param("userId") Long userId, @Param("beforeAt") Instant beforeAt, @Param("beforeId") Long beforeId,
                               Pageable pageable);

    List<Order> findByUserIdAndStatusInOrderByCreatedAtDesc(Long userId, Collection<OrderStatus> statuses);

    /** The admin board: by status, newest first (first page). */
    @Query("SELECT o FROM Order o WHERE o.storeId = :storeId AND o.status IN :statuses ORDER BY o.createdAt DESC, o.id DESC")
    List<Order> findAdminFirstPage(@Param("storeId") Long storeId, @Param("statuses") Collection<OrderStatus> statuses,
                                   Pageable pageable);

    @Query("""
            SELECT o FROM Order o WHERE o.storeId = :storeId AND o.status IN :statuses
              AND (o.createdAt < :beforeAt OR (o.createdAt = :beforeAt AND o.id < :beforeId))
            ORDER BY o.createdAt DESC, o.id DESC
            """)
    List<Order> findAdminPageBefore(@Param("storeId") Long storeId, @Param("statuses") Collection<OrderStatus> statuses,
                                    @Param("beforeAt") Instant beforeAt, @Param("beforeId") Long beforeId, Pageable pageable);

    Optional<Order> findByOrderNumber(Long orderNumber);

    /** Search by the phone captured on the order (+201XXXXXXXXX), newest first. */
    @Query(value = "SELECT * FROM orders WHERE store_id = :storeId AND customer_snapshot ->> 'phone' = :phone ORDER BY created_at DESC, id DESC LIMIT 50",
            nativeQuery = true)
    List<Order> findByPhone(@Param("storeId") Long storeId, @Param("phone") String phone);

    long countByStoreIdAndStatus(Long storeId, OrderStatus status);
}
