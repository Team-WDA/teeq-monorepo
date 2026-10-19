package kr.co.teeq.api.home.application.service;

import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.aicharacter.application.service.AiCharacterService;
import kr.co.teeq.api.call.application.service.CallLimitService;
import kr.co.teeq.api.feedback.application.service.CallFeedbackService;
import kr.co.teeq.api.home.application.dto.response.HomeResponse;
import kr.co.teeq.api.member.core.entity.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * 홈 화면 조립. 인사말 생성 중 AI 서버를 호출하고 저장 충돌을 재조회로 복구하므로
 * 이 서비스에도 {@code DailyGreetingService}에도 트랜잭션을 걸지 않는다.
 */
@Service
@RequiredArgsConstructor
public class HomeService {

    private final AiCharacterService aiCharacterService;
    private final DailyGreetingService dailyGreetingService;
    private final CallLimitService callLimitService;
    private final CallFeedbackService callFeedbackService;

    public HomeResponse getHome(Member member) {
        // 캐릭터가 없으면 AI_CHARACTER_NOT_FOUND가 그대로 전파된다
        AiCharacterResponse character = aiCharacterService.get(member);
        String greeting = dailyGreetingService.getOrCreate(member, character);
        return new HomeResponse(character.name(), character.personalityTags(), greeting,
            callLimitService.getTodayStatus(member),
            callFeedbackService.findPendingFeedback(member).orElse(null));
    }

}
