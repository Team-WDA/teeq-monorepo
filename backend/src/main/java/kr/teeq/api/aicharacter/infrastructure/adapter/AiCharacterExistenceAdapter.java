package kr.teeq.api.aicharacter.infrastructure.adapter;

import java.util.UUID;
import kr.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import kr.teeq.api.member.core.port.AiCharacterExistencePort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class AiCharacterExistenceAdapter implements AiCharacterExistencePort {

    private final AiCharacterRepository aiCharacterRepository;

    @Override
    public boolean existsByMemberId(UUID memberId) {
        return aiCharacterRepository.existsByMemberId(memberId);
    }

}
