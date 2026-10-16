package kr.teeq.api.auth.application.service;

import java.time.Clock;
import java.util.Locale;
import java.util.UUID;
import kr.teeq.api.auth.application.dto.request.ChangePasswordRequest;
import kr.teeq.api.auth.application.dto.request.LoginRequest;
import kr.teeq.api.auth.application.dto.request.RefreshRequest;
import kr.teeq.api.auth.application.dto.request.SignUpRequest;
import kr.teeq.api.auth.application.dto.response.AuthResponse;
import kr.teeq.api.auth.core.entity.RefreshToken;
import kr.teeq.api.auth.core.port.IssuedRefreshToken;
import kr.teeq.api.auth.core.port.TokenProvider;
import kr.teeq.api.auth.core.repository.RefreshTokenRepository;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.entity.Member;
import kr.teeq.api.member.core.port.AiCharacterExistencePort;
import kr.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    // 마이그레이션의 partial unique index 이름과 같아야 한다. 동시 가입으로 인덱스가 먼저 걸린 경우 409로 바꾼다
    private static final String EMAIL_INDEX_NAME = "uq_member_email_active";
    private static final String NICKNAME_INDEX_NAME = "uq_member_nickname_active";

    private final MemberRepository memberRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final TokenProvider tokenProvider;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;
    private final AiCharacterExistencePort aiCharacterExistencePort;

    @Transactional
    public AuthResponse signUp(SignUpRequest request) {
        String email = normalizeEmail(request.email());
        if (memberRepository.existsByEmailAndDeletedFalse(email)) {
            throw new CustomException(ErrorCode.DUPLICATE_EMAIL);
        }
        if (memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(request.nickname()).isPresent()) {
            throw new CustomException(ErrorCode.DUPLICATE_NICKNAME);
        }
        Member member = Member.builder()
            .email(email)
            .password(passwordEncoder.encode(request.password()))
            .nickname(request.nickname())
            .serviceTermsAgreed(request.serviceTermsAgreed())
            .privacyPolicyAgreed(request.privacyPolicyAgreed())
            .build();
        try {
            member = memberRepository.saveAndFlush(member);
        } catch (DataIntegrityViolationException exception) {
            throw toDuplicateException(exception);
        }
        return issueTokens(member);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        Member member = memberRepository.findByEmailAndDeletedFalse(normalizeEmail(request.email()))
            .filter(found -> passwordEncoder.matches(request.password(), found.getPassword()))
            .orElseThrow(() -> new CustomException(ErrorCode.INVALID_CREDENTIALS));
        return issueTokens(member);
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

    @Transactional
    public AuthResponse changePassword(Member authenticatedMember, ChangePasswordRequest request) {
        Member member = findActiveMember(authenticatedMember);
        if (!passwordEncoder.matches(request.currentPassword(), member.getPassword())) {
            throw new CustomException(ErrorCode.INVALID_CURRENT_PASSWORD);
        }
        member.changePassword(passwordEncoder.encode(request.newPassword()));
        return issueTokens(member);
    }

    @Transactional
    public void deleteAccount(Member authenticatedMember) {
        Member member = findActiveMember(authenticatedMember);
        member.delete(clock);
        refreshTokenRepository.deleteByMemberId(member.getId());
    }

    // 컨트롤러가 넘긴 엔티티는 분리 상태라 수정 전에 항상 id로 다시 조회한다
    private Member findActiveMember(Member authenticatedMember) {
        return memberRepository.findByIdAndDeletedFalse(authenticatedMember.getId())
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));
    }

    private AuthResponse issueTokens(Member member) {
        String accessToken = tokenProvider.issueAccessToken(member.getId());
        IssuedRefreshToken issued = tokenProvider.issueRefreshToken(member.getId());
        refreshTokenRepository.findByMemberId(member.getId()).ifPresentOrElse(
            existing -> existing.rotate(issued.token(), issued.expiresAt()),
            () -> refreshTokenRepository.save(RefreshToken.builder()
                .memberId(member.getId())
                .token(issued.token())
                .expiresAt(issued.expiresAt())
                .build()));
        return AuthResponse.of(accessToken, issued.token(), member,
            aiCharacterExistencePort.existsByMemberId(member.getId()));
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private RuntimeException toDuplicateException(DataIntegrityViolationException exception) {
        String message = String.valueOf(exception.getMostSpecificCause().getMessage());
        if (message.contains(EMAIL_INDEX_NAME)) {
            return new CustomException(ErrorCode.DUPLICATE_EMAIL, exception);
        }
        if (message.contains(NICKNAME_INDEX_NAME)) {
            return new CustomException(ErrorCode.DUPLICATE_NICKNAME, exception);
        }
        return exception;
    }

}
