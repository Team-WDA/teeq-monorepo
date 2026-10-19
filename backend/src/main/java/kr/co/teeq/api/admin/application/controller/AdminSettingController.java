package kr.co.teeq.api.admin.application.controller;

import io.swagger.v3.oas.annotations.Hidden;
import java.util.Optional;
import kr.co.teeq.api.admin.application.dto.response.AdminSettingRowResponse;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.setting.application.dto.request.SettingConfigUpdateRequest;
import kr.co.teeq.api.setting.application.dto.response.SettingConfigResponse;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

/**
 * 서비스 설정 화면. 키마다 htmx로 따로 저장하고, 저장·되돌리기 응답은 해당 행 조각만 돌려준다.
 */
@Slf4j
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/settings")
public class AdminSettingController {

    private static final String SETTINGS_VIEW = "admin/settings";
    private static final String SETTING_ROW_FRAGMENT = "admin/fragments/setting-row :: setting-row";

    private final SettingConfigService settingConfigService;

    @GetMapping
    public String settings(Model model) {
        model.addAttribute("settings", settingConfigService.getAll().stream()
            .map(AdminSettingRowResponse::from)
            .toList());
        return SETTINGS_VIEW;
    }

    // 빈 값도 서비스 검증에 맡겨 해당 행에 오류로 보여 준다
    @PostMapping("/{key}")
    public ModelAndView save(@PathVariable String key, @RequestParam(defaultValue = "") String value) {
        return saveRow(key, value);
    }

    // 요청 DTO의 값은 비울 수 없으므로 되돌리기는 키의 기본값을 저장하는 것으로 처리한다
    @PostMapping("/{key}/reset")
    public ModelAndView reset(@PathVariable String key) {
        String defaultValue = SettingKey.find(key)
            .map(SettingKey::defaultValue)
            .orElseThrow(() -> new CustomException(ErrorCode.SETTING_CONFIG_NOT_FOUND));
        return saveRow(key, defaultValue);
    }

    // 검증 실패 등은 입력값을 남긴 행 조각을 422로 돌려준다. 공통 셸이 422 응답만 행에 바꿔 끼운다
    private ModelAndView saveRow(String key, String value) {
        try {
            SettingConfigResponse saved = settingConfigService.update(key, new SettingConfigUpdateRequest(value));
            return new ModelAndView(SETTING_ROW_FRAGMENT).addObject("setting", AdminSettingRowResponse.from(saved));
        } catch (CustomException exception) {
            AdminSettingRowResponse current = findCurrentRow(key).orElseThrow(() -> exception);
            log.warn("Admin setting save rejected: {} {}", key, exception.getErrorCode().name());
            ModelAndView modelAndView = new ModelAndView(SETTING_ROW_FRAGMENT)
                .addObject("setting", current)
                .addObject("submittedValue", value)
                .addObject("rowErrorMessage", exception.getErrorCode().message());
            modelAndView.setStatus(HttpStatus.UNPROCESSABLE_CONTENT);
            return modelAndView;
        }
    }

    // 정의되지 않은 키는 행이 없으므로 비어 있고, 이때는 오류 화면으로 넘긴다
    private Optional<AdminSettingRowResponse> findCurrentRow(String key) {
        return settingConfigService.getAll().stream()
            .filter(setting -> setting.key().equals(key))
            .findFirst()
            .map(AdminSettingRowResponse::from);
    }

}
