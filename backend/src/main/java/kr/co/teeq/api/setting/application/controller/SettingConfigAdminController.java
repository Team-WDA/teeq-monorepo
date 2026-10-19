package kr.co.teeq.api.setting.application.controller;

import jakarta.validation.Valid;
import java.util.List;
import kr.co.teeq.api.setting.application.dto.request.SettingConfigUpdateRequest;
import kr.co.teeq.api.setting.application.dto.response.SettingConfigResponse;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/setting-configs")
@RequiredArgsConstructor
public class SettingConfigAdminController implements SettingConfigAdminControllerDocs {

    private final SettingConfigService settingConfigService;

    @GetMapping
    public ResponseEntity<List<SettingConfigResponse>> getAll() {
        return ResponseEntity.ok(settingConfigService.getAll());
    }

    @PatchMapping("/{key}")
    public ResponseEntity<SettingConfigResponse> update(
        @PathVariable String key,
        @Valid @RequestBody SettingConfigUpdateRequest request) {
        return ResponseEntity.ok(settingConfigService.update(key, request));
    }

}
