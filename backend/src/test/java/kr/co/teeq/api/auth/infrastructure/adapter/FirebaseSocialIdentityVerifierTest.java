package kr.co.teeq.api.auth.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.mock;

import com.google.firebase.auth.AuthErrorCode;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import java.util.HashMap;
import java.util.Map;
import kr.co.teeq.api.auth.core.port.SocialIdentity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class FirebaseSocialIdentityVerifierTest {

    private static final String CREDENTIAL = "firebase-id-token";

    private FirebaseAuth firebaseAuth;
    private FirebaseSocialIdentityVerifier verifier;

    @BeforeEach
    void setUp() {
        firebaseAuth = mock(FirebaseAuth.class);
        verifier = new FirebaseSocialIdentityVerifier(firebaseAuth);
    }

    private FirebaseToken token(String uid, String email, String signInProvider) {
        FirebaseToken token = mock(FirebaseToken.class);
        Map<String, Object> claims = new HashMap<>();
        if (signInProvider != null) {
            claims.put("firebase", Map.of("sign_in_provider", signInProvider));
        }
        given(token.getUid()).willReturn(uid);
        given(token.getEmail()).willReturn(email);
        given(token.getClaims()).willReturn(claims);
        return token;
    }

    private FirebaseAuthException authException(AuthErrorCode authErrorCode) {
        return new FirebaseAuthException(com.google.firebase.ErrorCode.UNAUTHENTICATED, "detail", null, null, authErrorCode);
    }

    private void assertErrorCode(Throwable thrown, ErrorCode expected) {
        assertThat(thrown).isInstanceOfSatisfying(CustomException.class,
            exception -> assertThat(exception.getErrorCode()).isEqualTo(expected));
    }

    @Test
    void appleProvider_mapsToAppleIdentityWithNormalizedEmail() throws Exception {
        FirebaseToken stubbedToken = token("uid-1", " Soyeon@Teeq.com ", "apple.com");
        given(firebaseAuth.verifyIdToken(CREDENTIAL)).willReturn(stubbedToken);

        SocialIdentity identity = verifier.verify(CREDENTIAL);

        assertThat(identity.loginType()).isEqualTo(LoginType.APPLE);
        assertThat(identity.subject()).isEqualTo("uid-1");
        assertThat(identity.email()).isEqualTo("soyeon@teeq.com");
    }

    @Test
    void googleProvider_mapsToGoogleIdentity() throws Exception {
        FirebaseToken stubbedToken = token("uid-2", "soyeon@teeq.com", "google.com");
        given(firebaseAuth.verifyIdToken(CREDENTIAL)).willReturn(stubbedToken);

        assertThat(verifier.verify(CREDENTIAL).loginType()).isEqualTo(LoginType.GOOGLE);
    }

    @Test
    void unsupportedProvider_throwsTokenInvalid() throws Exception {
        FirebaseToken stubbedToken = token("uid-3", "soyeon@teeq.com", "password");
        given(firebaseAuth.verifyIdToken(CREDENTIAL)).willReturn(stubbedToken);

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.SOCIAL_TOKEN_INVALID));
    }

    @Test
    void missingProviderClaim_throwsTokenInvalid() throws Exception {
        FirebaseToken stubbedToken = token("uid-4", "soyeon@teeq.com", null);
        given(firebaseAuth.verifyIdToken(CREDENTIAL)).willReturn(stubbedToken);

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.SOCIAL_TOKEN_INVALID));
    }

    @Test
    void missingOrBlankEmail_throwsTokenInvalid() throws Exception {
        FirebaseToken withoutEmail = token("uid-5", null, "apple.com");
        given(firebaseAuth.verifyIdToken("no-email")).willReturn(withoutEmail);
        FirebaseToken blankEmail = token("uid-6", "  ", "google.com");
        given(firebaseAuth.verifyIdToken("blank-email")).willReturn(blankEmail);

        assertThatThrownBy(() -> verifier.verify("no-email"))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.SOCIAL_TOKEN_INVALID));
        assertThatThrownBy(() -> verifier.verify("blank-email"))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.SOCIAL_TOKEN_INVALID));
    }

    @Test
    void authenticationErrors_areConvertedToTokenInvalid() throws Exception {
        for (AuthErrorCode authErrorCode : new AuthErrorCode[] {
            AuthErrorCode.EXPIRED_ID_TOKEN, AuthErrorCode.INVALID_ID_TOKEN, AuthErrorCode.REVOKED_ID_TOKEN}) {
            willThrow(authException(authErrorCode)).given(firebaseAuth).verifyIdToken(CREDENTIAL);

            assertThatThrownBy(() -> verifier.verify(CREDENTIAL)).satisfies(thrown -> assertErrorCode(thrown,
                ErrorCode.SOCIAL_TOKEN_INVALID));
        }
    }

    @Test
    void certificateFetchFailure_isConvertedToServerUnavailable() throws Exception {
        given(firebaseAuth.verifyIdToken(CREDENTIAL)).willThrow(authException(AuthErrorCode.CERTIFICATE_FETCH_FAILED));

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL)).satisfies(thrown -> assertErrorCode(thrown,
            ErrorCode.SOCIAL_SERVER_UNAVAILABLE));
    }

    @Test
    void exceptionWithoutAuthErrorCode_isConvertedToServerUnavailable() throws Exception {
        given(firebaseAuth.verifyIdToken(CREDENTIAL))
            .willThrow(new FirebaseAuthException(com.google.firebase.ErrorCode.UNAVAILABLE, "detail", null, null, null));

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL)).satisfies(thrown -> assertErrorCode(thrown,
            ErrorCode.SOCIAL_SERVER_UNAVAILABLE));
    }

}
