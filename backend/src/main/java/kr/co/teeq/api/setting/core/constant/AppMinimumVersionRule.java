package kr.co.teeq.api.setting.core.constant;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.core.version.AppVersion;

/**
 * 앱 최소 지원 버전 규칙. SemVer {@code x.y.z} 형식만 허용한다.
 */
public final class AppMinimumVersionRule {

    private AppMinimumVersionRule() {
    }

    public static void validate(String raw) {
        try {
            AppVersion.parse(raw);
        } catch (CustomException exception) {
            throw new CustomException(ErrorCode.INVALID_SETTING_VALUE, exception);
        }
    }

}
