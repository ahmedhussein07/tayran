package com.tayran.config;

import com.tayran.integration.push.FcmPushSender;
import com.tayran.integration.push.NoopPushSender;
import com.tayran.integration.push.PushSender;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import tools.jackson.databind.json.JsonMapper;

import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPairGenerator;
import java.util.Base64;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class PushConfigTest {

    @Test
    void missingServiceAccountFileMeansANoOpSender() {
        PushSender sender = new PushConfig().pushSender("C:/does/not/exist/tayran-firebase.json");
        assertThat(sender).isInstanceOf(NoopPushSender.class);
        assertThat(sender.send(java.util.List.of("t"), new PushSender.PushMessage("a", "b", java.util.Map.of(), "orders"))).isEmpty();
    }

    @Test
    void blankPathMeansANoOpSender() {
        assertThat(new PushConfig().pushSender("")).isInstanceOf(NoopPushSender.class);
    }

    @Test
    void anUnusableFileAlsoFallsBackInsteadOfStoppingTheBackend(@TempDir Path dir) throws Exception {
        Path broken = dir.resolve("broken.json");
        Files.writeString(broken, "{ not a service account }");
        assertThat(new PushConfig().pushSender(broken.toString())).isInstanceOf(NoopPushSender.class);
    }

    /**
     * A well-formed (made-up) service account gives the real FCM sender. This runs the whole
     * Firebase Admin setup, as the real file does, so a missing library shows up here.
     */
    @Test
    void aValidServiceAccountGivesTheFcmSender(@TempDir Path dir) throws Exception {
        var generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        String body = Base64.getEncoder().encodeToString(generator.generateKeyPair().getPrivate().getEncoded());
        String pem = String.join(System.lineSeparator(), "-----BEGIN PRIVATE KEY-----", body, "-----END PRIVATE KEY-----");
        Path file = dir.resolve("sa.json");
        Files.writeString(file, JsonMapper.builder().build().writeValueAsString(Map.of(
                "type", "service_account",
                "project_id", "tayran-test",
                "private_key_id", "k1",
                "private_key", pem,
                "client_email", "push@tayran-test.iam.gserviceaccount.com",
                "client_id", "1",
                "token_uri", "https://oauth2.googleapis.com/token")));
        assertThat(new PushConfig().pushSender(file.toString())).isInstanceOf(FcmPushSender.class);
    }
}
