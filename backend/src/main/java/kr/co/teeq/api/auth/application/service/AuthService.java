package kr.co.teeq.api.auth.application.service;

import java.time.Clock;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import kr.co.teeq.api.auth.application.dto.request.ChangePasswordRequest;
import kr.co.teeq.api.auth.application.dto.request.LoginRequest;
import kr.co.teeq.api.auth.application.dto.request.RefreshRequest;
import kr.co.teeq.api.auth.application.dto.request.SignUpRequest;
import kr.co.teeq.api.auth.application.dto.request.SocialLoginRequest;
import kr.co.teeq.api.auth.application.dto.response.AuthResponse;
import kr.co.teeq.api.auth.core.port.SocialIdentity;
import kr.co.teeq.api.auth.core.port.SocialIdentityVerifier;
import kr.co.teeq.api.auth.core.port.TokenProvider;
import kr.co.teeq.api.auth.core.repository.RefreshTokenRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import kr.co.teeq.api.member.core.repository.ProfileImageRepository;
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
    private static final String SOCIAL_INDEX_NAME = "uq_member_social_active";

    private final MemberRepository memberRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final TokenProvider tokenProvider;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;
    private final AuthTokenIssuer authTokenIssuer;
    private final SocialLoginCommandService socialLoginCommandService;
    private final List<SocialIdentityVerifier> socialIdentityVerifiers;
    private final ProfileImageRepository profileImageRepository;

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
            .orElseThrow(() -> new CustomException(ErrorCode.INVALID_CREDENTIALS));
        // 소셜 계정은 비밀번호가 없다. 앱이 올바른 로그인 방식으로 안내할 수 있도록 구분해 응답한다
        if (member.getLoginType() != LoginType.EMAIL) {
            throw new CustomException(ErrorCode.LOGIN_METHOD_MISMATCH);
        }
        if (!passwordEncoder.matches(request.password(), member.getPassword())) {
            throw new CustomException(ErrorCode.INVALID_CREDENTIALS);
        }
        return issueTokens(member);
    }

    // 제공자 서버 호출 중에는 DB 커넥션을 잡지 않도록 이 메서드에는 트랜잭션을 걸지 않는다
    public SocialLoginResult socialLogin(SocialLoginRequest request) {
        LoginType loginType = request.socialType().toLoginType();
        SocialIdentityVerifier verifier = socialIdentityVerifiers.stream()
            .filter(candidate -> candidate.loginType() == loginType)
            .findFirst()
            .orElseThrow(() -> new CustomException(ErrorCode.INVALID_REQUEST));
        SocialIdentity identity = verifier.verify(request.credential());
        try {
            return socialLoginCommandService.loginOrSignUp(identity);
        } catch (DataIntegrityViolationException exception) {
            if (!isViolationOf(exception, SOCIAL_INDEX_NAME)) {
                throw toDuplicateException(exception);
            }
            // 같은 계정의 첫 로그인이 동시에 들어와 다른 요청이 먼저 가입한 경우다. 새 트랜잭션에서 한 번 더 시도하면 로그인으로 처리된다
            return socialLoginCommandService.loginOrSignUp(identity);
        }
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
        if (member.getLoginType() != LoginType.EMAIL) {
            throw new CustomException(ErrorCode.STATE_CONFLICT);
        }
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
        // 사진 파일은 지우지 않고 활성 행만 soft delete 한다
        profileImageRepository.findByMemberIdAndDeletedFalse(member.getId())
            .ifPresent(image -> image.delete(clock));
        refreshTokenRepository.deleteByMemberId(member.getId());
    }

    // 컨트롤러가 넘긴 엔티티는 분리 상태라 수정 전에 항상 id로 다시 조회한다
    private Member findActiveMember(Member authenticatedMember) {
        return memberRepository.findByIdAndDeletedFalse(authenticatedMember.getId())
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));
    }

    private AuthResponse issueTokens(Member member) {
        return authTokenIssuer.issue(member);
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private RuntimeException toDuplicateException(DataIntegrityViolationException exception) {
        if (isViolationOf(exception, EMAIL_INDEX_NAME)) {
            return new CustomException(ErrorCode.DUPLICATE_EMAIL, exception);
        }
        if (isViolationOf(exception, NICKNAME_INDEX_NAME)) {
            return new CustomException(ErrorCode.DUPLICATE_NICKNAME, exception);
        }
        return exception;
    }

    private boolean isViolationOf(DataIntegrityViolationException exception, String indexName) {
        return String.valueOf(exception.getMostSpecificCause().getMessage()).contains(indexName);
    }

}
