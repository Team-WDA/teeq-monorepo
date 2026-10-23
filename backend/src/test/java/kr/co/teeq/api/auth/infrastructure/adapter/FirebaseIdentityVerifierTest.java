package kr.co.teeq.api.auth.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.google.firebase.auth.AuthErrorCode;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.auth.UserInfo;
import com.google.firebase.auth.UserRecord;
import java.util.HashMap;
import java.util.Map;
import kr.co.teeq.api.auth.core.port.VerifiedIdentity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;

class FirebaseIdentityVerifierTest {

    private static final String CREDENTIAL = "firebase-id-token";

    private FirebaseAuth firebaseAuth;
    private FirebaseIdentityVerifier verifier;
    private ListAppender<ILoggingEvent> logAppender;
    private Logger verifierLogger;

    @BeforeEach
    void setUp() {
        firebaseAuth = mock(FirebaseAuth.class);
        verifier = new FirebaseIdentityVerifier(firebaseAuth);
        verifierLogger = (Logger) LoggerFactory.getLogger(FirebaseIdentityVerifier.class);
        logAppender = new ListAppender<>();
        logAppender.start();
        verifierLogger.addAppender(logAppender);
    }

    @AfterEach
    void tearDown() {
        verifierLogger.detachAppender(logAppender);
    }

    private UserInfo userInfo(String providerId, String email) {
        UserInfo userInfo = mock(UserInfo.class);
        given(userInfo.getProviderId()).willReturn(providerId);
        given(userInfo.getEmail()).willReturn(email);
        return userInfo;
    }

    private UserRecord userRecord(String topLevelEmail, UserInfo... providerData) {
        UserRecord userRecord = mock(UserRecord.class);
        given(userRecord.getEmail()).willReturn(topLevelEmail);
        given(userRecord.getProviderData()).willReturn(providerData);
        return userRecord;
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
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(stubbedToken);

        VerifiedIdentity identity = verifier.verify(CREDENTIAL);

        assertThat(identity.loginType()).isEqualTo(LoginType.APPLE);
        assertThat(identity.subject()).isEqualTo("uid-1");
        assertThat(identity.email()).isEqualTo("soyeon@teeq.com");
    }

    @Test
    void googleProvider_mapsToGoogleIdentity() throws Exception {
        FirebaseToken stubbedToken = token("uid-2", "soyeon@teeq.com", "google.com");
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(stubbedToken);

        assertThat(verifier.verify(CREDENTIAL).loginType()).isEqualTo(LoginType.GOOGLE);
    }

    @Test
    void passwordProvider_mapsToEmailIdentityEvenWhenEmailNotVerified() throws Exception {
        FirebaseToken stubbedToken = token("uid-7", "soyeon@teeq.com", "password");
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(stubbedToken);

        VerifiedIdentity identity = verifier.verify(CREDENTIAL);

        assertThat(identity.loginType()).isEqualTo(LoginType.EMAIL);
        assertThat(identity.subject()).isEqualTo("uid-7");
    }

    @Test
    void verify_checksRevocation() throws Exception {
        FirebaseToken stubbedToken = token("uid-8", "soyeon@teeq.com", "google.com");
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(stubbedToken);

        verifier.verify(CREDENTIAL);

        verify(firebaseAuth).verifyIdToken(CREDENTIAL, true);
        verify(firebaseAuth, never()).verifyIdToken(CREDENTIAL);
        verify(firebaseAuth, never()).getUser(anyString());
    }

