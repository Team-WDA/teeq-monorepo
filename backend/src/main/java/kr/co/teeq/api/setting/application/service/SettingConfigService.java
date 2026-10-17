package kr.co.teeq.api.setting.application.service;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.setting.application.dto.request.SettingConfigUpdateRequest;
import kr.co.teeq.api.setting.application.dto.response.SettingConfigResponse;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import kr.co.teeq.api.setting.core.entity.SettingConfig;
import kr.co.teeq.api.setting.core.repository.SettingConfigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class SettingConfigService {

    private final SettingConfigRepository settingConfigRepository;

    // 캐시 없이 매번 DB에서 읽고, 행이 없는 키는 enum 기본값을 돌려준다
    @Transactional(readOnly = true)
    public List<SettingConfigResponse> getAll() {
        Map<String, SettingConfig> storedByKey = settingConfigRepository.findAllByDeletedFalse().stream()
            .collect(Collectors.toMap(SettingConfig::getConfigKey, Function.identity()));
        return Arrays.stream(SettingKey.values())
            .map(settingKey -> SettingConfigResponse.of(settingKey, storedByKey.get(settingKey.name())))
            .toList();
    }

    // 키 정의는 코드가 가지므로 정의되지 않은 키는 만들지 않고 404로 거부한다. DB에 행이 없으면 새로 저장한다
    @Transactional
    public SettingConfigResponse update(String key, SettingConfigUpdateRequest request) {
        SettingKey settingKey = SettingKey.find(key)
            .orElseThrow(() -> new CustomException(ErrorCode.SETTING_CONFIG_NOT_FOUND));
        settingKey.validate(request.value());
        SettingConfig settingConfig = settingConfigRepository.findByConfigKeyAndDeletedFalse(settingKey.name())
            .map(stored -> {
                stored.changeValue(request.value());
                return stored;
            })
            .orElseGet(() -> SettingConfig.builder()
                .configKey(settingKey.name())
                .configValue(request.value())
                .valueType(settingKey.valueType())
                .build());
        return SettingConfigResponse.of(settingKey, settingConfigRepository.saveAndFlush(settingConfig));
    }

    @Transactional(readOnly = true)
    public long getInt(SettingKey settingKey) {
        return Long.parseLong(readValue(settingKey));
    }

    @Transactional(readOnly = true)
    public boolean getBoolean(SettingKey settingKey) {
        return Boolean.parseBoolean(readValue(settingKey));
    }

    @Transactional(readOnly = true)
    public String getString(SettingKey settingKey) {
        return readValue(settingKey);
    }

    private String readValue(SettingKey settingKey) {
        return settingConfigRepository.findByConfigKeyAndDeletedFalse(settingKey.name())
            .map(SettingConfig::getConfigValue)
            .orElse(settingKey.defaultValue());
    }

}
