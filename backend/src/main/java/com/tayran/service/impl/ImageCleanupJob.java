package com.tayran.service.impl;

import com.tayran.dao.entity.ImageRecord;
import com.tayran.dao.repository.ImageRecordRepository;
import com.tayran.integration.storage.ObjectStorage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Duration;
import java.util.List;

/** Weekly: deletes the files and rows of images no category or product has referenced for 30 days. */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImageCleanupJob {

    static final Duration UNREFERENCED_FOR = Duration.ofDays(30);

    private final ImageRecordRepository imageRepository;
    private final ObjectStorage storage;
    private final Clock clock;

    @Scheduled(cron = "${app.image-cleanup-cron:0 30 3 * * SUN}")
    @Transactional
    public int run() {
        List<ImageRecord> stale = imageRepository.findUnreferencedSince(clock.instant().minus(UNREFERENCED_FOR));
        for (ImageRecord image : stale) {
            for (int width : image.getKind().widths()) {
                storage.delete(image.getKind().key(image.getHash(), width));
            }
            imageRepository.delete(image);
        }
        if (!stale.isEmpty()) {
            log.info("Image cleanup removed {} unreferenced images", stale.size());
        }
        return stale.size();
    }
}
