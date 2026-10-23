package kr.co.teeq.api.auth.infrastructure.adapter;

import com.google.firebase.auth.AuthErrorCode;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import java.util.Map;
import kr.co.teeq.api.auth.core.port.VerifiedIdentity;
import kr.co.teeq.api.auth.core.port.IdentityVerifier;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Firebase ID token을 Admin SDK로 검증한다. 회원 식별값은 Firebase uid이고, 로그인 방식은
 * {@code firebase.sign_in_provider} 클레임(apple.com, google.com, password)으로 정한다. 토큰 값은 로그에 남기지 않는다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class FirebaseIdentityVerifier implements IdentityVerifier {

    private static final String FIREBASE_CLAIM = "firebase";
    private static final String SIGN_IN_PROVIDER_KEY = "sign_in_provider";
    private static final String APPLE_PROVIDER = "apple.com";
    private static final String GOOGLE_PROVIDER = "google.com";
    private static final String PASSWORD_PROVIDER = "password";

    private final FirebaseAuth firebaseAuth;

    @Override
    public VerifiedIdentity verify(String credential) {
        FirebaseToken token = verifyToken(credential);
        LoginType loginType = resolveLoginType(token);
        String email = token.getEmail();
        if (email == null || email.isBlank()) {
            throw new CustomException(ErrorCode.AUTH_TOKEN_INVALID);
        }
        return new VerifiedIdentity(loginType, token.getUid(), email);
    }

    // 서명·만료·대상 프로젝트에 더해 폐기(revoke)와 비활성 사용자도 확인한다. email_verified는 검사하지 않는다
    private FirebaseToken verifyToken(String credential) {
        try {
            return firebaseAuth.verifyIdToken(credential, true);
        } catch (FirebaseAuthException exception) {
            if (exception.getAuthErrorCode() == null
                || exception.getAuthErrorCode() == AuthErrorCode.CERTIFICATE_FETCH_FAILED) {
                log.error("Firebase 토큰 검증 서버 오류: errorCode={}", exception.getErrorCode(), exception);
                throw new CustomException(ErrorCode.AUTH_SERVER_UNAVAILABLE, exception);
            }
            log.warn("Firebase 토큰 검증 실패: authErrorCode={}", exception.getAuthErrorCode());
            throw new CustomException(ErrorCode.AUTH_TOKEN_INVALID, exception);
        }
    }

    private LoginType resolveLoginType(FirebaseToken token) {
        Object firebaseClaim = token.getClaims().get(FIREBASE_CLAIM);
        Object provider = firebaseClaim instanceof Map<?, ?> claim ? claim.get(SIGN_IN_PROVIDER_KEY) : null;
        if (APPLE_PROVIDER.equals(provider)) {
            return LoginType.APPLE;
        }
        if (GOOGLE_PROVIDER.equals(provider)) {
            return LoginType.GOOGLE;
        }
        if (PASSWORD_PROVIDER.equals(provider)) {
            return LoginType.EMAIL;
        }
        throw new CustomException(ErrorCode.AUTH_TOKEN_INVALID);
    }

}
