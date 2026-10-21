package kr.co.teeq.api.member.core.constant;

/**
 * 비밀번호와 닉네임 입력 규칙. 가입, 비밀번호 변경, 닉네임 변경과 중복 확인 요청이 함께 쓴다.
 */
public final class MemberValidation {

    // 영문과 숫자를 포함한 8~64자, 공백과 한글 제외(출력 가능한 ASCII). BCrypt가 72바이트를 넘는 입력에서 예외를 내는 것을 막는다
    public static final String PASSWORD_REGEX = "^(?=.*[A-Za-z])(?=.*\\d)[\\x21-\\x7E]{8,64}$";
    public static final String PASSWORD_MESSAGE = "비밀번호는 영문과 숫자를 포함한 8~64자여야 하며 공백과 한글은 사용할 수 없습니다.";

    public static final String NICKNAME_REGEX = "^[가-힣]{2,10}$";
    public static final String NICKNAME_MESSAGE = "닉네임은 한글만 사용해 2~10자로 입력해 주세요.";

    private MemberValidation() {
    }

}
