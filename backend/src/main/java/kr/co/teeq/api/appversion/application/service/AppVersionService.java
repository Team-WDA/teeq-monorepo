package kr.co.teeq.api.appversion.application.service;

import kr.co.teeq.api.appversion.application.dto.response.AppVersionCheckResponse;
import kr.co.teeq.api.appversion.core.constant.AppPlatform;
import kr.co.teeq.api.common.core.version.AppVersion;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 앱 버전이 플랫폼별 최소 지원 버전을 만족하는지 판정한다. 최소 버전과 스토어 주소는 동적 설정에서 읽는다.
 */
@Service
@RequiredArgsConstructor
public class AppVersionService {

    private final SettingConfigService settingConfigService;

    @Transactional(readOnly = true)
    public AppVersionCheckResponse check(AppPlatform platform, String appVersion) {
        AppVersion current = AppVersion.parse(appVersion);
        String minimumVersion = settingConfigService.getString(minimumVersionKey(platform));
        String storeUrl = settingConfigService.getString(storeUrlKey(platform));
        boolean updateRequired = current.compareTo(AppVersion.parse(minimumVersion)) < 0;
        return new AppVersionCheckResponse(updateRequired, minimumVersion, storeUrl);
    }

    private SettingKey minimumVersionKey(AppPlatform platform) {
        return switch (platform) {
            case ANDROID -> SettingKey.APP_MIN_VERSION_ANDROID;
            case IOS -> SettingKey.APP_MIN_VERSION_IOS;
        };
    }

    private SettingKey storeUrlKey(AppPlatform platform) {
        return switch (platform) {
            case ANDROID -> SettingKey.APP_STORE_URL_ANDROID;
            case IOS -> SettingKey.APP_STORE_URL_IOS;
        };
    }

}
