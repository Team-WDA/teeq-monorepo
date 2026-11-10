package kr.co.teeq.api.admin.application.view;

import java.util.Locale;

/**
 * 관리자 화면에 보여 주는 AI 사용량 종류의 라벨. AI 서버는 소문자(stt/llm/tts)로 보내고 화면에서만 대문자로 보인다.
 */
public final class AiUsageDisplayLabel {

    private static final String EMPTY_LABEL = "-";

    private AiUsageDisplayLabel() {
    }

    // 종류가 없으면 "-", 알 수 없는 종류도 그대로 대문자로 보여 준다
    public static String kind(String kind) {
        if (kind == null) {
            return EMPTY_LABEL;
        }
        return kind.toUpperCase(Locale.ROOT);
    }

}
