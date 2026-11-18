package com.tayran.service.impl;

import com.tayran.dao.entity.ImageRecord;
import com.tayran.dao.repository.ImageRecordRepository;
import com.tayran.dao.repository.StoreRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.ImageKind;
import com.tayran.model.TayranConst;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Clock;

/** Shared by the admin catalog services: dirty-marking and image lookups. */
@Component
@RequiredArgsConstructor
public class CatalogChanges {

    /** One store for now. */
    public static final long DEFAULT_STORE_ID = 1L;

    private final StoreRepository storeRepository;
    private final ImageRecordRepository imageRepository;
    private final Clock clock;

    /** Any create, update, delete or image change: the publisher republishes on its next run. */
    public void markDirty() {
        storeRepository.markAllDirty();
    }

    /**
     * Resolves an uploaded image for a category or product. The background colour always comes from
     * the images table, never from the client.
     *
     * @return the image, or null when {@code hash} is null or blank
     * @throws BusinessException UNKNOWN_IMAGE when the hash is unknown or was uploaded for the other kind
     */
    public ImageRecord image(String hash, ImageKind kind) {
        if (hash == null || hash.isBlank()) {
            return null;
        }
        ImageRecord image = imageRepository.findById(hash.trim())
                .filter(i -> i.getKind() == kind)
                .orElseThrow(() -> new BusinessException(TayranConst.UNKNOWN_IMAGE));
        image.setLastReferencedAt(clock.instant());
        return imageRepository.save(image);
    }
}
