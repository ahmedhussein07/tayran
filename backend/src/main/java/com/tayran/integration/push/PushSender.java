package com.tayran.integration.push;

import java.util.List;
import java.util.Map;

/** Sends push notifications to devices (FCM, or a no-op when Firebase isn't configured). */
public interface PushSender {

    /** A notification with a data payload; {@code channelId} is the Android channel. */
    record PushMessage(String title, String body, Map<String, String> data, String channelId) {
    }

    /**
     * Sends to every token.
     *
     * @return tokens the push service reported as invalid or unregistered (to be removed)
     */
    List<String> send(List<String> tokens, PushMessage message);
}
