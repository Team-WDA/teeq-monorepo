package kr.co.teeq.api.auth.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Jwks;
import java.security.KeyPair;
import java.security.PublicKey;
import java.security.interfaces.ECPublicKey;
import java.security.interfaces.RSAPublicKey;
import java.util.Map;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class AppleJwksClientTest {

    private MockRestServiceServer server;
    private AppleJwksClient client;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder();
        server = MockRestServiceServer.bindTo(builder).build();
        client = new AppleJwksClient(builder);
    }

    private void respondWith(String body) {
        server.expect(requestTo(AppleJwksClient.JWKS_URL))
            .andRespond(withSuccess(body, MediaType.APPLICATION_JSON));
    }

    private void assertUnavailable() {
        assertThatThrownBy(() -> client.fetch())
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.SOCIAL_SERVER_UNAVAILABLE));
    }

    @Test
    void fetch_rsaAndEcKeys_returnsOnlyRsaKeyById() {
        KeyPair rsaKeyPair = Jwts.SIG.RS256.keyPair().build();
        KeyPair ecKeyPair = Jwts.SIG.ES256.keyPair().build();
        String rsaJwk = Jwks.json(Jwks.builder().key((RSAPublicKey) rsaKeyPair.getPublic()).id("rsa-key").build());
        String ecJwk = Jwks.json(Jwks.builder().key((ECPublicKey) ecKeyPair.getPublic()).id("ec-key").build());
        respondWith("{\"keys\":[" + rsaJwk + "," + ecJwk + "]}");

        Map<String, PublicKey> keys = client.fetch();

        assertThat(keys).containsOnlyKeys("rsa-key");
        assertThat(keys.get("rsa-key")).isEqualTo(rsaKeyPair.getPublic());
    }

    @Test
    void fetch_serverError_throwsServerUnavailable() {
        server.expect(requestTo(AppleJwksClient.JWKS_URL)).andRespond(withServerError());

        assertUnavailable();
    }

    @Test
    void fetch_emptyBody_throwsServerUnavailable() {
        respondWith("");

        assertUnavailable();
    }

    @Test
    void fetch_malformedJson_throwsServerUnavailable() {
        respondWith("{not-json");

        assertUnavailable();
    }

    @Test
    void fetch_emptyKeySet_throwsServerUnavailable() {
        respondWith("{\"keys\":[]}");

        assertUnavailable();
    }

}
