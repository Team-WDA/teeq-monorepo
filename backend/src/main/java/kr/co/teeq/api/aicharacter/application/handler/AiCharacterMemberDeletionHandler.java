package kr.co.teeq.api.aicharacter.application.handler;

import java.time.Clock;
import kr.co.teeq.api.aicharacter.core.entity.AiCharacter;
import kr.co.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import kr.co.teeq.api.member.core.event.HandlesMemberDeletion;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 회원 삭제 시 AI 캐릭터를 soft delete 한다.
 */
@Component
@RequiredArgsConstructor
@HandlesMemberDeletion(entities = AiCharacter.class)
public class AiCharacterMemberDeletionHandler {

    private final AiCharacterRepository aiCharacterRepository;
    private final Clock clock;

    @EventListener
    public void handle(MemberDeletedEvent event) {
        aiCharacterRepository.findByMemberId(event.memberId())
            .ifPresent(aiCharacter -> aiCharacter.delete(clock));
    }

}
