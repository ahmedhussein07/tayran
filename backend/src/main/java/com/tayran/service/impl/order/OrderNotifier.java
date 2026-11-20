package com.tayran.service.impl.order;

import com.tayran.dao.entity.User;
import com.tayran.dao.entity.UserDevice;
import com.tayran.dao.repository.UserDeviceRepository;
import com.tayran.dao.repository.UserRepository;
import com.tayran.integration.push.PushSender;
import com.tayran.integration.push.PushSender.PushMessage;
import com.tayran.model.order.ActorType;
import com.tayran.model.order.OrderStatus;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.List;
import java.util.Map;

/**
 * Pushes order updates to the customer's phones, only after the change is committed and on a
 * separate thread: a failed or slow push never affects the order. Tokens FCM rejects are removed.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OrderNotifier {

    public static final String CHANNEL = "orders";

    private final PushSender sender;
    private final UserDeviceRepository deviceRepository;
    private final UserRepository userRepository;

    @Async("pushExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onOrderChanged(OrderChanged change) {
        try {
            if (!shouldNotify(change)) {
                return;
            }
            List<String> tokens = deviceRepository.findByUserId(change.userId()).stream().map(UserDevice::getFcmToken).toList();
            if (tokens.isEmpty()) {
                return;
            }
            boolean english = userRepository.findById(change.userId()).map(User::getPreferredLanguage).map("en"::equals).orElse(false);
            PushMessage message = message(change, english);
            List<String> invalid = sender.send(tokens, message);
            if (!invalid.isEmpty()) {
                deviceRepository.deleteByTokens(invalid);
            }
        } catch (RuntimeException e) {
            // The stack trace helps find the cause; it never contains tokens or texts.
            log.warn("Push for order {} failed", change.orderId(), e);
        }
    }

    /** Status changes the customer didn't make themselves; never new orders or item edits. */
    static boolean shouldNotify(OrderChanged change) {
        if (change.created() || change.itemsEdited()) {
            return false;
        }
        return switch (change.status()) {
            case CONFIRMED, OUT_FOR_DELIVERY, DELIVERED -> true;
            case CANCELLED -> change.actor() != ActorType.CUSTOMER;
            case PENDING_REVIEW -> false;
        };
    }

    static PushMessage message(OrderChanged c, boolean english) {
        String n = english ? String.valueOf(c.number()) : arabicDigits(String.valueOf(c.number()));
        String title;
        String body;
        switch (c.status()) {
            case CONFIRMED -> {
                title = english ? "Order #" + n + " confirmed" : "أكدنا طلبك رقم " + n;
                body = c.itemsChanged()
                        ? (english ? "We changed a few items in your order. Tap to see what changed." : "عدّلنا شوية حاجات في طلبك، دوس وشوف التفاصيل")
                        : (english ? "We're preparing it now." : "بنجهزه دلوقتي");
            }
            case OUT_FOR_DELIVERY -> {
                title = english ? "Your order is on its way" : "طلبك في الطريق";
                String courier = c.courierName() == null ? "" : c.courierName();
                body = english ? courier + " is bringing order #" + n + "." : courier + " جايلك بطلبك رقم " + n;
            }
            case DELIVERED -> {
                title = english ? "Order #" + n + " delivered" : "اتسلم طلبك رقم " + n;
                body = english ? "Enjoy! Thanks for ordering from Tayran." : "بالهنا والشفا، شكرًا إنك طلبت من طيران";
            }
            case CANCELLED -> {
                title = english ? "Order #" + n + " was cancelled" : "اتلغى طلبك رقم " + n;
                body = c.cancelReason() == null ? "" : c.cancelReason();
            }
            default -> throw new IllegalArgumentException("No push for " + c.status());
        }
        Map<String, String> data = Map.of(
                "orderId", String.valueOf(c.orderId()),
                "status", c.status().name(),
                "stage", String.valueOf(c.status().stage()),
                "version", String.valueOf(c.version()),
                "itemsChanged", String.valueOf(c.itemsChanged()));
        return new PushMessage(title, body.strip(), data, CHANNEL);
    }

    private static String arabicDigits(String s) {
        StringBuilder sb = new StringBuilder();
        for (char ch : s.toCharArray()) {
            sb.append(ch >= '0' && ch <= '9' ? (char) ('٠' + (ch - '0')) : ch);
        }
        return sb.toString();
    }

    static boolean isFinal(OrderStatus status) {
        return status.isFinal();
    }
}
