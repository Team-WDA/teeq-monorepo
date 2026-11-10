package kr.co.teeq.api.call.infrastructure.config;

import java.net.http.HttpClient;
import java.time.Duration;
import kr.co.teeq.api.common.infrastructure.properties.AiServerMetricsProperties;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class AiMetricsRestClientConfig {

    // 연결 타임아웃(5초). 설정 키가 아니라 코드 상수다
    private static final Duration CONNECT_TIMEOUT = Duration.ofMillis(5000);

    // RestClient.Builder 자동 구성 빈이 없으므로 빌더를 직접 만든다.
    // 집계 조회는 오래 걸릴 수 있어 읽기 타임아웃만 설정값(기본 15초)을 쓴다
    @Bean
    public RestClient aiMetricsRestClient(AiServerProperties properties, AiServerMetricsProperties metricsProperties) {
        JdkClientHttpRequestFactory requestFactory =
                new JdkClientHttpRequestFactory(HttpClient.newBuilder().connectTimeout(CONNECT_TIMEOUT).build());
        requestFactory.setReadTimeout(metricsProperties.timeout());
        return RestClient.builder()
                .baseUrl(properties.apiBaseUrl())
                .requestFactory(requestFactory)
                .build();
    }

}
