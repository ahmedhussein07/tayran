package com.tayran.model;

import java.util.List;

/** What an image is for: decides its storage prefix and variant widths. */
public enum ImageKind {
    PRODUCT("p", List.of(160, 320, 640), 320),
    CATEGORY("c", List.of(128, 256), 256);

    private final String prefix;
    private final List<Integer> widths;
    private final int previewWidth;

    ImageKind(String prefix, List<Integer> widths, int previewWidth) {
        this.prefix = prefix;
        this.widths = widths;
        this.previewWidth = previewWidth;
    }

    public List<Integer> widths() {
        return widths;
    }

    /** Object key of one variant, e.g. p/3fa91c0be27d_320.webp. */
    public String key(String hash, int width) {
        return prefix + "/" + hash + "_" + width + ".webp";
    }

    public String previewKey(String hash) {
        return key(hash, previewWidth);
    }

    /** URL template with {hash} and {w} placeholders, for the app. */
    public String template(String cdnBase) {
        String base = cdnBase.endsWith("/") ? cdnBase.substring(0, cdnBase.length() - 1) : cdnBase;
        return base + "/" + prefix + "/{hash}_{w}.webp";
    }
}
