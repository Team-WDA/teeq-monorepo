package kr.co.teeq.api.auth.infrastructure.adapter;

import com.google.firebase.auth.AuthErrorCode;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import java.util.Map;
import kr.co.teeq.api.auth.core.port.SocialIdentity;
import kr.co.teeq.api.auth.core.port.SocialIdentityVerifier;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Firebase ID token을 Admin SDK로 검증한다. 회원 식별값은 Firebase uid이고, 로그인 방식은
 * {@code firebase.sign_in_provider} 클레임으로 정한다. 토큰 값은 로그에 남기지 않는다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class FirebaseSocialIdentityVerifier implements SocialIdentityVerifier {

    private static final String FIREBASE_CLAIM = "firebase";
    private static final String SIGN_IN_PROVIDER_KEY = "sign_in_provider";
    private static final String APPLE_PROVIDER = "apple.com";
    private static final String GOOGLE_PROVIDER = "google.com";

    private final FirebaseAuth firebaseAuth;

    @Override
    public SocialIdentity verify(String credential) {
        FirebaseToken token = verifyToken(credential);
        LoginType loginType = resolveLoginType(token);
        String email = token.getEmail();
        if (email == null || email.isBlank()) {
            throw new CustomException(ErrorCode.SOCIAL_TOKEN_INVALID);
        }
        return new SocialIdentity(loginType, token.getUid(), email);
    }

    // 폐기 여부는 확인하지 않는다(verifyIdToken은 서명·만료·대상 프로젝트만 검사한다)
    private FirebaseToken verifyToken(String credential) {
        try {
            return firebaseAuth.verifyIdToken(credential);
        } catch (FirebaseAuthException exception) {
            if (exception.getAuthErrorCode() == null
                || exception.getAuthErrorCode() == AuthErrorCode.CERTIFICATE_FETCH_FAILED) {
                log.error("Firebase 토큰 검증 서버 오류: errorCode={}", exception.getErrorCode(), exception);
                throw new CustomException(ErrorCode.SOCIAL_SERVER_UNAVAILABLE, exception);
            }
            log.warn("Firebase 토큰 검증 실패: authErrorCode={}", exception.getAuthErrorCode());
            throw new CustomException(ErrorCode.SOCIAL_TOKEN_INVALID, exception);
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
        throw new CustomException(ErrorCode.SOCIAL_TOKEN_INVALID);
    }

}
