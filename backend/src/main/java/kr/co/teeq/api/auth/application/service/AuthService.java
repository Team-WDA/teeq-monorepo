package kr.co.teeq.api.auth.application.service;

import java.util.UUID;
import kr.co.teeq.api.auth.application.dto.request.RefreshRequest;
import kr.co.teeq.api.auth.application.dto.request.LoginRequest;
import kr.co.teeq.api.auth.application.dto.request.SignUpRequest;
import kr.co.teeq.api.auth.application.dto.response.AuthResponse;
import kr.co.teeq.api.auth.core.port.VerifiedIdentity;
import kr.co.teeq.api.auth.core.port.IdentityVerifier;
import kr.co.teeq.api.auth.core.port.TokenProvider;
import kr.co.teeq.api.auth.core.repository.RefreshTokenRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final MemberRepository memberRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final TokenProvider tokenProvider;
    private final AuthTokenIssuer authTokenIssuer;
    private final AuthCommandService authCommandService;
    private final IdentityVerifier identityVerifier;

    // Firebase 검증(외부 호출)은 DB 트랜잭션 밖에서 끝낸다. 그래서 이 메서드에는 트랜잭션을 걸지 않는다
    public AuthResponse login(LoginRequest request) {
        VerifiedIdentity identity = identityVerifier.verify(request.credential());
        return authCommandService.login(identity);
    }

    public AuthResponse signUp(SignUpRequest request) {
        VerifiedIdentity identity = identityVerifier.verify(request.credential());
        return authCommandService.signUp(identity, request.nickname());
    }

    @Transactional
    public AuthResponse refresh(RefreshRequest request) {
        UUID memberId = tokenProvider.parseRefreshToken(request.refreshToken());
        refreshTokenRepository.findByMemberId(memberId)
            .filter(stored -> stored.getToken().equals(request.refreshToken()))
            .orElseThrow(() -> new CustomException(ErrorCode.INVALID_REFRESH_TOKEN));
        Member member = memberRepository.findByIdAndDeletedFalse(memberId)
            .orElseThrow(() -> new CustomException(ErrorCode.INVALID_REFRESH_TOKEN));
        return issueTokens(member);
    }

    @Transactional
    public void logout(Member member) {
        refreshTokenRepository.deleteByMemberId(member.getId());
    }

    private AuthResponse issueTokens(Member member) {
        return authTokenIssuer.issue(member);
    }

}