    @Test
    void unsupportedProvider_throwsTokenInvalid() throws Exception {
        FirebaseToken stubbedToken = token("uid-3", "soyeon@teeq.com", "phone");
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(stubbedToken);

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.AUTH_TOKEN_INVALID));
        assertThat(logAppender.list).singleElement()
            .satisfies(event -> assertThat(event.getFormattedMessage()).contains("UNSUPPORTED_PROVIDER", "phone"));
    }

    @Test
    void missingProviderClaim_throwsTokenInvalid() throws Exception {
        FirebaseToken stubbedToken = token("uid-4", "soyeon@teeq.com", null);
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(stubbedToken);

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.AUTH_TOKEN_INVALID));
        assertThat(logAppender.list).singleElement()
            .satisfies(event -> assertThat(event.getFormattedMessage()).contains("PROVIDER_CLAIM_MISSING"));
    }

    @Test
    void tokenWithoutEmail_usesLoginProviderEmailOfUserRecord() throws Exception {
        FirebaseToken withoutEmail = token("uid-5", null, "apple.com");
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(withoutEmail);
        UserRecord userRecord = userRecord("top@teeq.com",
            userInfo("google.com", "google@teeq.com"), userInfo("apple.com", " Apple@Teeq.com "));
        given(firebaseAuth.getUser("uid-5")).willReturn(userRecord);

        VerifiedIdentity identity = verifier.verify(CREDENTIAL);

        assertThat(identity.loginType()).isEqualTo(LoginType.APPLE);
        assertThat(identity.email()).isEqualTo("apple@teeq.com");
    }

    @Test
    void blankTokenEmail_isTreatedAsMissingAndFallsBackToTopLevelEmail() throws Exception {
        FirebaseToken blankEmail = token("uid-6", "  ", "google.com");
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(blankEmail);
        UserRecord userRecord = userRecord("top@teeq.com",
            userInfo("google.com", "  "), userInfo("apple.com", "apple@teeq.com"));
        given(firebaseAuth.getUser("uid-6")).willReturn(userRecord);

        assertThat(verifier.verify(CREDENTIAL).email()).isEqualTo("top@teeq.com");
    }

    @Test
    void emailMissingEverywhere_throwsTokenInvalidAndLogsReasonWithoutIdentifiers() throws Exception {
        FirebaseToken withoutEmail = token("uid-secret", null, "apple.com");
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(withoutEmail);
        UserRecord userRecord = userRecord(" ", userInfo("apple.com", null));
        given(firebaseAuth.getUser("uid-secret")).willReturn(userRecord);

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.AUTH_TOKEN_INVALID));

        assertThat(logAppender.list).singleElement().satisfies(event -> {
            assertThat(event.getLevel()).isEqualTo(Level.WARN);
            assertThat(event.getFormattedMessage())
                .contains("EMAIL_MISSING", "apple.com")
                .doesNotContain("uid-secret", CREDENTIAL);
        });
    }

    @Test
    void nullProviderData_isTreatedAsEmpty() throws Exception {
        FirebaseToken withoutEmail = token("uid-9", null, "google.com");
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(withoutEmail);
        UserRecord userRecord = mock(UserRecord.class);
        given(userRecord.getEmail()).willReturn("top@teeq.com");
        given(firebaseAuth.getUser("uid-9")).willReturn(userRecord);

        assertThat(verifier.verify(CREDENTIAL).email()).isEqualTo("top@teeq.com");
    }

    @Test
    void userRecordLookupFailure_isConvertedByAuthErrorCode() throws Exception {
        FirebaseToken withoutEmail = token("uid-10", null, "apple.com");
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willReturn(withoutEmail);
        given(firebaseAuth.getUser("uid-10")).willThrow(authException(AuthErrorCode.USER_NOT_FOUND));

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.AUTH_TOKEN_INVALID));
        assertThat(logAppender.list).singleElement().satisfies(event -> {
            assertThat(event.getLevel()).isEqualTo(Level.WARN);
            assertThat(event.getFormattedMessage()).doesNotContain("uid-10");
            assertThat(event.getThrowableProxy()).isNull();
        });

        willThrow(new FirebaseAuthException(com.google.firebase.ErrorCode.UNAVAILABLE, "detail", null, null, null))
            .given(firebaseAuth).getUser("uid-10");

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.AUTH_SERVER_UNAVAILABLE));
    }

    @Test
    void authenticationErrors_areConvertedToTokenInvalid() throws Exception {
        for (AuthErrorCode authErrorCode : new AuthErrorCode[] {
            AuthErrorCode.EXPIRED_ID_TOKEN, AuthErrorCode.INVALID_ID_TOKEN, AuthErrorCode.REVOKED_ID_TOKEN}) {
            willThrow(authException(authErrorCode)).given(firebaseAuth).verifyIdToken(CREDENTIAL, true);

            assertThatThrownBy(() -> verifier.verify(CREDENTIAL)).satisfies(thrown -> assertErrorCode(thrown,
                ErrorCode.AUTH_TOKEN_INVALID));
        }
    }

    @Test
    void certificateFetchFailure_isConvertedToServerUnavailable() throws Exception {
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true)).willThrow(authException(AuthErrorCode.CERTIFICATE_FETCH_FAILED));

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL)).satisfies(thrown -> assertErrorCode(thrown,
            ErrorCode.AUTH_SERVER_UNAVAILABLE));
    }

    @Test
    void exceptionWithoutAuthErrorCode_isConvertedToServerUnavailable() throws Exception {
        given(firebaseAuth.verifyIdToken(CREDENTIAL, true))
            .willThrow(new FirebaseAuthException(com.google.firebase.ErrorCode.UNAVAILABLE, "detail", null, null, null));

        assertThatThrownBy(() -> verifier.verify(CREDENTIAL)).satisfies(thrown -> assertErrorCode(thrown,
            ErrorCode.AUTH_SERVER_UNAVAILABLE));
    }

}
