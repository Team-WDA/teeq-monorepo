package kr.teeq.api.member.application.service;

import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.application.dto.request.ChangeNicknameRequest;
import kr.teeq.api.member.application.dto.response.MemberResponse;
import kr.teeq.api.member.application.dto.response.NicknameAvailabilityResponse;
import kr.teeq.api.member.core.entity.Member;
import kr.teeq.api.member.core.repository.MemberRepository;
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

    @Transactional(readOnly = true)
    public NicknameAvailabilityResponse checkNicknameAvailability(String nickname) {
        boolean taken = memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(nickname).isPresent();
        return new NicknameAvailabilityResponse(!taken);
    }

    public MemberResponse getMe(Member member) {
        return MemberResponse.from(member);
    }

    // 컨트롤러가 넘긴 엔티티는 분리 상태라 수정 전에 id로 다시 조회한다. 자신의 닉네임을 대소문자만 바꾸는 것은 중복이 아니다
    @Transactional
    public MemberResponse changeNickname(Member authenticatedMember, ChangeNicknameRequest request) {
        Member member = memberRepository.findByIdAndDeletedFalse(authenticatedMember.getId())
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));
        memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(request.nickname())
            .filter(found -> !found.getId().equals(member.getId()))
            .ifPresent(found -> {
                throw new CustomException(ErrorCode.DUPLICATE_NICKNAME);
            });
        member.changeNickname(request.nickname());
        try {
            memberRepository.saveAndFlush(member);
        } catch (DataIntegrityViolationException exception) {
            String message = String.valueOf(exception.getMostSpecificCause().getMessage());
            if (message.contains(NICKNAME_INDEX_NAME)) {
                throw new CustomException(ErrorCode.DUPLICATE_NICKNAME, exception);
            }
            throw exception;
        }
        return MemberResponse.from(member);
    }

}
