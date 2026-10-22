package kr.co.teeq.api.aicharacter.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;

import kr.co.teeq.api.aicharacter.core.port.AiCharacterGenerationPort;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.web.client.RestClient;

class AiCharacterGenerationAdapterSelectionTest {

    private static final String STUB_ENABLED_KEY = "ai-server.stub-character-enabled";

    private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
        .withUserConfiguration(AiServerCharacterGenerationAdapter.class, StubAiCharacterGenerationAdapter.class)
        .withBean("characterRestClient", RestClient.class, () -> RestClient.builder().build())
        .withBean(AiServerProperties.class,
            () -> new AiServerProperties("http://ai-server.test", "X-Teeq-Server-Key", "dummy-server-key"));

    @Test
    void 설정_키가_없으면_AI_서버_어댑터가_선택된다() {
        contextRunner.run(context -> {
            assertThat(context.getBeansOfType(AiCharacterGenerationPort.class)).hasSize(1);
            assertThat(context.getBean(AiCharacterGenerationPort.class))
                .isInstanceOf(AiServerCharacterGenerationAdapter.class);
        });
    }

    @Test
    void 설정_키가_false면_AI_서버_어댑터가_선택된다() {
        contextRunner.withPropertyValues(STUB_ENABLED_KEY + "=false").run(context -> {
            assertThat(context.getBeansOfType(AiCharacterGenerationPort.class)).hasSize(1);
            assertThat(context.getBean(AiCharacterGenerationPort.class))
                .isInstanceOf(AiServerCharacterGenerationAdapter.class);
        });
    }

    @Test
    void 설정_키가_true면_임시_어댑터만_선택된다() {
        contextRunner.withPropertyValues(STUB_ENABLED_KEY + "=true").run(context -> {
            assertThat(context.getBeansOfType(AiCharacterGenerationPort.class)).hasSize(1);
            assertThat(context.getBean(AiCharacterGenerationPort.class))
                .isInstanceOf(StubAiCharacterGenerationAdapter.class);
        });
    }

    @Test
    void 임시_어댑터_자체는_RestClient와_AI_서버_설정에_의존하지_않는다() {
        new ApplicationContextRunner()
            .withUserConfiguration(AiServerCharacterGenerationAdapter.class, StubAiCharacterGenerationAdapter.class)
            .withPropertyValues(STUB_ENABLED_KEY + "=true")
            .run(context -> {
                assertThat(context).hasNotFailed();
                assertThat(context.getBean(AiCharacterGenerationPort.class))
                    .isInstanceOf(StubAiCharacterGenerationAdapter.class);
            });
    }

    // 실제 앱의 기동 실패는 포트를 주입받는 AiCharacterService의 생성자 주입 실패로 일어난다.
    // 여기서는 포트를 주입받는 쪽이 없으므로 컨텍스트는 뜨고, 어느 어댑터도 등록되지 않는 것만 확인한다
    @Test
    void 설정_값이_true나_false가_아니면_어느_어댑터도_등록되지_않는다() {
        contextRunner.withPropertyValues(STUB_ENABLED_KEY + "=ture").run(context -> {
            assertThat(context).hasNotFailed();
            assertThat(context.getBeansOfType(AiCharacterGenerationPort.class)).isEmpty();
        });
    }

}
