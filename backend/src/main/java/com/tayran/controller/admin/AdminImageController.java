package com.tayran.controller.admin;

import com.tayran.exception.BusinessException;
import com.tayran.model.ImageKind;
import com.tayran.model.ResponsePojo;
import com.tayran.model.TayranConst;
import com.tayran.service.impl.ImageIngestService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * Step one of attaching an image: upload, get {hash, bg, previewUrl} back, show the preview, then
 * send the hash with the category or product.
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/images")
public class AdminImageController {

    private final ImageIngestService imageIngestService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ResponsePojo> upload(@RequestParam String kind, @RequestPart("file") MultipartFile file) throws IOException {
        ImageKind imageKind;
        try {
            imageKind = ImageKind.valueOf(kind.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BusinessException(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of("kind")));
        }
        return ResponseEntity.ok(ResponsePojo.ok(imageIngestService.ingest(imageKind, file.getBytes())));
    }
}
