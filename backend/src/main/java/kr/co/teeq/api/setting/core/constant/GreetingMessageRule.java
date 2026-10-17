package kr.co.teeq.api.setting.core.constant;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;

/**
 * 오늘의 한마디 문구 규칙. AI 응답 검증과 default 문구 설정 검증이 같은 기준을 쓴다.
 */
public final class GreetingMessageRule {

    public static final String HONORIFIC_PLACEHOLDER = "{호칭}";
    /** 줄바꿈을 뺀 본문 최대 길이(code point 기준) */
    public static final int MAX_BODY_LENGTH = 45;
    /** 저장 문구 최대 길이 */
    public static final int MAX_STORED_LENGTH = 200;
    /** 호칭 최대 길이(닉네임 10 + 접미사) */
    public static final int MAX_HONORIFIC_LENGTH = 12;

    private GreetingMessageRule() {
    }

    public static boolean isValidMessage(String message) {
        if (message == null || message.isBlank()) {
            return false;
        }
        // String.length()는 UTF-16 단위라 DB varchar(200)의 code point 기준보다 보수적이어서 안전하다
        if (message.length() > MAX_STORED_LENGTH) {
            return false;
        }
        if (message.codePoints().anyMatch(codePoint -> Character.isISOControl(codePoint)
            && codePoint != '\n' && codePoint != '\r')) {
            return false;
        }
        String body = message.replace("\n", "").replace("\r", "");
        return body.codePointCount(0, body.length()) <= MAX_BODY_LENGTH;
    }

    /** 호칭 자리 표시자가 정확히 한 번 있고, 가장 긴 호칭으로 치환해도 규칙을 만족해야 한다. */
    public static void validateTemplate(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new CustomException(ErrorCode.INVALID_SETTING_VALUE);
        }
        int first = raw.indexOf(HONORIFIC_PLACEHOLDER);
        if (first < 0 || raw.indexOf(HONORIFIC_PLACEHOLDER, first + 1) >= 0) {
            throw new CustomException(ErrorCode.INVALID_SETTING_VALUE);
        }
        String longest = raw.replace(HONORIFIC_PLACEHOLDER, "가".repeat(MAX_HONORIFIC_LENGTH));
        if (!isValidMessage(longest)) {
            throw new CustomException(ErrorCode.INVALID_SETTING_VALUE);
        }
    }

}
