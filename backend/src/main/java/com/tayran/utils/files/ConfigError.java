package com.tayran.utils.files;

import com.tayran.model.ErrorDto;
import com.tayran.model.TayranConst;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Loads files/error-map.json: error code to HTTP status and Arabic/English message. */
@Component
@RequiredArgsConstructor
public class ConfigError {

    private final ObjectMapper objectMapper;
    private Map<String, ErrorDto> errorDtoMap = Map.of();

    @PostConstruct
    public void init() {
        try (InputStream inputStream = ConfigError.class.getResourceAsStream("/files/error-map.json")) {
            List<ErrorDto> errors = objectMapper.readValue(inputStream, new TypeReference<List<ErrorDto>>() {
            });
            errorDtoMap = errors.stream().collect(Collectors.toUnmodifiableMap(ErrorDto::getErrorKey, Function.identity()));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    public ErrorDto get(String code) {
        ErrorDto error = errorDtoMap.get(code);
        return error != null ? error : errorDtoMap.get(TayranConst.INTERNAL_ERROR);
    }

    public HttpStatus statusOf(ErrorDto error) {
        return HttpStatus.valueOf(error.getHttpStatus());
    }
}
