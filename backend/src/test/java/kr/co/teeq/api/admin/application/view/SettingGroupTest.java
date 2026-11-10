package kr.co.teeq.api.admin.application.view;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Arrays;
import org.junit.jupiter.api.Test;
import kr.co.teeq.api.setting.core.constant.SettingKey;

class SettingGroupTest {

    @Test
    void everySettingKeyBelongsToExactlyOneGroup() {
        for (SettingKey settingKey : SettingKey.values()) {
            long groupCount = Arrays.stream(SettingGroup.values())
                .filter(group -> group.keys().contains(settingKey))
                .count();
            assertThat(groupCount).as(settingKey.name()).isEqualTo(1);
        }
    }

    @Test
    void everySettingKeyHasDisplayName() {
        for (SettingKey settingKey : SettingKey.values()) {
            assertThat(SettingKeyDisplayName.of(settingKey.name()))
                .as(settingKey.name())
                .isNotBlank()
                .isNotEqualTo(settingKey.name());
        }
    }

    @Test
    void fromPath_findsGroupOrEmpty() {
        assertThat(SettingGroup.fromPath("call-limits")).contains(SettingGroup.CALL_LIMITS);
        assertThat(SettingGroup.fromPath("unknown")).isEmpty();
    }

}
