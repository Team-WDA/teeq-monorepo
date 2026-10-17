package kr.teeq.api.setting.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;

import java.util.List;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.setting.application.dto.request.SettingConfigUpdateRequest;
import kr.teeq.api.setting.application.dto.response.SettingConfigResponse;
import kr.teeq.api.setting.core.constant.SettingKey;
import kr.teeq.api.setting.core.repository.SettingConfigRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class SettingConfigServiceTest {

    @Mock
    private SettingConfigRepository settingConfigRepository;

    private SettingConfigService settingConfigService;

    @BeforeEach
    void setUp() {
        settingConfigService = new SettingConfigService(settingConfigRepository);
    }

    @Test
    void update_undefinedKey_throwsSettingConfigNotFound() {
        assertThatThrownBy(() -> settingConfigService.update("NO_SUCH_KEY", new SettingConfigUpdateRequest("1")))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.SETTING_CONFIG_NOT_FOUND));
        verifyNoMoreInteractions(settingConfigRepository);
    }

    @Test
    void update_greetingDefaultWithoutPlaceholder_throwsInvalidSettingValue() {
        assertThatThrownBy(() -> settingConfigService.update("GREETING_DEFAULT_MESSAGE_CASUAL",
            new SettingConfigUpdateRequest("오늘 하루 어땠어?")))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_SETTING_VALUE));
        verify(settingConfigRepository, never()).saveAndFlush(any());
    }

    @Test
    void getAll_withoutStoredRows_returnsEnumDefaults() {
        given(settingConfigRepository.findAllByDeletedFalse()).willReturn(List.of());

        List<SettingConfigResponse> responses = settingConfigService.getAll();

        assertThat(responses).hasSize(SettingKey.values().length);
        assertThat(responses).allSatisfy(response -> {
            SettingKey settingKey = SettingKey.find(response.key()).orElseThrow();
            assertThat(response.value()).isEqualTo(settingKey.defaultValue());
            assertThat(response.updatedAt()).isNull();
        });
        verify(settingConfigRepository).findAllByDeletedFalse();
    }

}
