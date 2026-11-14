package com.tayran.service.impl;

import com.tayran.config.properties.OtpProperties;
import com.tayran.dao.entity.OtpChallenge;
import com.tayran.dao.repository.OtpChallengeRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.OtpChallengeResponse;
import com.tayran.model.TayranConst;
import com.tayran.support.MutableClock;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class OtpServiceImplTest {

    private static final String PHONE = "+201012345678";

    private final OtpProperties properties = new OtpProperties("test-secret", 4, Duration.ofMinutes(5),
            Duration.ofSeconds(30), 5, 5, Duration.ofHours(1), false);
    private final MutableClock clock = new MutableClock(Instant.parse("2026-11-14T10:00:00Z"));
    private final List<OtpChallenge> rows = new ArrayList<>();
    private final List<String> sentCodes = new ArrayList<>();
    private OtpServiceImpl service;

    @BeforeEach
    void setUp() {
        OtpChallengeRepository repository = inMemoryRepository();
        service = new OtpServiceImpl(repository, (phone, code) -> sentCodes.add(code), properties, clock);
    }

    @Nested
    class Request {

        @Test
        void sendsAFourDigitCodeAndStoresOnlyItsHash() {
            OtpChallengeResponse response = service.requestOtp("010 1234 5678");

            assertThat(response.getExpiresInSeconds()).isEqualTo(300);
            assertThat(response.getResendAfterSeconds()).isEqualTo(30);
            assertThat(sentCodes).hasSize(1);
            String code = sentCodes.getFirst();
            assertThat(code).matches("\\d{4}");

            OtpChallenge stored = rows.getFirst();
            assertThat(stored.getId()).isEqualTo(response.getChallengeId());
            assertThat(stored.getPhone()).isEqualTo(PHONE);
            assertThat(stored.getCodeHash()).hasSize(64).doesNotContain(code);
            assertThat(stored.getExpiresAt()).isEqualTo(clock.instant().plus(Duration.ofMinutes(5)));
        }

        @Test
        void rejectsAnInvalidPhone() {
            assertThatThrownBy(() -> service.requestOtp("01312345678"))
                    .isInstanceOf(BusinessException.class).hasMessage(TayranConst.INVALID_PHONE);
        }

        @Test
        void resendWithin30SecondsIsTooSoon() {
            service.requestOtp(PHONE);
            clock.advance(Duration.ofSeconds(29));

            assertThatThrownBy(() -> service.requestOtp(PHONE))
                    .isInstanceOf(BusinessException.class)
                    .hasMessage(TayranConst.OTP_RESEND_TOO_SOON)
                    .extracting(e -> ((BusinessException) e).getDetails().get("retryAfterSeconds"))
                    .isEqualTo(1L);
        }

        @Test
        void resendAfter30SecondsSupersedesThePreviousCode() {
            UUID first = service.requestOtp(PHONE).getChallengeId();
            String firstCode = sentCodes.getFirst();
            clock.advance(Duration.ofSeconds(30));

            service.requestOtp(PHONE);

            assertThat(rows).hasSize(2);
            assertThatThrownBy(() -> service.verifyOtp(first, firstCode))
                    .isInstanceOf(BusinessException.class).hasMessage(TayranConst.OTP_EXPIRED);
        }

        @Test
        void sixthRequestWithinAnHourIsRateLimited() {
            for (int i = 0; i < 5; i++) {
                service.requestOtp(PHONE);
                clock.advance(Duration.ofMinutes(1));
            }

            assertThatThrownBy(() -> service.requestOtp(PHONE))
                    .isInstanceOf(BusinessException.class)
                    .hasMessage(TayranConst.OTP_RATE_LIMITED)
                    // the oldest of the five leaves the window 55 minutes from now
                    .extracting(e -> ((BusinessException) e).getDetails().get("retryAfterSeconds"))
                    .isEqualTo(Duration.ofMinutes(55).toSeconds());
        }

        @Test
        void rateLimitIsPerPhoneAndSlidesWithTheWindow() {
            for (int i = 0; i < 5; i++) {
                service.requestOtp(PHONE);
                clock.advance(Duration.ofMinutes(1));
            }
            service.requestOtp("01112345678"); // another phone is not affected

            clock.advance(Duration.ofMinutes(55)); // the first request is now an hour old
            service.requestOtp(PHONE);

            assertThat(sentCodes).hasSize(7);
        }
    }

    @Nested
    class Verify {

        @Test
        void correctCodeReturnsThePhoneAndConsumesTheChallenge() {
            UUID id = service.requestOtp(PHONE).getChallengeId();

            assertThat(service.verifyOtp(id, sentCodes.getFirst())).isEqualTo(PHONE);
            assertThatThrownBy(() -> service.verifyOtp(id, sentCodes.getFirst()))
                    .isInstanceOf(BusinessException.class).hasMessage(TayranConst.OTP_EXPIRED);
        }

        @Test
        void wrongCodeCountsTheAttemptAndReportsWhatIsLeft() {
            UUID id = service.requestOtp(PHONE).getChallengeId();

            assertThatThrownBy(() -> service.verifyOtp(id, wrong()))
                    .isInstanceOf(BusinessException.class)
                    .hasMessage(TayranConst.OTP_INVALID)
                    .extracting(e -> ((BusinessException) e).getDetails().get("remainingAttempts"))
                    .isEqualTo(4);
            assertThat(rows.getFirst().getAttempts()).isEqualTo(1);
        }

        @Test
        void fifthWrongCodeLocksTheChallengeEvenForTheRightCode() {
            UUID id = service.requestOtp(PHONE).getChallengeId();
            for (int i = 0; i < 4; i++) {
                assertThatThrownBy(() -> service.verifyOtp(id, wrong())).hasMessage(TayranConst.OTP_INVALID);
            }

            assertThatThrownBy(() -> service.verifyOtp(id, wrong())).hasMessage(TayranConst.OTP_TOO_MANY_ATTEMPTS);
            assertThatThrownBy(() -> service.verifyOtp(id, sentCodes.getFirst())).hasMessage(TayranConst.OTP_TOO_MANY_ATTEMPTS);
        }

        @Test
        void codeExpiresAfterFiveMinutes() {
            UUID id = service.requestOtp(PHONE).getChallengeId();
            clock.advance(Duration.ofMinutes(5));

            assertThatThrownBy(() -> service.verifyOtp(id, sentCodes.getFirst())).hasMessage(TayranConst.OTP_EXPIRED);
        }

        @Test
        void codeStillWorksJustBeforeExpiry() {
            UUID id = service.requestOtp(PHONE).getChallengeId();
            clock.advance(Duration.ofMinutes(5).minusSeconds(1));

            assertThat(service.verifyOtp(id, sentCodes.getFirst())).isEqualTo(PHONE);
        }

        @Test
        void unknownChallengeIsTreatedAsExpired() {
            assertThatThrownBy(() -> service.verifyOtp(UUID.randomUUID(), "1234")).hasMessage(TayranConst.OTP_EXPIRED);
        }

        private String wrong() {
            String right = sentCodes.getLast();
            return right.equals("0000") ? "1111" : "0000";
        }
    }

    /** A Mockito-backed repository that keeps rows in a list, enough for the queries the service uses. */
    private OtpChallengeRepository inMemoryRepository() {
        OtpChallengeRepository repository = mock(OtpChallengeRepository.class);
        when(repository.lockPhone(anyString())).thenReturn(1L);
        when(repository.save(any(OtpChallenge.class))).thenAnswer(invocation -> {
            OtpChallenge challenge = invocation.getArgument(0);
            if (!rows.contains(challenge)) {
                rows.add(challenge);
            }
            return challenge;
        });
        when(repository.findFirstByPhoneOrderByCreatedOnDesc(anyString())).thenAnswer(invocation ->
                byPhone(invocation.getArgument(0)).max(Comparator.comparing(OtpChallenge::getCreatedOn)));
        when(repository.countByPhoneAndCreatedOnAfter(anyString(), any(Instant.class))).thenAnswer(invocation ->
                byPhone(invocation.getArgument(0)).filter(c -> c.getCreatedOn().isAfter(invocation.getArgument(1))).count());
        when(repository.findFirstByPhoneAndCreatedOnAfterOrderByCreatedOnAsc(anyString(), any(Instant.class))).thenAnswer(invocation ->
                byPhone(invocation.getArgument(0)).filter(c -> c.getCreatedOn().isAfter(invocation.getArgument(1)))
                        .min(Comparator.comparing(OtpChallenge::getCreatedOn)));
        when(repository.supersedeOpenChallenges(anyString(), any(Instant.class))).thenAnswer(invocation -> {
            List<OtpChallenge> open = byPhone(invocation.getArgument(0)).filter(c -> !c.isClosed()).toList();
            open.forEach(c -> c.setSupersededAt(invocation.getArgument(1)));
            return open.size();
        });
        when(repository.findByIdForUpdate(any(UUID.class))).thenAnswer(invocation ->
                rows.stream().filter(c -> c.getId().equals(invocation.getArgument(0))).findFirst());
        return repository;
    }

    private Stream<OtpChallenge> byPhone(String phone) {
        return rows.stream().filter(c -> c.getPhone().equals(phone));
    }
}
