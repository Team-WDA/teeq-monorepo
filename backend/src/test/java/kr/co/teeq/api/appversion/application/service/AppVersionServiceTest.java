package kr.co.teeq.api.appversion.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;

import kr.co.teeq.api.appversion.application.dto.response.AppVersionCheckResponse;
import kr.co.teeq.api.appversion.core.constant.AppPlatform;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AppVersionServiceTest {

    private static final String ANDROID_STORE_URL = "https://play.google.com/store/apps/details?id=kr.co.teeq.app";

    @Mock
    private SettingConfigService settingConfigService;

    @InjectMocks
    private AppVersionService appVersionService;

    @BeforeEach
    void stubAndroid() {
        lenient().when(settingConfigService.getString(SettingKey.APP_MIN_VERSION_ANDROID))
            .thenReturn("1.3.0");
        lenient().when(settingConfigService.getString(SettingKey.APP_STORE_URL_ANDROID))
            .thenReturn(ANDROID_STORE_URL);
    }

    @Test
    void check_belowMinimum_requiresUpdate() {
        AppVersionCheckResponse response = appVersionService.check(AppPlatform.ANDROID, "1.2.9");

        assertThat(response).isEqualTo(new AppVersionCheckResponse(true, "1.3.0", ANDROID_STORE_URL));
    }

    @ParameterizedTest
    @ValueSource(strings = {"1.3.0", "1.10.0"})
    void check_equalOrAboveMinimum_doesNotRequireUpdate(String appVersion) {
        assertThat(appVersionService.check(AppPlatform.ANDROID, appVersion).updateRequired()).isFalse();
    }

    @Test
    void check_defaultMinimum_neverRequiresUpdate() {
        given(settingConfigService.getString(SettingKey.APP_MIN_VERSION_ANDROID)).willReturn("0.0.0");

        assertThat(appVersionService.check(AppPlatform.ANDROID, "0.0.1").updateRequired()).isFalse();
    }

    @Test
    void check_ios_readsOnlyIosKeys() {
        given(settingConfigService.getString(SettingKey.APP_MIN_VERSION_IOS)).willReturn("2.0.0");
        given(settingConfigService.getString(SettingKey.APP_STORE_URL_IOS)).willReturn("itms-beta://");

        AppVersionCheckResponse response = appVersionService.check(AppPlatform.IOS, "1.9.9");

        assertThat(response).isEqualTo(new AppVersionCheckResponse(true, "2.0.0", "itms-beta://"));
        verify(settingConfigService).getString(SettingKey.APP_MIN_VERSION_IOS);
        verify(settingConfigService).getString(SettingKey.APP_STORE_URL_IOS);
        verifyNoMoreInteractions(settingConfigService);
    }

    @Test
    void check_invalidAppVersion_throwsInvalidRequest() {
        assertThatThrownBy(() -> appVersionService.check(AppPlatform.ANDROID, "abc"))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
    }

}
