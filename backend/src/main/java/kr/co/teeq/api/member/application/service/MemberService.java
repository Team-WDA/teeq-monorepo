package kr.co.teeq.api.member.application.service;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.application.dto.request.ChangeNicknameRequest;
import kr.co.teeq.api.member.application.dto.request.SignupCompletionRequest;
import kr.co.teeq.api.member.application.dto.response.MemberResponse;
import kr.co.teeq.api.member.application.dto.response.NicknameAvailabilityResponse;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.port.AiCharacterExistencePort;
import kr.co.teeq.api.member.core.port.ProfileImageStoragePort;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import kr.co.teeq.api.member.core.repository.ProfileImageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MemberService {

    // 마이그레이션의 partial unique index 이름과 같아야 한다
    private static final String NICKNAME_INDEX_NAME = "uq_member_nickname_active";

    private final MemberRepository memberRepository;
    private final AiCharacterExistencePort aiCharacterExistencePort;
    private final ProfileImageRepository profileImageRepository;
    private final ProfileImageStoragePort profileImageStoragePort;

    @Transactional(readOnly = true)
    public NicknameAvailabilityResponse checkNicknameAvailability(String nickname) {
        boolean taken = memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(nickname).isPresent();
        return new NicknameAvailabilityResponse(!taken);
    }

    @Transactional(readOnly = true)
    public MemberResponse getMe(Member member) {
        return toResponse(member);
    }

    // 컨트롤러가 넘긴 엔티티는 분리 상태라 수정 전에 id로 다시 조회한다. 자신의 닉네임을 대소문자만 바꾸는 것은 중복이 아니다
    @Transactional
    public MemberResponse changeNickname(Member authenticatedMember, ChangeNicknameRequest request) {
        Member member = findActiveMember(authenticatedMember);
        validateNicknameNotTaken(member, request.nickname());
        member.changeNickname(request.nickname());
        flushNicknameChange(member);
        return toResponse(member);
    }

    // 소셜 첫 로그인으로 만들어진 닉네임 NULL 회원만 완료할 수 있다. 약관 동의는 요청 검증에서 true로 보장된다
    @Transactional
    public MemberResponse completeSignup(Member authenticatedMember, SignupCompletionRequest request) {
        Member member = findActiveMember(authenticatedMember);
        if (member.isSignupCompleted()) {
            throw new CustomException(ErrorCode.STATE_CONFLICT);
        }
        validateNicknameNotTaken(member, request.nickname());
        member.completeSignup(request.nickname());
        flushNicknameChange(member);
        return toResponse(member);
    }

    private Member findActiveMember(Member authenticatedMember) {
        return memberRepository.findByIdAndDeletedFalse(authenticatedMember.getId())
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));
    }

    private void validateNicknameNotTaken(Member member, String nickname) {
        memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(nickname)
            .filter(found -> !found.getId().equals(member.getId()))
            .ifPresent(found -> {
                throw new CustomException(ErrorCode.DUPLICATE_NICKNAME);
            });
    }

    // 중복 검사와 저장 사이에 다른 회원이 선점하면 partial unique index 위반을 닉네임 중복으로 바꾼다
    private void flushNicknameChange(Member member) {
        try {
            memberRepository.saveAndFlush(member);
        } catch (DataIntegrityViolationException exception) {
            String message = String.valueOf(exception.getMostSpecificCause().getMessage());
            if (message.contains(NICKNAME_INDEX_NAME)) {
                throw new CustomException(ErrorCode.DUPLICATE_NICKNAME, exception);
            }
            throw exception;
        }
    }

    private MemberResponse toResponse(Member member) {
        String profileImageUrl = profileImageRepository.findByMemberIdAndDeletedFalse(member.getId())
            .map(image -> profileImageStoragePort.urlFor(image.getStorageKey()))
            .orElse(null);
        return MemberResponse.from(member, aiCharacterExistencePort.existsByMemberId(member.getId()), profileImageUrl);
    }

}
