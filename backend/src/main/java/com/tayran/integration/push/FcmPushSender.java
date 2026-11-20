package com.tayran.integration.push;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Notification;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** FCM through the Firebase Admin SDK. Tokens are never logged. */
@Slf4j
public class FcmPushSender implements PushSender {

    private static final Set<MessagingErrorCode> INVALID = Set.of(MessagingErrorCode.UNREGISTERED, MessagingErrorCode.INVALID_ARGUMENT,
            MessagingErrorCode.SENDER_ID_MISMATCH);

    private final FirebaseMessaging messaging;

    public FcmPushSender(FirebaseMessaging messaging) {
        this.messaging = messaging;
    }

    @Override
    public List<String> send(List<String> tokens, PushMessage message) {
        if (tokens.isEmpty()) {
            return List.of();
        }
        MulticastMessage multicast = MulticastMessage.builder()
                .addAllTokens(tokens)
                .setNotification(Notification.builder().setTitle(message.title()).setBody(message.body()).build())
                .putAllData(message.data())
                .setAndroidConfig(AndroidConfig.builder()
                        .setPriority(AndroidConfig.Priority.HIGH)
                        .setNotification(AndroidNotification.builder()
                                .setChannelId(message.channelId())
                                .setIcon("ic_stat_tayran")
                                .setColor("#F77F00")
                                .build())
                        .build())
                .build();
        try {
            BatchResponse response = messaging.sendEachForMulticast(multicast);
            List<String> invalid = new ArrayList<>();
            for (int i = 0; i < response.getResponses().size(); i++) {
                var r = response.getResponses().get(i);
                // Set.of(...).contains(null) throws, and a failure can come without an error code.
                MessagingErrorCode code = r.isSuccessful() || r.getException() == null ? null : r.getException().getMessagingErrorCode();
                if (code != null && INVALID.contains(code)) {
                    invalid.add(tokens.get(i));
                }
            }
            response.getResponses().stream().filter(r -> !r.isSuccessful() && r.getException() != null).findFirst()
                    .ifPresent(r -> log.warn("Push failure: {} {}", r.getException().getMessagingErrorCode(),
                            r.getException().getClass().getSimpleName()));
            if (response.getFailureCount() > 0) {
                log.info("Push: {} sent, {} failed ({} invalid tokens)", response.getSuccessCount(), response.getFailureCount(), invalid.size());
            }
            return invalid;
        } catch (FirebaseMessagingException e) {
            log.warn("Push failed: {}", e.getMessagingErrorCode());
            return List.of();
        }
    }
}
