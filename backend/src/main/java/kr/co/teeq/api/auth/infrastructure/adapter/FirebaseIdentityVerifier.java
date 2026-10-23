package kr.co.teeq.api.auth.infrastructure.adapter;

import com.google.firebase.auth.AuthErrorCode;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.auth.UserInfo;
import com.google.firebase.auth.UserRecord;
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
 * {@code firebase.sign_in_provider} 클레임(apple.com, google.com, password)으로 정한다.
 * "ID 공급업체별로 여러 계정 만들기" 설정에서는 토큰에 email 클레임이 빠질 수 있어, 이때는 사용자 레코드의
 * 제공자 이메일을 읽는다. 토큰 값, uid, 이메일은 로그에 남기지 않는다.
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
        String provider = resolveProvider(token);
        LoginType loginType = resolveLoginType(provider);
        String email = resolveEmail(token, provider);
        return new VerifiedIdentity(loginType, token.getUid(), email);
    }

    // 서명·만료·대상 프로젝트에 더해 폐기(revoke)와 비활성 사용자도 확인한다. email_verified는 검사하지 않는다
    private FirebaseToken verifyToken(String credential) {
        try {
            return firebaseAuth.verifyIdToken(credential, true);
        } catch (FirebaseAuthException exception) {
            throw convert(exception, "토큰 검증");
        }
    }

    private String resolveProvider(FirebaseToken token) {
        Object firebaseClaim = token.getClaims().get(FIREBASE_CLAIM);
        Object provider = firebaseClaim instanceof Map<?, ?> claim ? claim.get(SIGN_IN_PROVIDER_KEY) : null;
        if (provider == null) {
            throw reject("PROVIDER_CLAIM_MISSING", null);
        }
        return provider.toString();
    }

    private LoginType resolveLoginType(String provider) {
        return switch (provider) {
            case APPLE_PROVIDER -> LoginType.APPLE;
            case GOOGLE_PROVIDER -> LoginType.GOOGLE;
            case PASSWORD_PROVIDER -> LoginType.EMAIL;
            default -> throw reject("UNSUPPORTED_PROVIDER", provider);
        };
    }

    // 토큰 email이 있으면 추가 호출 없이 그대로 쓰고, 없을 때만 사용자 레코드를 조회한다
    private String resolveEmail(FirebaseToken token, String provider) {
        if (hasText(token.getEmail())) {
            return token.getEmail();
        }
        UserRecord userRecord = fetchUserRecord(token.getUid());
        UserInfo[] providerData = userRecord.getProviderData();
        for (UserInfo userInfo : providerData == null ? new UserInfo[0] : providerData) {
            if (provider.equals(userInfo.getProviderId()) && hasText(userInfo.getEmail())) {
                return userInfo.getEmail();
            }
        }
        if (hasText(userRecord.getEmail())) {
            return userRecord.getEmail();
        }
        throw reject("EMAIL_MISSING", provider);
    }

    private UserRecord fetchUserRecord(String uid) {
        try {
            return firebaseAuth.getUser(uid);
        } catch (FirebaseAuthException exception) {
            throw convert(exception, "사용자 레코드 조회");
        }
    }

    private CustomException convert(FirebaseAuthException exception, String action) {
        if (exception.getAuthErrorCode() == null
            || exception.getAuthErrorCode() == AuthErrorCode.CERTIFICATE_FETCH_FAILED) {
            log.error("Firebase {} 서버 오류: errorCode={}", action, exception.getErrorCode(), exception);
            return new CustomException(ErrorCode.AUTH_SERVER_UNAVAILABLE, exception);
        }
        log.warn("Firebase {} 실패: authErrorCode={}", action, exception.getAuthErrorCode());
        return new CustomException(ErrorCode.AUTH_TOKEN_INVALID, exception);
    }

    private CustomException reject(String reason, String provider) {
        log.warn("로그인 거절: reason={}, provider={}", reason, provider);
        return new CustomException(ErrorCode.AUTH_TOKEN_INVALID);
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

}
