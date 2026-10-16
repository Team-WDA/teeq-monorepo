package kr.teeq.api.setting.core.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.setting.core.entity.SettingConfig;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettingConfigRepository extends JpaRepository<SettingConfig, UUID> {

    Optional<SettingConfig> findByConfigKeyAndDeletedFalse(String configKey);

    List<SettingConfig> findAllByDeletedFalse();

}
