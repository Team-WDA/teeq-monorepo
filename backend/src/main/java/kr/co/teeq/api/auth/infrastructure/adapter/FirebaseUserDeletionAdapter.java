package kr.co.teeq.api.auth.infrastructure.adapter;

import com.google.firebase.auth.AuthErrorCode;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import kr.co.teeq.api.auth.core.port.FirebaseUserDeletionPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * Admin SDK로 Firebase 사용자를 삭제한다. 사용자가 이미 없으면(USER_NOT_FOUND) 성공으로 본다.
 */
@Component
@RequiredArgsConstructor
public class FirebaseUserDeletionAdapter implements FirebaseUserDeletionPort {

    private final FirebaseAuth firebaseAuth;

    @Override
    public void delete(String firebaseUid) {
        try {
            firebaseAuth.deleteUser(firebaseUid);
        } catch (FirebaseAuthException exception) {
            if (exception.getAuthErrorCode() == AuthErrorCode.USER_NOT_FOUND) {
                return;
            }
            throw new IllegalStateException("Firebase 사용자 삭제 실패: errorCode=" + exception.getErrorCode(), exception);
        }
    }

}
