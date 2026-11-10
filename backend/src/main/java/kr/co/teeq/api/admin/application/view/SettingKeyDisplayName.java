package kr.co.teeq.api.admin.application.view;

import java.util.Map;
import kr.co.teeq.api.setting.core.constant.SettingKey;

/**
 * 서비스 설정 키의 한국어 표시 이름. 행의 주 제목으로 쓰고 키 이름은 보조 글씨로 남긴다.
 */
public final class SettingKeyDisplayName {

    private static final Map<SettingKey, String> DISPLAY_NAMES = Map.ofEntries(
        Map.entry(SettingKey.CALL_MAX_SECONDS_PER_SESSION, "통화 1회 최대 시간(초)"),
        Map.entry(SettingKey.CALL_MAX_SECONDS_PER_DAY, "회원별 하루 통화 한도(초)"),
        Map.entry(SettingKey.CALL_MAX_SECONDS_PER_MONTH_TOTAL, "전체 월 통화 한도(초)"),
        Map.entry(SettingKey.CALL_MIN_START_SECONDS, "통화 시작 최소 잔여 시간(초)"),
        Map.entry(SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL, "반말 기본 문구"),
        Map.entry(SettingKey.GREETING_DEFAULT_MESSAGE_POLITE, "존댓말 기본 문구"),
        Map.entry(SettingKey.MEDIA_BASE_URL, "미디어 기본 주소"),
        Map.entry(SettingKey.APP_MIN_VERSION_ANDROID, "Android 최소 지원 버전"),
        Map.entry(SettingKey.APP_MIN_VERSION_IOS, "iOS 최소 지원 버전"),
        Map.entry(SettingKey.APP_STORE_URL_ANDROID, "Android 스토어 주소"),
        Map.entry(SettingKey.APP_STORE_URL_IOS, "iOS 스토어 주소"));

    private SettingKeyDisplayName() {
    }

    // 키 이름(상수 이름)으로 찾는다. 표시 이름이 없으면 조용히 넘기지 않고 실패시킨다
    public static String of(String keyName) {
        String displayName = DISPLAY_NAMES.get(SettingKey.valueOf(keyName));
        if (displayName == null) {
            throw new IllegalStateException("설정 키의 한국어 표시 이름이 없습니다: " + keyName);
        }
        return displayName;
    }

}
