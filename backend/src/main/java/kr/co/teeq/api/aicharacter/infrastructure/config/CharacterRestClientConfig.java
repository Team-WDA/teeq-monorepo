package kr.co.teeq.api.aicharacter.infrastructure.config;

import java.net.http.HttpClient;
import java.time.Duration;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class CharacterRestClientConfig {

    // 캐릭터 생성 호출 타임아웃(3초). 설정 키가 아니라 코드 상수다.
    // connect와 read에 각각 적용되므로 합계 상한은 아니다
    private static final Duration TIMEOUT = Duration.ofMillis(3000);

    // RestClient.Builder 자동 구성 빈이 없으므로 빌더를 직접 만든다
    @Bean
    public RestClient characterRestClient(AiServerProperties properties) {
        JdkClientHttpRequestFactory requestFactory =
                new JdkClientHttpRequestFactory(HttpClient.newBuilder().connectTimeout(TIMEOUT).build());
        requestFactory.setReadTimeout(TIMEOUT);
        return RestClient.builder()
                .baseUrl(properties.baseUrl())
                .requestFactory(requestFactory)
                .build();
    }

}
