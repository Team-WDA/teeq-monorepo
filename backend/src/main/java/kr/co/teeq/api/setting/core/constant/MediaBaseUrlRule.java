package kr.co.teeq.api.setting.core.constant;

import java.net.URI;
import java.net.URISyntaxException;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;

/**
 * 미디어 절대 URL 앞부분 규칙. http(s) 스킴과 호스트가 있어야 하고, 사용자 정보·쿼리·프래그먼트는 조립하면 URL이 깨지므로 거부한다.
 */
public final class MediaBaseUrlRule {

    private MediaBaseUrlRule() {
    }

    public static void validate(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new CustomException(ErrorCode.INVALID_SETTING_VALUE);
        }
        URI uri;
        try {
            uri = new URI(raw);
        } catch (URISyntaxException exception) {
            throw new CustomException(ErrorCode.INVALID_SETTING_VALUE, exception);
        }
        boolean httpScheme = "http".equals(uri.getScheme()) || "https".equals(uri.getScheme());
        if (!httpScheme || uri.getHost() == null || uri.getRawUserInfo() != null
            || uri.getRawQuery() != null || uri.getRawFragment() != null) {
            throw new CustomException(ErrorCode.INVALID_SETTING_VALUE);
        }
    }

}
