package com.tayran.service.impl;

import com.tayran.dao.entity.User;
import com.tayran.dao.repository.AddressRepository;
import com.tayran.dao.repository.UserRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.AuthResponse;
import com.tayran.model.OtpChallengeResponse;
import com.tayran.model.TayranConst;
import com.tayran.model.TokenPair;
import com.tayran.service.AuthService;
import com.tayran.service.NextStepResolver;
import com.tayran.service.OtpService;
import com.tayran.service.TokenService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final OtpService otpService;
    private final TokenService tokenService;
    private final UserRepository userRepository;
    private final AddressRepository addressRepository;
    private final NextStepResolver nextStepResolver;

    @Override
    public OtpChallengeResponse requestOtp(String phone) {
        return otpService.requestOtp(phone);
    }

    @Override
    @Transactional(noRollbackFor = BusinessException.class)
    public AuthResponse verifyOtp(UUID challengeId, String code) {
        String phone = otpService.verifyOtp(challengeId, code);
        User user = userRepository.findByPhone(phone).orElseGet(() -> userRepository.save(new User(phone)));
        return toAuthResponse(user, tokenService.issue(user.getId()));
    }

    @Override
    @Transactional(noRollbackFor = BusinessException.class)
    public AuthResponse refresh(String refreshToken) {
        TokenPair pair = tokenService.rotate(refreshToken);
        User user = userRepository.findById(pair.userId())
                .orElseThrow(() -> new BusinessException(TayranConst.UNAUTHORIZED));
        return toAuthResponse(user, pair);
    }

    private AuthResponse toAuthResponse(User user, TokenPair pair) {
        boolean hasAddress = addressRepository.existsByUserIdAndDefaultAddressTrue(user.getId());
        return new AuthResponse(pair.accessToken(), pair.refreshToken(), nextStepResolver.resolve(user, hasAddress));
    }
}
