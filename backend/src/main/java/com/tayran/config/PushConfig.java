package com.tayran.config;

import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.tayran.integration.push.FcmPushSender;
import com.tayran.integration.push.NoopPushSender;
import com.tayran.integration.push.PushSender;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.TaskExecutor;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Firebase is initialized once from the service account file at FIREBASE_SERVICE_ACCOUNT_FILE.
 * The file's contents are never logged or copied. When it's missing, a no-op sender keeps the
 * backend running.
 */
@Slf4j
@EnableAsync
@Configuration
public class PushConfig {

    @Bean
    PushSender pushSender(@Value("${firebase.service-account-file:}") String file) {
        if (file == null || file.isBlank() || !Files.isRegularFile(Path.of(file))) {
            log.warn("Firebase service account file not found: push notifications are disabled (no-op sender)");
            return new NoopPushSender();
        }
        try (InputStream in = Files.newInputStream(Path.of(file))) {
            FirebaseApp app = FirebaseApp.getApps().stream().filter(a -> a.getName().equals("tayran")).findFirst()
                    .orElseGet(() -> {
                        try {
                            // The JDK transport: with the default Apache one, FCM's gzipped reply is
                            // unzipped twice ("Not in GZIP format"), so sent pushes count as failed.
                            return FirebaseApp.initializeApp(FirebaseOptions.builder()
                                    .setHttpTransport(new NetHttpTransport())
                                    .setCredentials(GoogleCredentials.fromStream(in, NetHttpTransport::new)).build(), "tayran");
                        } catch (IOException e) {
                            throw new java.io.UncheckedIOException(e);
                        }
                    });
            log.info("Firebase push initialized");
            return new FcmPushSender(FirebaseMessaging.getInstance(app));
        } catch (IOException | RuntimeException | LinkageError e) {
            // The type only (never the message, which could quote the file).
            log.warn("Firebase service account file could not be used ({}): push notifications are disabled (no-op sender)",
                    e.getClass().getSimpleName());
            return new NoopPushSender();
        }
    }

    /** Pushes go out on their own threads, so a slow push service never delays an admin action. */
    @Bean
    TaskExecutor pushExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(4);
        executor.setQueueCapacity(500);
        executor.setThreadNamePrefix("push-");
        executor.initialize();
        return executor;
    }
}
