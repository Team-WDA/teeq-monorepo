package kr.co.teeq.api.auth.application.service;

import java.util.Optional;
import kr.co.teeq.api.auth.application.dto.response.AuthResponse;
import kr.co.teeq.api.auth.core.port.VerifiedIdentity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 검증이 끝난 사용자 정보로 로그인 또는 가입을 처리한다. 검증 서버 호출 중에는 DB 트랜잭션을 열지 않으므로
 * 호출은 이 트랜잭션 밖({@link AuthService})에서 끝낸다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthCommandService {

    // 마이그레이션의 partial unique index 이름과 같아야 한다. 동시 가입으로 인덱스가 먼저 걸린 경우 409로 바꾼다
    private static final String NICKNAME_INDEX_NAME = "uq_member_nickname_active";
    private static final String FIREBASE_UID_INDEX_NAME = "uq_member_firebase_uid_active";

    private final MemberRepository memberRepository;
    private final AuthTokenIssuer authTokenIssuer;

    @Transactional
    public AuthResponse login(VerifiedIdentity identity) {
        Member member = findActiveMember(identity)
            .orElseThrow(() -> new CustomException(ErrorCode.AUTH_SIGNUP_REQUIRED));
        // 같은 uid인데 가입 때와 다른 제공자의 토큰이면 거절한다. 토큰과 uid 값은 로그에 남기지 않는다
        if (member.getLoginType() != identity.loginType()) {
            log.warn("로그인 제공자 불일치: memberId={}, storedLoginType={}, tokenLoginType={}",
                member.getId(), member.getLoginType(), identity.loginType());
            throw new CustomException(ErrorCode.AUTH_TOKEN_INVALID);
        }
        return authTokenIssuer.issue(member);
    }

    // 약관 동의는 요청 검증에서 true로 보장되므로 동의한 상태로 저장한다
    @Transactional
    public AuthResponse signUp(VerifiedIdentity identity, String nickname) {
        if (findActiveMember(identity).isPresent()) {
            throw new CustomException(ErrorCode.STATE_CONFLICT);
        }
        if (memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(nickname).isPresent()) {
            throw new CustomException(ErrorCode.DUPLICATE_NICKNAME);
        }
        Member member = Member.createMember(identity.loginType(), identity.subject(), identity.email(), nickname);
        try {
            member = memberRepository.saveAndFlush(member);
        } catch (DataIntegrityViolationException exception) {
            throw toConflictException(exception);
        }
        return authTokenIssuer.issue(member);
    }

    private Optional<Member> findActiveMember(VerifiedIdentity identity) {
        return memberRepository.findByFirebaseUidAndDeletedFalse(identity.subject());
    }

    private RuntimeException toConflictException(DataIntegrityViolationException exception) {
        String message = String.valueOf(exception.getMostSpecificCause().getMessage());
        if (message.contains(FIREBASE_UID_INDEX_NAME)) {
            return new CustomException(ErrorCode.STATE_CONFLICT, exception);
        }
        if (message.contains(NICKNAME_INDEX_NAME)) {
            return new CustomException(ErrorCode.DUPLICATE_NICKNAME, exception);
        }
        return exception;
    }

}
