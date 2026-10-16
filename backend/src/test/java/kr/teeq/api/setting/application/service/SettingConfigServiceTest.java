package kr.teeq.api.setting.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;

import java.util.List;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.setting.application.dto.request.SettingConfigUpdateRequest;
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
    void getAll_withoutDefinedKeys_returnsEmptyList() {
        given(settingConfigRepository.findAllByDeletedFalse()).willReturn(List.of());

        assertThat(settingConfigService.getAll()).isEmpty();
        verify(settingConfigRepository).findAllByDeletedFalse();
    }

}
