package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.util.List;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import kr.co.teeq.api.setting.application.dto.request.SettingConfigUpdateRequest;
import kr.co.teeq.api.setting.application.dto.response.SettingConfigResponse;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminSettingController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminSettingController.class
})
class AdminSettingControllerTest {

    private static final String HTMX_HEADER = "HX-Request";
    private static final String SESSION_KEY = SettingKey.CALL_MAX_SECONDS_PER_SESSION.name();
    private static final String GREETING_KEY = SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL.name();
    private static final String MARKUP_VALUE = "{호칭}<script>alert('x')</script><b>굵게</b>";
    private static final String ESCAPED_MARKUP_VALUE =
        "{호칭}&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;&lt;b&gt;굵게&lt;/b&gt;";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private SettingConfigService settingConfigService;

    @Test
    void getSettings_rendersAllKeysWithDefaultBadge() throws Exception {
        given(settingConfigService.getAll()).willReturn(List.of(
            defaultSessionSetting(),
            new SettingConfigResponse(GREETING_KEY, "{호칭},\n바꾼 인사말", SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL.valueType(),
                SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL.description(), AdminSliceTestConfig.NOW)));

        mockMvc.perform(get("/admin/settings").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/settings"))
            .andExpect(content().string(containsString(SESSION_KEY)))
            .andExpect(content().string(containsString(GREETING_KEY)))
            .andExpect(content().string(containsString("기본값 사용 중")))
            .andExpect(content().string(containsString("변경됨")))
            .andExpect(content().string(containsString("저장하면 즉시 반영됩니다")))
            // 문자열 값은 여러 줄 입력칸, 정수 값은 한 줄 입력칸
            .andExpect(content().string(containsString("<textarea")))
            .andExpect(content().string(containsString("type=\"number\"")))
            // 수정 시각은 KST로 표시한다
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            // 공통 셸: 관리자 이름, 메뉴, CSRF meta
            .andExpect(content().string(containsString("<span class=\"top-bar-admin-name\">운영자</span>")))
            .andExpect(content().string(containsString("href=\"/admin/onboarding-submissions\"")))
            .andExpect(content().string(containsString("name=\"_csrf\"")));
    }

    @Test
    void saveRow_callsServiceAndReturnsRowFragment() throws Exception {
        given(settingConfigService.update(SESSION_KEY, new SettingConfigUpdateRequest("1500")))
            .willReturn(new SettingConfigResponse(SESSION_KEY, "1500", SettingKey.CALL_MAX_SECONDS_PER_SESSION.valueType(),
                SettingKey.CALL_MAX_SECONDS_PER_SESSION.description(), AdminSliceTestConfig.NOW));

        mockMvc.perform(post("/admin/settings/{key}", SESSION_KEY)
                .header(HTMX_HEADER, "true")
                .with(asAdmin())
                .with(csrf())
                .param("value", "1500"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"1500\"")))
            .andExpect(content().string(containsString("변경됨")))
            .andExpect(content().string(not(containsString("<html"))));

        verify(settingConfigService).update(SESSION_KEY, new SettingConfigUpdateRequest("1500"));
    }

    @Test
    void settingValueWithMarkup_isRenderedEscaped() throws Exception {
        given(settingConfigService.getAll()).willReturn(List.of(greetingSetting(MARKUP_VALUE)));
        given(settingConfigService.update(GREETING_KEY, new SettingConfigUpdateRequest(MARKUP_VALUE)))
            .willReturn(greetingSetting(MARKUP_VALUE));

        mockMvc.perform(get("/admin/settings").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString(ESCAPED_MARKUP_VALUE)))
            .andExpect(content().string(not(containsString(MARKUP_VALUE))));

