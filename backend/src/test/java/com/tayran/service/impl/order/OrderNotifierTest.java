package com.tayran.service.impl.order;

import com.tayran.dao.entity.User;
import com.tayran.dao.entity.UserDevice;
import com.tayran.dao.repository.UserDeviceRepository;
import com.tayran.dao.repository.UserRepository;
import com.tayran.integration.push.PushSender;
import com.tayran.integration.push.PushSender.PushMessage;
import com.tayran.model.order.ActorType;
import com.tayran.model.order.OrderStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class OrderNotifierTest {

    private PushSender sender;
    private UserDeviceRepository devices;
    private UserRepository users;
    private OrderNotifier notifier;

    @BeforeEach
    void setUp() {
        sender = mock(PushSender.class);
        devices = mock(UserDeviceRepository.class);
        users = mock(UserRepository.class);
        notifier = new OrderNotifier(sender, devices, users);
        UserDevice d1 = device("token-1");
        UserDevice d2 = device("token-2");
        when(devices.findByUserId(7L)).thenReturn(List.of(d1, d2));
        User user = new User("+201000000007");
        user.setPreferredLanguage("ar");
        when(users.findById(7L)).thenReturn(Optional.of(user));
    }

    private static UserDevice device(String token) {
        UserDevice d = new UserDevice();
        d.setFcmToken(token);
        return d;
    }

    private static OrderChanged change(OrderStatus status, boolean itemsChanged, ActorType actor) {
        return new OrderChanged(5L, 10042L, 7L, status, 3, false, false, itemsChanged, actor, "مفيش طيارين دلوقتي", "حسن");
    }

    @Test
    void notifiesOnlyStatusChangesTheCustomerDidntMake() {
        assertThat(OrderNotifier.shouldNotify(change(OrderStatus.CONFIRMED, false, ActorType.ADMIN))).isTrue();
        assertThat(OrderNotifier.shouldNotify(change(OrderStatus.OUT_FOR_DELIVERY, false, ActorType.ADMIN))).isTrue();
        assertThat(OrderNotifier.shouldNotify(change(OrderStatus.DELIVERED, false, ActorType.ADMIN))).isTrue();
        assertThat(OrderNotifier.shouldNotify(change(OrderStatus.CANCELLED, false, ActorType.ADMIN))).isTrue();
        assertThat(OrderNotifier.shouldNotify(change(OrderStatus.CANCELLED, false, ActorType.CUSTOMER))).isFalse();
        assertThat(OrderNotifier.shouldNotify(new OrderChanged(5L, 1L, 7L, OrderStatus.PENDING_REVIEW, 0, true, false, false,
                ActorType.CUSTOMER, null, null))).isFalse();
        assertThat(OrderNotifier.shouldNotify(new OrderChanged(5L, 1L, 7L, OrderStatus.PENDING_REVIEW, 1, false, true, true,
                ActorType.ADMIN, null, null))).isFalse();
    }

    @Test
    void textsFollowTheCustomersLanguageAndDataDrivesTheApp() {
        PushMessage ar = OrderNotifier.message(change(OrderStatus.CONFIRMED, true, ActorType.ADMIN), false);
        assertThat(ar.title()).isEqualTo("أكدنا طلبك رقم ١٠٠٤٢");
        assertThat(ar.body()).contains("عدّلنا");
        assertThat(ar.channelId()).isEqualTo("orders");
        assertThat(ar.data()).containsEntry("orderId", "5").containsEntry("status", "CONFIRMED").containsEntry("stage", "2")
                .containsEntry("version", "3").containsEntry("itemsChanged", "true");

        PushMessage en = OrderNotifier.message(change(OrderStatus.OUT_FOR_DELIVERY, false, ActorType.ADMIN), true);
        assertThat(en.title()).isEqualTo("Your order is on its way");
        assertThat(en.body()).contains("حسن").contains("#10042");

        PushMessage cancelled = OrderNotifier.message(change(OrderStatus.CANCELLED, false, ActorType.ADMIN), false);
        assertThat(cancelled.body()).isEqualTo("مفيش طيارين دلوقتي");
    }

    @Test
    void sendsToEveryDeviceAndRemovesTokensFcmRejects() {
        when(sender.send(anyList(), any())).thenReturn(List.of("token-2"));
        notifier.onOrderChanged(change(OrderStatus.CONFIRMED, false, ActorType.ADMIN));

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<String>> tokens = ArgumentCaptor.forClass(List.class);
        verify(sender).send(tokens.capture(), any());
        assertThat(tokens.getValue()).containsExactly("token-1", "token-2");
        verify(devices).deleteByTokens(List.of("token-2"));
    }

    @Test
    void aFailingPushIsSwallowed() {
        when(sender.send(anyList(), any())).thenThrow(new IllegalStateException("FCM down"));
        notifier.onOrderChanged(change(OrderStatus.DELIVERED, false, ActorType.ADMIN)); // no exception
        verify(devices, never()).deleteByTokens(any());
    }

    @Test
    void customerCancellationsAreNotPushed() {
        notifier.onOrderChanged(change(OrderStatus.CANCELLED, false, ActorType.CUSTOMER));
        verify(sender, never()).send(anyList(), any());
    }
}
