package kr.teeq.api.auth.infrastructure.adapter;

import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.security.Jwk;
import io.jsonwebtoken.security.JwkSet;
import io.jsonwebtoken.security.Jwks;
import io.jsonwebtoken.security.RsaPublicJwk;
import java.net.http.HttpClient;
import java.security.PublicKey;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

/**
 * Apple 공개키 목록을 조회한다. 공용 {@link RestClient} 빈과 섞이지 않도록 클래스 안에서 직접 만든다.
 */
@Slf4j
@Component
public class AppleJwksClient {

    static final String JWKS_URL = "https://appleid.apple.com/auth/keys";
    private static final Duration TIMEOUT = Duration.ofSeconds(3);

    private final RestClient restClient;

    @Autowired
    public AppleJwksClient() {
        this(RestClient.builder().requestFactory(createRequestFactory()));
    }

    AppleJwksClient(RestClient.Builder restClientBuilder) {
        this.restClient = restClientBuilder.build();
    }

    /**
     * 공개키 목록을 {@code kid} 기준으로 조회한다. RSA 키가 아닌 항목은 건너뛴다.
     *
     * @throws CustomException 조회하거나 해석하지 못하거나 사용할 수 있는 키가 하나도 없으면 SOCIAL_SERVER_UNAVAILABLE
     */
    public Map<String, PublicKey> fetch() {
        try {
            String body = restClient.get().uri(JWKS_URL).retrieve().body(String.class);
            if (body == null || body.isBlank()) {
                log.error("Apple 공개키 응답 본문이 비어 있습니다");
                throw new CustomException(ErrorCode.SOCIAL_SERVER_UNAVAILABLE);
            }
            JwkSet jwkSet = Jwks.setParser().build().parse(body);
            Map<String, PublicKey> keys = new HashMap<>();
            for (Jwk<?> jwk : jwkSet.getKeys()) {
                if (jwk instanceof RsaPublicJwk rsaPublicJwk && jwk.getId() != null) {
                    keys.put(jwk.getId(), rsaPublicJwk.toKey());
                }
            }
            if (keys.isEmpty()) {
                log.error("Apple 공개키 응답에 사용할 수 있는 RSA 키가 없습니다");
                throw new CustomException(ErrorCode.SOCIAL_SERVER_UNAVAILABLE);
            }
            return Map.copyOf(keys);
        } catch (RestClientException | JwtException exception) {
            throw new CustomException(ErrorCode.SOCIAL_SERVER_UNAVAILABLE, exception);
        }
    }

    private static JdkClientHttpRequestFactory createRequestFactory() {
        JdkClientHttpRequestFactory requestFactory =
            new JdkClientHttpRequestFactory(HttpClient.newBuilder().connectTimeout(TIMEOUT).build());
        requestFactory.setReadTimeout(TIMEOUT);
        return requestFactory;
    }

}
