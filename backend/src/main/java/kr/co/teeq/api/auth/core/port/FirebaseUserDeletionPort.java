package kr.co.teeq.api.auth.core.port;

/**
 * Firebase 사용자 삭제 외부 연동 port. 탈퇴한 회원의 Firebase 계정을 지워 같은 이메일로 다시 가입할 수 있게 한다.
 */
public interface FirebaseUserDeletionPort {

    /**
     * uid의 Firebase 사용자를 삭제한다. 이미 없는 사용자는 정상으로 취급하고, 그 밖의 실패는 호출자에게 예외로 전달한다.
     */
    void delete(String firebaseUid);

}
