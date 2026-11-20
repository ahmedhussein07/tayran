package com.tayran.integration.push;

import lombok.extern.slf4j.Slf4j;

import java.util.List;

/** Used when the Firebase service account file is missing: the backend runs, nothing is pushed. */
@Slf4j
public class NoopPushSender implements PushSender {

    @Override
    public List<String> send(List<String> tokens, PushMessage message) {
        log.debug("Push skipped (no Firebase credentials): {}", message.data());
        return List.of();
    }
}
