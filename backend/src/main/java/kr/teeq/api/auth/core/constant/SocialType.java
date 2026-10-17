package kr.teeq.api.auth.core.constant;

import kr.teeq.api.member.core.constant.LoginType;

/**
 * 소셜 로그인 요청이 지원하는 제공자.
 */
public enum SocialType {
    APPLE(LoginType.APPLE);

    private final LoginType loginType;

    SocialType(LoginType loginType) {
        this.loginType = loginType;
    }

    public LoginType toLoginType() {
        return loginType;
    }
}
