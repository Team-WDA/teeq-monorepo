package kr.co.teeq.api.setting.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import kr.co.teeq.api.setting.application.dto.request.SettingConfigUpdateRequest;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.aop.AopAutoConfiguration;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = SettingConfigAdminController.class)
// 컨트롤러가 Docs 인터페이스를 구현하므로 클래스 기반 프록시(AopAutoConfiguration)가 있어야 매핑이 잡힌다
@ImportAutoConfiguration(AopAutoConfiguration.class)
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    SettingConfigAdminController.class
})
class SettingConfigAdminControllerSecurityTest {

    private static final String BASE_PATH = "/api/admin/setting-configs";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private SettingConfigService settingConfigService;

    @Test
    void noSession_returns401Json() throws Exception {
        mockMvc.perform(get(BASE_PATH))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void patchWithoutCsrf_returns403() throws Exception {
        mockMvc.perform(patch(BASE_PATH + "/ANY_KEY")
                .with(asAdmin())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":\"1\"}"))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void adminSession_patchWithCsrf_returns200() throws Exception {
        mockMvc.perform(patch(BASE_PATH + "/ANY_KEY")
                .with(asAdmin()).with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":\"1\"}"))
            .andExpect(status().isOk());

        verify(settingConfigService).update(eq("ANY_KEY"), any(SettingConfigUpdateRequest.class));
    }

    @Test
    void adminSession_getList_returns200() throws Exception {
        given(settingConfigService.getAll()).willReturn(List.of());

        mockMvc.perform(get(BASE_PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$").isEmpty());
    }

}
