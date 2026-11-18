package com.tayran.config.security;

import com.tayran.model.ErrorDto;
import com.tayran.model.ResponsePojo;
import com.tayran.model.TayranConst;
import com.tayran.utils.files.ConfigError;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/** Writes 401 responses in the unified format: TOKEN_EXPIRED or UNAUTHORIZED. */
@Component
@RequiredArgsConstructor
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint, AccessDeniedHandler {

    private final ConfigError configError;
    private final ObjectMapper objectMapper;

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException authException) throws IOException {
        Object reason = request.getAttribute(JwtAuthenticationFilter.AUTH_ERROR_ATTRIBUTE);
        write(response, TayranConst.TOKEN_EXPIRED.equals(reason) ? TayranConst.TOKEN_EXPIRED : TayranConst.UNAUTHORIZED);
    }

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response,
                       AccessDeniedException accessDeniedException) throws IOException {
        // Signed in, but not allowed (for example a customer token on an admin endpoint).
        write(response, TayranConst.FORBIDDEN);
    }

    private void write(HttpServletResponse response, String code) throws IOException {
        ErrorDto error = configError.get(code);
        response.setStatus(error.getHttpStatus());
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getOutputStream(), ResponsePojo.error(error, null));
    }
}
