package kr.co.teeq.api.aicharacter.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

import java.util.UUID;
import kr.co.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AiCharacterExistenceAdapterTest {

    private static final UUID MEMBER_ID = UUID.randomUUID();

    @Mock
    private AiCharacterRepository aiCharacterRepository;
    @InjectMocks
    private AiCharacterExistenceAdapter adapter;

    @Test
    void 존재_여부_조회는_이름이_있는_캐릭터만_대상으로_위임한다() {
        given(aiCharacterRepository.existsByMemberIdAndNameIsNotNull(MEMBER_ID)).willReturn(true);

        assertThat(adapter.existsByMemberId(MEMBER_ID)).isTrue();

        verify(aiCharacterRepository).existsByMemberIdAndNameIsNotNull(MEMBER_ID);
    }

}
