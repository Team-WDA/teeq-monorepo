package kr.co.teeq.api.auth.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import com.google.firebase.auth.AuthErrorCode;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class FirebaseUserDeletionAdapterTest {

    private static final String FIREBASE_UID = "uid-1";

    private FirebaseAuth firebaseAuth;
    private FirebaseUserDeletionAdapter adapter;

    @BeforeEach
    void setUp() {
        firebaseAuth = mock(FirebaseAuth.class);
        adapter = new FirebaseUserDeletionAdapter(firebaseAuth);
    }

    private FirebaseAuthException authException(AuthErrorCode authErrorCode) {
        return new FirebaseAuthException(com.google.firebase.ErrorCode.NOT_FOUND, "detail", null, null, authErrorCode);
    }

    @Test
    void delete_callsAdminSdkWithUid() throws Exception {
        adapter.delete(FIREBASE_UID);

        verify(firebaseAuth).deleteUser(FIREBASE_UID);
    }

    @Test
    void delete_userNotFound_isTreatedAsSuccess() throws Exception {
        willThrow(authException(AuthErrorCode.USER_NOT_FOUND)).given(firebaseAuth).deleteUser(FIREBASE_UID);

        assertThatCode(() -> adapter.delete(FIREBASE_UID)).doesNotThrowAnyException();
    }

    @Test
    void delete_otherAuthError_isPropagatedToCaller() throws Exception {
        willThrow(authException(AuthErrorCode.USER_DISABLED)).given(firebaseAuth).deleteUser(FIREBASE_UID);

        assertThatThrownBy(() -> adapter.delete(FIREBASE_UID)).isInstanceOf(IllegalStateException.class).hasCauseInstanceOf(FirebaseAuthException.class);
    }

}
