package kr.co.teeq.api.auth.application.service;

import kr.co.teeq.api.auth.application.dto.request.SocialLoginRequest;
import kr.co.teeq.api.auth.core.port.SocialIdentity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
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
            .orElseGet(() -> new SocialLoginResult(authTokenIssuer.issue(signUp(identity)), true));
    }

    private Member signUp(SocialIdentity identity) {
        if (memberRepository.existsByEmailAndDeletedFalse(identity.email())) {
            throw new CustomException(ErrorCode.DUPLICATE_EMAIL);
        }
        Member member = Member.createSocialMember(identity.loginType(), identity.subject(), identity.email());
        return memberRepository.saveAndFlush(member);
    }

}
