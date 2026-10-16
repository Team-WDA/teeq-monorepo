package kr.teeq.api.setting.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import kr.teeq.api.common.core.entity.BaseEntity;
import kr.teeq.api.setting.core.constant.SettingValueType;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "setting_config")
public class SettingConfig extends BaseEntity {

    @Column(nullable = false)
    private String configKey;

    @Column(nullable = false)
    private String configValue;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SettingValueType valueType;

    @Builder
    private SettingConfig(String configKey, String configValue, SettingValueType valueType) {
        this.configKey = configKey;
        this.configValue = configValue;
        this.valueType = valueType;
    }

    public void changeValue(String configValue) {
        this.configValue = configValue;
    }

}
