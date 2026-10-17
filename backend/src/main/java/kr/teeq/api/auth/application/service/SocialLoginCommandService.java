package kr.teeq.api.auth.application.service;

import kr.teeq.api.auth.application.dto.request.SocialLoginRequest;
import kr.teeq.api.auth.core.port.SocialIdentity;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.entity.Member;
import kr.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 검증이 끝난 소셜 사용자 정보로 로그인 또는 가입을 처리한다. 제공자 서버 호출 중에는 DB 트랜잭션을 열지 않으므로
 * 호출은 이 트랜잭션 밖({@link AuthService})에서 끝낸다.
 */
@Service
@RequiredArgsConstructor
public class SocialLoginCommandService {

    private final MemberRepository memberRepository;
    private final AuthTokenIssuer authTokenIssuer;

    // 유니크 인덱스 위반(DataIntegrityViolationException)은 호출한 쪽이 처리한다. 같은 트랜잭션에서는 재조회할 수 없다
    @Transactional
    public SocialLoginResult loginOrSignUp(SocialIdentity identity, SocialLoginRequest request) {
        return memberRepository.findByLoginTypeAndSocialUserIdAndDeletedFalse(identity.loginType(), identity.subject())
            .map(member -> new SocialLoginResult(authTokenIssuer.issue(member), false))
            .orElseGet(() -> new SocialLoginResult(authTokenIssuer.issue(signUp(identity, request)), true));
    }

    private Member signUp(SocialIdentity identity, SocialLoginRequest request) {
        if (memberRepository.existsByEmailAndDeletedFalse(identity.email())) {
            throw new CustomException(ErrorCode.DUPLICATE_EMAIL);
        }
        if (request.nickname() == null || request.serviceTermsAgreed() == null
            || request.privacyPolicyAgreed() == null) {
            throw new CustomException(ErrorCode.SOCIAL_SIGNUP_REQUIRED);
        }
        if (!request.serviceTermsAgreed() || !request.privacyPolicyAgreed()) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
        if (memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(request.nickname()).isPresent()) {
            throw new CustomException(ErrorCode.DUPLICATE_NICKNAME);
        }
        Member member = Member.createSocialMember(identity.loginType(), identity.subject(), identity.email(),
            request.nickname(), request.serviceTermsAgreed(), request.privacyPolicyAgreed());
        return memberRepository.saveAndFlush(member);
    }

}
