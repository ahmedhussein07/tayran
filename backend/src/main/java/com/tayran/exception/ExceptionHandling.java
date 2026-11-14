package com.tayran.exception;

import com.tayran.model.ErrorDto;
import com.tayran.model.ResponsePojo;
import com.tayran.model.TayranConst;
import com.tayran.utils.files.ConfigError;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.List;
import java.util.Map;

/** Global error handler: every error leaves as the unified {@link ResponsePojo} with a stable code. */
@Slf4j
@RestControllerAdvice
@RequiredArgsConstructor
public class ExceptionHandling {

    private final ConfigError configError;

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ResponsePojo> handleBusiness(BusinessException ex) {
        return respond(ex.getCode(), ex.getDetails());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ResponsePojo> handleValidation(MethodArgumentNotValidException ex) {
        List<String> fields = ex.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getField).distinct().sorted().toList();
        return respond(TayranConst.VALIDATION_ERROR, Map.of("fields", fields));
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, MissingServletRequestParameterException.class,
            MissingRequestHeaderException.class, MethodArgumentTypeMismatchException.class})
    public ResponseEntity<ResponsePojo> handleBadRequest(Exception ex) {
        log.debug("Bad request: {}", ex.getMessage());
        return respond(TayranConst.VALIDATION_ERROR, Map.of("fields", List.of()));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ResponsePojo> handleNotFound(NoResourceFoundException ex) {
        return respond(TayranConst.NOT_FOUND, null);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ResponsePojo> handleMethodNotAllowed(HttpRequestMethodNotSupportedException ex) {
        return respond(TayranConst.METHOD_NOT_ALLOWED, null);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ResponsePojo> handleUnexpected(Exception ex) {
        log.error("Unexpected error", ex);
        return respond(TayranConst.INTERNAL_ERROR, null);
    }

    private ResponseEntity<ResponsePojo> respond(String code, Object content) {
        ErrorDto error = configError.get(code);
        return ResponseEntity.status(configError.statusOf(error)).body(ResponsePojo.error(error, content));
    }
}
