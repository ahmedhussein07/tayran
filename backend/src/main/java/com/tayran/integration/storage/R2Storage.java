package com.tayran.integration.storage;

import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.checksums.RequestChecksumCalculation;
import software.amazon.awssdk.core.checksums.ResponseChecksumValidation;
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
        String endpoint = endpoint(env.getProperty("R2_ENDPOINT"), accountId);
        this.client = S3Client.builder()
                .region(Region.of("auto"))
                .endpointOverride(URI.create(endpoint))
                .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create(accessKey, secretKey)))
                .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
                // SDK 2.30+ adds integrity checksums to every upload by default; R2 doesn't accept
                // all of them, so only send them when an operation requires one (Cloudflare's advice).
                .requestChecksumCalculation(RequestChecksumCalculation.WHEN_REQUIRED)
                .responseChecksumValidation(ResponseChecksumValidation.WHEN_REQUIRED)
                .build();
        // Fail at startup, not on the first upload, when the bucket or keys are wrong. A HEAD on a
        // key that doesn't exist answers 404 when the keys can read the bucket (object-scoped API
        // tokens may not be allowed HeadBucket, so that isn't used).
        try {
            exists(".tayran-startup-check");
        } catch (S3Exception e) {
            throw new IllegalStateException("R2 check failed (HTTP " + e.statusCode() + "): "
                    + (e.statusCode() == 403 ? "the access key can't read R2_BUCKET; give the token Object Read & Write on it"
                    : e.statusCode() == 404 ? "R2_BUCKET doesn't exist in this account"
                    : "check R2_BUCKET, R2_ACCESS_KEY_ID / R2_SECRET_ACCESS_KEY and R2_ACCOUNT_ID / R2_ENDPOINT"));
        }
        log.info("R2 object storage configured and reachable");
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

    /**
     * The S3 endpoint for the account: R2_ENDPOINT, or https://{account}.r2.cloudflarestorage.com.
     * Anything after the host is dropped. The bucket is added by the client, so an endpoint copied
     * with "/bucket" on the end (as the Cloudflare dashboard shows it) would otherwise put every
     * object under a "bucket/" folder that the public URL can't see.
     */
    static String endpoint(String configured, String accountId) {
        if (configured == null || configured.isBlank()) {
            return "https://" + accountId + ".r2.cloudflarestorage.com";
        }
        URI uri = URI.create(configured.trim());
        if (uri.getScheme() == null || uri.getHost() == null) {
            throw new IllegalStateException("R2_ENDPOINT must be a URL like https://<account>.r2.cloudflarestorage.com");
        }
        if (uri.getPath() != null && !uri.getPath().isEmpty() && !uri.getPath().equals("/")) {
            log.warn("R2_ENDPOINT has a path after the host; using the host only (the bucket comes from R2_BUCKET)");
        }
        return uri.getScheme() + "://" + uri.getHost() + (uri.getPort() > 0 ? ":" + uri.getPort() : "");
    }

    private static String required(Environment env, String name) {
        String value = env.getProperty(name);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException(name + " must be set for the r2 profile");
        }
        return value.trim();
    }
}