        mockMvc.perform(post("/admin/settings/{key}", GREETING_KEY)
                .header(HTMX_HEADER, "true")
                .with(asAdmin())
                .with(csrf())
                .param("value", MARKUP_VALUE))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString(ESCAPED_MARKUP_VALUE)))
            .andExpect(content().string(not(containsString(MARKUP_VALUE))));
    }

    @Test
    void saveRow_withInvalidValue_showsErrorOnRow() throws Exception {
        given(settingConfigService.update(SESSION_KEY, new SettingConfigUpdateRequest("abc")))
            .willThrow(new CustomException(ErrorCode.INVALID_SETTING_VALUE));
        given(settingConfigService.getAll()).willReturn(List.of(defaultSessionSetting()));

        mockMvc.perform(post("/admin/settings/{key}", SESSION_KEY)
                .header(HTMX_HEADER, "true")
                .with(asAdmin())
                .with(csrf())
                .param("value", "abc"))
            .andExpect(status().isUnprocessableContent())
            .andExpect(content().string(containsString(ErrorCode.INVALID_SETTING_VALUE.message())))
            // 입력한 값을 그대로 남겨 고칠 수 있게 한다
            .andExpect(content().string(containsString("value=\"abc\"")))
            .andExpect(content().string(not(containsString("<html"))));
    }

    @Test
    void reset_savesDefaultValue() throws Exception {
        String defaultValue = SettingKey.CALL_MAX_SECONDS_PER_SESSION.defaultValue();
        given(settingConfigService.update(SESSION_KEY, new SettingConfigUpdateRequest(defaultValue)))
            .willReturn(new SettingConfigResponse(SESSION_KEY, defaultValue,
                SettingKey.CALL_MAX_SECONDS_PER_SESSION.valueType(),
                SettingKey.CALL_MAX_SECONDS_PER_SESSION.description(), AdminSliceTestConfig.NOW));

        mockMvc.perform(post("/admin/settings/{key}/reset", SESSION_KEY)
                .header(HTMX_HEADER, "true")
                .with(asAdmin())
                .with(csrf()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"" + defaultValue + "\"")))
            .andExpect(content().string(containsString("기본값 사용 중")));

        verify(settingConfigService).update(SESSION_KEY, new SettingConfigUpdateRequest(defaultValue));
    }

    @Test
    void postWithoutCsrf_returns403() throws Exception {
        given(settingConfigService.getAll()).willReturn(List.of(defaultSessionSetting()));
        // 화면을 열어 CSRF 토큰이 저장된 세션에서 토큰 없이 보내면 잘못된 토큰으로 판정된다
        MockHttpSession session = (MockHttpSession) mockMvc.perform(get("/admin/settings").with(asAdmin()))
            .andExpect(status().isOk())
            .andReturn().getRequest().getSession(false);

        mockMvc.perform(post("/admin/settings/{key}", SESSION_KEY)
                .session(session)
                .with(asAdmin())
                .param("value", "1500"))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));

        verify(settingConfigService, never()).update(anyString(), any());
    }

    @Test
    void unknownKey_showsErrorPage() throws Exception {
        given(settingConfigService.update("UNKNOWN_KEY", new SettingConfigUpdateRequest("1")))
            .willThrow(new CustomException(ErrorCode.SETTING_CONFIG_NOT_FOUND));

        mockMvc.perform(post("/admin/settings/{key}", "UNKNOWN_KEY")
                .with(asAdmin())
                .with(csrf())
                .param("value", "1"))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"))
            .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
            .andExpect(content().string(containsString(ErrorCode.SETTING_CONFIG_NOT_FOUND.message())));
    }

    @Test
    void resetUnknownKey_showsErrorPageWithoutCallingService() throws Exception {
        mockMvc.perform(post("/admin/settings/{key}/reset", "UNKNOWN_KEY")
                .with(asAdmin())
                .with(csrf()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.SETTING_CONFIG_NOT_FOUND.message())));

        verify(settingConfigService, never()).update(anyString(), any());
    }

    private SettingConfigResponse greetingSetting(String value) {
        SettingKey settingKey = SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL;
        return new SettingConfigResponse(settingKey.name(), value, settingKey.valueType(), settingKey.description(),
            AdminSliceTestConfig.NOW);
    }

    private SettingConfigResponse defaultSessionSetting() {
        SettingKey settingKey = SettingKey.CALL_MAX_SECONDS_PER_SESSION;
        return new SettingConfigResponse(settingKey.name(), settingKey.defaultValue(), settingKey.valueType(),
            settingKey.description(), null);
    }

}
