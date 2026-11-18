package com.tayran.integration.storage;

import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.net.URI;

/**
 * Cloudflare R2 through the S3 API (r2 profile). Configured ONLY from the environment variables
 * R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET and R2_ENDPOINT; their values
 * are never printed or logged.
 */
@Slf4j
@Component
@Profile("r2")
public class R2Storage implements ObjectStorage {

    private final S3Client client;
    private final String bucket;

    public R2Storage(Environment env) {
        String accountId = required(env, "R2_ACCOUNT_ID");
        String accessKey = required(env, "R2_ACCESS_KEY_ID");
        String secretKey = required(env, "R2_SECRET_ACCESS_KEY");
        this.bucket = required(env, "R2_BUCKET");
        String endpoint = env.getProperty("R2_ENDPOINT");
        if (endpoint == null || endpoint.isBlank()) {
            endpoint = "https://" + accountId + ".r2.cloudflarestorage.com";
        }
        this.client = S3Client.builder()
                .region(Region.of("auto"))
                .endpointOverride(URI.create(endpoint))
                .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create(accessKey, secretKey)))
                .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
                .build();
        log.info("R2 object storage configured");
    }

    @Override
    public void put(String key, byte[] bytes, String contentType, String cacheControl) {
        client.putObject(PutObjectRequest.builder().bucket(bucket).key(key).contentType(contentType).cacheControl(cacheControl).build(),
                RequestBody.fromBytes(bytes));
    }

    @Override
    public boolean exists(String key) {
        try {
            client.headObject(HeadObjectRequest.builder().bucket(bucket).key(key).build());
            return true;
        } catch (NoSuchKeyException e) {
            return false;
        } catch (S3Exception e) {
            if (e.statusCode() == 404) {
                return false;
            }
            throw e;
        }
    }

    @Override
    public void delete(String key) {
        client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(key).build());
    }

    @PreDestroy
    void close() {
        client.close();
    }

    private static String required(Environment env, String name) {
        String value = env.getProperty(name);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException(name + " must be set for the r2 profile");
        }
        return value;
    }
}
