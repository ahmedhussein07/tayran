package com.tayran.service.impl;

import com.sksamuel.scrimage.ImmutableImage;
import com.sksamuel.scrimage.webp.WebpImageReader;
import com.sksamuel.scrimage.webp.WebpWriter;
import com.tayran.config.properties.StorageProperties;
import com.tayran.dao.entity.ImageRecord;
import com.tayran.dao.repository.ImageRecordRepository;
import com.tayran.exception.BusinessException;
import com.tayran.integration.storage.ObjectStorage;
import com.tayran.model.ImageKind;
import com.tayran.model.TayranConst;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ImageIngestServiceTest {

    /** Object storage in a map, recording content type and cache header. */
    static class MemoryStorage implements ObjectStorage {
        record Stored(byte[] bytes, String contentType, String cacheControl) {
        }

        final Map<String, Stored> objects = new HashMap<>();
        int puts;

        @Override
        public void put(String key, byte[] bytes, String contentType, String cacheControl) {
            puts++;
            objects.put(key, new Stored(bytes, contentType, cacheControl));
        }

        @Override
        public boolean exists(String key) {
            return objects.containsKey(key);
        }

        @Override
        public void delete(String key) {
            objects.remove(key);
        }
    }

    private MemoryStorage storage;
    private ImageRecordRepository repository;
    private ImageIngestService service;

    @BeforeEach
    void setUp() {
        storage = new MemoryStorage();
        repository = mock(ImageRecordRepository.class);
        when(repository.findById(anyString())).thenReturn(Optional.empty());
        when(repository.save(any(ImageRecord.class))).thenAnswer(i -> i.getArgument(0));
        service = new ImageIngestService(storage, repository, new StorageProperties("https://cdn.example/x", null),
                Clock.fixed(Instant.parse("2026-11-01T10:00:00Z"), ZoneOffset.UTC));
    }

    @Test
    void productImageBecomesThreeSquareWebpVariantsWithAnImmutableCacheHeader() throws IOException {
        ImageIngestService.Result result = service.ingest(ImageKind.PRODUCT, png(600, 400, Color.WHITE, new Color(200, 40, 40)));

        assertThat(result.hash()).matches("[0-9a-f]{12}");
        assertThat(result.previewUrl()).isEqualTo("https://cdn.example/x/p/" + result.hash() + "_320.webp");
        assertThat(storage.objects).containsOnlyKeys(
                "p/" + result.hash() + "_160.webp", "p/" + result.hash() + "_320.webp", "p/" + result.hash() + "_640.webp");
        for (int width : new int[]{160, 320, 640}) {
            MemoryStorage.Stored stored = storage.objects.get("p/" + result.hash() + "_" + width + ".webp");
            assertThat(stored.contentType()).isEqualTo("image/webp");
            assertThat(stored.cacheControl()).isEqualTo(ObjectStorage.IMMUTABLE);
            ImmutableImage decoded = new WebpImageReader().read(stored.bytes());
            assertThat(decoded.width).isEqualTo(width);
            assertThat(decoded.height).isEqualTo(width);
        }
    }

    @Test
    void categoryImageBecomesTwoVariants() {
        ImageIngestService.Result result = service.ingest(ImageKind.CATEGORY, png(300, 300, Color.WHITE, Color.BLUE));
        assertThat(storage.objects).containsOnlyKeys("c/" + result.hash() + "_128.webp", "c/" + result.hash() + "_256.webp");
        assertThat(result.previewUrl()).endsWith("/c/" + result.hash() + "_256.webp");
    }

    @Test
    void whiteBackgroundIsTrimmedToTransparentAndTheSubjectIsPaddedEightPercent() throws IOException {
        ImageIngestService.Result result = service.ingest(ImageKind.PRODUCT, png(600, 400, Color.WHITE, new Color(200, 40, 40)));
        ImmutableImage big = new WebpImageReader().read(storage.objects.get("p/" + result.hash() + "_640.webp").bytes());

        // Corners are transparent: the white was trimmed away and the square padded with transparency.
        assertThat(big.pixel(0, 0).alpha()).isLessThan(16);
        assertThat(big.pixel(639, 639).alpha()).isLessThan(16);
        // The subject fills the square up to the 8% padding: the centre is the subject's colour.
        assertThat(big.pixel(320, 320).red()).isGreaterThan(150);
        assertThat(big.pixel(320, 320).alpha()).isGreaterThan(240);
        // Just inside the padding on the middle row is still subject, just outside is transparent.
        int pad = (int) Math.round(640 * 0.08);
        assertThat(big.pixel(pad + 6, 320).alpha()).isGreaterThan(200);
        assertThat(big.pixel(pad - 6, 320).alpha()).isLessThan(40);
    }

    @Test
    void transparencyIsKept() throws IOException {
        BufferedImage image = new BufferedImage(400, 400, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = image.createGraphics();
        g.setColor(new Color(30, 140, 60));
        g.fillOval(50, 50, 300, 300);
        g.dispose();
        ImageIngestService.Result result = service.ingest(ImageKind.PRODUCT, encode(image));
        ImmutableImage decoded = new WebpImageReader().read(storage.objects.get("p/" + result.hash() + "_320.webp").bytes());
        assertThat(decoded.pixel(2, 2).alpha()).isLessThan(16);
        assertThat(decoded.pixel(160, 160).alpha()).isGreaterThan(240);
    }

    @Test
    void dominantColourComesFromTheSubjectNotTheBackground() {
        ImageIngestService.Result result = service.ingest(ImageKind.PRODUCT, png(600, 400, Color.WHITE, new Color(200, 40, 40)));
        assertThat(result.bg()).matches("#[0-9A-F]{6}");
        Color bg = Color.decode(result.bg());
        assertThat(bg.getRed()).isGreaterThan(bg.getGreen() + 60);
    }

    @Test
    void sameImageGivesTheSameHashAndIsNotWrittenTwice() {
        byte[] bytes = png(600, 400, Color.WHITE, new Color(200, 40, 40));
        String first = service.ingest(ImageKind.PRODUCT, bytes).hash();
        int puts = storage.puts;
        String second = service.ingest(ImageKind.PRODUCT, bytes).hash();

        assertThat(second).isEqualTo(first);
        assertThat(storage.puts).isEqualTo(puts);
        // Different kinds never share a hash.
        assertThat(service.ingest(ImageKind.CATEGORY, bytes).hash()).isNotEqualTo(first);
    }

    @Test
    void jpegAndWebpInputsAreAccepted() throws IOException {
        BufferedImage rgb = new BufferedImage(300, 200, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = rgb.createGraphics();
        g.setColor(Color.ORANGE);
        g.fillRect(0, 0, 300, 200);
        g.dispose();
        ByteArrayOutputStream jpeg = new ByteArrayOutputStream();
        ImageIO.write(rgb, "jpg", jpeg);
        assertThat(service.ingest(ImageKind.PRODUCT, jpeg.toByteArray()).hash()).isNotBlank();

        byte[] webp = ImmutableImage.wrapAwt(rgb).bytes(WebpWriter.DEFAULT);
        assertThat(service.ingest(ImageKind.CATEGORY, webp).hash()).isNotBlank();
    }

    @Test
    void badFilesAreRejectedWithClearCodes() {
        assertCode(() -> service.ingest(ImageKind.PRODUCT, new byte[0]), TayranConst.IMAGE_UNREADABLE);
        assertCode(() -> service.ingest(ImageKind.PRODUCT, "GIF89a not supported".getBytes()), TayranConst.IMAGE_TYPE_UNSUPPORTED);
        assertCode(() -> service.ingest(ImageKind.PRODUCT, "<svg xmlns='http://www.w3.org/2000/svg'/>".getBytes()),
                TayranConst.IMAGE_TYPE_UNSUPPORTED);
        assertCode(() -> service.ingest(ImageKind.PRODUCT, new byte[ImageIngestService.MAX_BYTES + 1]), TayranConst.IMAGE_TOO_LARGE);

        // A PNG signature followed by garbage.
        byte[] truncated = png(100, 100, Color.WHITE, Color.BLACK);
        byte[] broken = java.util.Arrays.copyOf(truncated, 40);
        assertCode(() -> service.ingest(ImageKind.PRODUCT, broken), TayranConst.IMAGE_UNREADABLE);

        assertThat(storage.objects).isEmpty();
    }

    @Test
    void hugeDimensionsAreRejectedBeforeDecoding() {
        // 6001 x 1 PNG: tiny file, oversize header.
        BufferedImage wide = new BufferedImage(ImageIngestService.MAX_SIDE + 1, 1, BufferedImage.TYPE_INT_RGB);
        assertCode(() -> service.ingest(ImageKind.PRODUCT, encode(wide)), TayranConst.IMAGE_DIMENSIONS_TOO_LARGE);
    }

    private static void assertCode(Runnable call, String code) {
        assertThatThrownBy(call::run).isInstanceOf(BusinessException.class)
                .satisfies(e -> assertThat(((BusinessException) e).getCode()).isEqualTo(code));
    }

    /** A filled circle off-centre on a solid background. */
    static byte[] png(int w, int h, Color background, Color subject) {
        BufferedImage image = new BufferedImage(w, h, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();
        g.setColor(background);
        g.fillRect(0, 0, w, h);
        g.setColor(subject);
        int d = Math.min(w, h) * 2 / 3;
        g.fillOval(w / 8, h / 8, d, d);
        g.dispose();
        return encode(image);
    }

    static byte[] encode(BufferedImage image) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            ImageIO.write(image, "png", out);
            return out.toByteArray();
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }
}
