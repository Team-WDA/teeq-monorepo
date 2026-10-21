package kr.co.teeq.api.onboarding.application.service;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.core.repository.OnboardingSubmissionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 회원의 현재 persona 조회. 통화 시작과 홈 한마디가 AI 서버에 보낼 personaId를 얻는다.
 */
@Service
@RequiredArgsConstructor
public class OnboardingPersonaService {

    private final OnboardingSubmissionRepository onboardingSubmissionRepository;

    /**
     * 회원의 가장 최근 온보딩 제출의 personaId를 돌려준다. 제출이 없으면 AI_CHARACTER_NOT_FOUND.
     */
    @Transactional(readOnly = true)
    public String getCurrentPersonaId(Member member) {
        return onboardingSubmissionRepository
                .findFirstByMemberIdAndDeletedFalseOrderByCreatedAtDescIdDesc(member.getId())
                .orElseThrow(() -> new CustomException(ErrorCode.AI_CHARACTER_NOT_FOUND))
                .getPersonaId();
    }
}
