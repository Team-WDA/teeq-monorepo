package kr.co.teeq.api.admin.application.view;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import kr.co.teeq.api.setting.core.constant.SettingKey;

/**
 * 서비스 설정 화면의 탭 그룹. 경로 조각과 탭 이름, 그룹에 속한 설정 키를 정한다.
 */
public enum SettingGroup {

    CALL_LIMITS("call-limits", "통화 한도", List.of(
        SettingKey.CALL_MAX_SECONDS_PER_SESSION,
        SettingKey.CALL_MAX_SECONDS_PER_DAY,
        SettingKey.CALL_MAX_SECONDS_PER_MONTH_TOTAL,
        SettingKey.CALL_MIN_START_SECONDS)),
    GREETING_MESSAGES("greeting-messages", "오늘의 한마디", List.of(
        SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL,
        SettingKey.GREETING_DEFAULT_MESSAGE_POLITE)),
    APP_VERSIONS("app-versions", "앱 버전·스토어", List.of(
        SettingKey.APP_MIN_VERSION_ANDROID,
        SettingKey.APP_MIN_VERSION_IOS,
        SettingKey.APP_STORE_URL_ANDROID,
        SettingKey.APP_STORE_URL_IOS)),
    MEDIA("media", "미디어", List.of(
        SettingKey.MEDIA_BASE_URL));

    private final String path;
    private final String label;
    private final List<SettingKey> keys;

    SettingGroup(String path, String label, List<SettingKey> keys) {
        this.path = path;
        this.label = label;
        this.keys = keys;
    }

    public String path() {
        return path;
    }

    public String label() {
        return label;
    }

    public List<SettingKey> keys() {
        return keys;
    }

    public static Optional<SettingGroup> fromPath(String path) {
        return Arrays.stream(values())
            .filter(group -> group.path.equals(path))
            .findFirst();
    }

}
