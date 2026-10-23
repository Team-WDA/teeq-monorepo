package kr.co.teeq.api.member.core.constant;

/**
 * 회원의 로그인 방식. 한 계정은 하나의 방식만 가진다. EMAIL은 Firebase 이메일/비밀번호(`password` 제공자)다.
 */
public enum LoginType {
    APPLE,
    GOOGLE,
    EMAIL
}
