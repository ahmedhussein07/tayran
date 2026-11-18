package com.tayran.service.impl;

import com.sksamuel.scrimage.ImmutableImage;
import com.sksamuel.scrimage.ScaleMethod;
import com.sksamuel.scrimage.webp.WebpImageReader;
import com.sksamuel.scrimage.webp.WebpWriter;
import com.tayran.config.properties.StorageProperties;
import com.tayran.dao.entity.ImageRecord;
import com.tayran.dao.repository.ImageRecordRepository;
import com.tayran.exception.BusinessException;
import com.tayran.integration.storage.ObjectStorage;
import com.tayran.model.ImageKind;
import com.tayran.model.TayranConst;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.Instant;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.Iterator;
import java.util.Map;

/**
 * Turns an uploaded image into content-addressed WebP variants:
 * validate → decode (auto-oriented, metadata dropped) → trim transparent / near-white edges →
 * centre on a transparent square with 8% padding → hash → variants → dominant colour → store.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImageIngestService {

    public record Result(String hash, String bg, String previewUrl) {
    }

    static final int MAX_BYTES = 10 * 1024 * 1024;
    static final int MAX_SIDE = 6000;
    /** The normalized square is capped here: the largest variant is 640px. */
    static final int NORMALIZED_MAX = 1024;
    static final double PADDING = 0.08;
    static final int WEBP_QUALITY = 78;

    private final ObjectStorage storage;
    private final ImageRecordRepository imageRepository;
    private final StorageProperties storageProperties;
    private final Clock clock;

    private enum Format { JPEG, PNG, WEBP }

    @Transactional
    public Result ingest(ImageKind kind, byte[] bytes) {
        if (bytes == null || bytes.length == 0) {
            throw new BusinessException(TayranConst.IMAGE_UNREADABLE);
        }
        if (bytes.length > MAX_BYTES) {
            throw new BusinessException(TayranConst.IMAGE_TOO_LARGE);
        }
        Format format = sniff(bytes);
        int[] size = dimensions(format, bytes);
        if (size[0] > MAX_SIDE || size[1] > MAX_SIDE) {
            throw new BusinessException(TayranConst.IMAGE_DIMENSIONS_TOO_LARGE);
        }

        BufferedImage decoded = decode(format, bytes);
        BufferedImage square = normalize(decoded);
        String hash = hash(kind, square);
        String bg = dominantColour(square);

        ImmutableImage source = ImmutableImage.wrapAwt(square);
        WebpWriter writer = WebpWriter.DEFAULT.withQ(WEBP_QUALITY);
        for (int width : kind.widths()) {
            String key = kind.key(hash, width);
            if (storage.exists(key)) {
                continue; // same image already stored: dedupe
            }
            try {
                byte[] webp = source.scaleTo(width, width, ScaleMethod.Lanczos3).bytes(writer);
                storage.put(key, webp, "image/webp", ObjectStorage.IMMUTABLE);
            } catch (IOException e) {
                throw new IllegalStateException("WebP encoding failed", e);
            }
        }

        Instant now = clock.instant();
        ImageRecord record = imageRepository.findById(hash).orElseGet(() -> new ImageRecord(hash, kind, bg, now, now));
        record.setLastReferencedAt(now);
        imageRepository.save(record);
        return new Result(hash, bg, storageProperties.url(kind.previewKey(hash)));
    }

    // ---- validation ------------------------------------------------------------------------

    private static Format sniff(byte[] b) {
        if (b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) {
            return Format.JPEG;
        }
        if (b.length >= 8 && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') {
            return Format.PNG;
        }
        if (b.length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') {
            return Format.WEBP;
        }
        throw new BusinessException(TayranConst.IMAGE_TYPE_UNSUPPORTED);
    }

    /** Reads width and height from the header only, before decoding anything large. */
    private static int[] dimensions(Format format, byte[] b) {
        if (format == Format.WEBP) {
            return webpDimensions(b);
        }
        try (ImageInputStream in = ImageIO.createImageInputStream(new ByteArrayInputStream(b))) {
            Iterator<ImageReader> readers = ImageIO.getImageReaders(in);
            if (!readers.hasNext()) {
                throw new BusinessException(TayranConst.IMAGE_UNREADABLE);
            }
            ImageReader reader = readers.next();
            try {
                reader.setInput(in, true, true);
                return new int[]{reader.getWidth(0), reader.getHeight(0)};
            } finally {
                reader.dispose();
            }
        } catch (IOException e) {
            throw new BusinessException(TayranConst.IMAGE_UNREADABLE);
        }
    }

    private static int[] webpDimensions(byte[] b) {
        if (b.length < 30) {
            throw new BusinessException(TayranConst.IMAGE_UNREADABLE);
        }
        String chunk = new String(b, 12, 4, StandardCharsets.US_ASCII);
        switch (chunk) {
            case "VP8X" -> {
                int w = 1 + ((b[24] & 0xFF) | (b[25] & 0xFF) << 8 | (b[26] & 0xFF) << 16);
                int h = 1 + ((b[27] & 0xFF) | (b[28] & 0xFF) << 8 | (b[29] & 0xFF) << 16);
                return new int[]{w, h};
            }
            case "VP8 " -> {
                int w = ((b[26] & 0xFF) | (b[27] & 0xFF) << 8) & 0x3FFF;
                int h = ((b[28] & 0xFF) | (b[29] & 0xFF) << 8) & 0x3FFF;
                return new int[]{w, h};
            }
            case "VP8L" -> {
                int bits = (b[21] & 0xFF) | (b[22] & 0xFF) << 8 | (b[23] & 0xFF) << 16 | (b[24] & 0xFF) << 24;
                return new int[]{(bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1};
            }
            default -> throw new BusinessException(TayranConst.IMAGE_UNREADABLE);
        }
    }

    private static BufferedImage decode(Format format, byte[] bytes) {
        try {
            ImmutableImage image = format == Format.WEBP
                    ? new WebpImageReader().read(bytes)
                    : ImmutableImage.loader().detectOrientation(true).fromBytes(bytes);
            BufferedImage argb = new BufferedImage(image.width, image.height, BufferedImage.TYPE_INT_ARGB);
            Graphics2D g = argb.createGraphics();
            g.drawImage(image.awt(), 0, 0, null);
            g.dispose();
            return argb;
        } catch (IOException | RuntimeException e) {
            throw new BusinessException(TayranConst.IMAGE_UNREADABLE);
        }
    }

    // ---- normalization ---------------------------------------------------------------------

    /** A pixel is background when it is (almost) transparent or (almost) white. */
    static boolean isBackground(int argb) {
        int a = argb >>> 24;
        int r = (argb >> 16) & 0xFF;
        int g = (argb >> 8) & 0xFF;
        int b = argb & 0xFF;
        return a < 16 || (r > 244 && g > 244 && b > 244);
    }

    /** Trims background edges, scales into NORMALIZED_MAX, and centres on a transparent square with padding. */
    static BufferedImage normalize(BufferedImage image) {
        int w = image.getWidth();
        int h = image.getHeight();
        int[] px = image.getRGB(0, 0, w, h, null, 0, w);
        int minX = w, minY = h, maxX = -1, maxY = -1;
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                if (!isBackground(px[y * w + x])) {
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        }
        if (maxX < 0) { // nothing but background: keep the whole image
            minX = 0;
            minY = 0;
            maxX = w - 1;
            maxY = h - 1;
        }
        int cw = maxX - minX + 1;
        int ch = maxY - minY + 1;

        int content = (int) Math.round(NORMALIZED_MAX * (1 - 2 * PADDING));
        double scale = Math.min(1.0, (double) content / Math.max(cw, ch));
        int dw = Math.max(1, (int) Math.round(cw * scale));
        int dh = Math.max(1, (int) Math.round(ch * scale));
        int side = scale < 1.0 ? NORMALIZED_MAX : (int) Math.ceil(Math.max(cw, ch) / (1 - 2 * PADDING));

        BufferedImage square = new BufferedImage(side, side, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = square.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        int ox = (side - dw) / 2;
        int oy = (side - dh) / 2;
        g.drawImage(image, ox, oy, ox + dw, oy + dh, minX, minY, maxX + 1, maxY + 1, null);
        g.dispose();
        return square;
    }

    /** SHA-256 over the kind, size and raw pixels of the normalized square; first 12 hex characters. */
    static String hash(ImageKind kind, BufferedImage square) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update(kind.name().getBytes(StandardCharsets.US_ASCII));
            int w = square.getWidth();
            int h = square.getHeight();
            digest.update(ByteBuffer.allocate(8).putInt(w).putInt(h).array());
            int[] px = square.getRGB(0, 0, w, h, null, 0, w);
            ByteBuffer buffer = ByteBuffer.allocate(px.length * 4);
            buffer.asIntBuffer().put(px);
            digest.update(buffer.array());
            return HexFormat.of().formatHex(digest.digest()).substring(0, 12);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    /** The most common colour among opaque pixels (quantized to 16 levels per channel, then averaged). */
    static String dominantColour(BufferedImage square) {
        int w = square.getWidth();
        int h = square.getHeight();
        int[] px = square.getRGB(0, 0, w, h, null, 0, w);
        Map<Integer, long[]> buckets = new HashMap<>();
        int step = Math.max(1, (int) Math.sqrt((double) px.length / 40_000)); // sample ~40k pixels
        for (int i = 0; i < px.length; i += step) {
            int p = px[i];
            if ((p >>> 24) < 200) {
                continue;
            }
            int r = (p >> 16) & 0xFF;
            int g = (p >> 8) & 0xFF;
            int b = p & 0xFF;
            int key = (r >> 4) << 8 | (g >> 4) << 4 | (b >> 4);
            long[] acc = buckets.computeIfAbsent(key, k -> new long[4]);
            acc[0] += r;
            acc[1] += g;
            acc[2] += b;
            acc[3]++;
        }
        return buckets.values().stream()
                .max((x, y) -> Long.compare(x[3], y[3]))
                .map(acc -> String.format("#%02X%02X%02X", acc[0] / acc[3], acc[1] / acc[3], acc[2] / acc[3]))
                .orElse("#FFFFFF");
    }

}
