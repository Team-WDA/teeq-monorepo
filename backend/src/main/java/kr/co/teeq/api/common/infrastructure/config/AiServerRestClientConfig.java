package kr.co.teeq.api.common.infrastructure.config;

import java.net.http.HttpClient;
import java.time.Duration;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class AiServerRestClientConfig {

    // RestClient.Builder 자동 구성 빈이 없으므로 빌더를 직접 만든다
    @Bean
    public RestClient aiServerRestClient(AiServerProperties properties) {
        Duration timeout = Duration.ofMillis(properties.timeoutMillis());
        JdkClientHttpRequestFactory requestFactory =
                new JdkClientHttpRequestFactory(HttpClient.newBuilder().connectTimeout(timeout).build());
        requestFactory.setReadTimeout(timeout);
        return RestClient.builder()
                .baseUrl(properties.baseUrl())
                .requestFactory(requestFactory)
                .build();
    }

}
