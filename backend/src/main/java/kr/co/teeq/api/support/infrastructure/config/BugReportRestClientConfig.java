package kr.co.teeq.api.support.infrastructure.config;

import java.net.http.HttpClient;
import java.time.Duration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class BugReportRestClientConfig {

    // Discord 웹훅 호출 타임아웃. 설정 키가 아니라 코드 상수다. 재시도하지 않는다
    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(1);
    private static final Duration READ_TIMEOUT = Duration.ofSeconds(2);

    // RestClient.Builder 자동 구성 빈이 없으므로 빌더를 직접 만든다. 웹훅 URL은 호출 시점에 지정한다
    @Bean
    public RestClient bugReportRestClient() {
        JdkClientHttpRequestFactory requestFactory =
                new JdkClientHttpRequestFactory(HttpClient.newBuilder().connectTimeout(CONNECT_TIMEOUT).build());
        requestFactory.setReadTimeout(READ_TIMEOUT);
        return RestClient.builder()
                .requestFactory(requestFactory)
                .build();
    }

}
