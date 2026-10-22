package kr.co.teeq.api.admin.infrastructure.config;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.ADMIN_ID;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asSuperAdmin;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.endsWith;
import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.response.SecurityMockMvcResultMatchers.authenticated;
import static org.springframework.security.test.web.servlet.response.SecurityMockMvcResultMatchers.unauthenticated;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import kr.co.teeq.api.admin.application.controller.AdminLoginController;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.member.core.constant.AdminRole;
import kr.co.teeq.api.member.core.entity.Admin;
import kr.co.teeq.api.member.core.principal.AuthenticatedAdmin;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@WebMvcTest(controllers = AdminSecurityTest.ProbeController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    AdminLoginController.class,
    AdminSecurityTest.ProbeController.class
})
class AdminSecurityTest {

    private static final String USERNAME = "operator";
    private static final String RAW_PASSWORD = "dummy-admin-password-for-test";
    private static final String HTMX_HEADER = "HX-Request";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @MockitoBean
    private AdminRepository adminRepository;

    @Test
    void unauthenticatedPage_redirectsToLogin() throws Exception {
        mockMvc.perform(get("/admin/probe"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", endsWith("/admin/login")));
    }

    @Test
    void unauthenticatedHtmx_returns401WithHxRedirect() throws Exception {
        mockMvc.perform(get("/admin/probe").header(HTMX_HEADER, "true"))
            .andExpect(status().isUnauthorized())
            .andExpect(header().string("HX-Redirect", "/admin/login"));
    }

    @Test
    void unauthenticatedRest_returns401Json() throws Exception {
        mockMvc.perform(get("/api/admin/probe"))
            .andExpect(status().isUnauthorized())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void bearerTokenOnAdminRestPath_isIgnoredAndReturns401Json() throws Exception {
        // 관리자 체인은 Authorization 헤더를 읽지 않으므로 JWT로는 관리자 경로를 쓸 수 없다
        mockMvc.perform(get("/api/admin/probe").header("Authorization", "Bearer some.jwt.value"))
            .andExpect(status().isUnauthorized())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void loginPageAndAssets_arePublic() throws Exception {
        // 로그인 폼에 CSRF 숨은 필드가 렌더링되어야 브라우저 로그인이 403 없이 동작한다
        mockMvc.perform(get("/admin/login"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("name=\"_csrf\"")));
        mockMvc.perform(get("/admin/assets/admin.css"))
            .andExpect(status().isOk());
    }

    @Test
    void login_withValidCredentials_redirectsToHomeAndSetsOneHourSession() throws Exception {
        givenStoredAdmin(AdminRole.ADMIN);

        MvcResult result = mockMvc.perform(loginRequest(USERNAME, RAW_PASSWORD))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", "/admin"))
            .andExpect(authenticated()
                .withRoles("ADMIN")
                .withAuthentication(authentication -> assertThat(authentication.getPrincipal())
                    .isEqualTo(new AuthenticatedAdmin(ADMIN_ID, USERNAME, "운영자"))))
            .andReturn();

        assertThat(result.getRequest().getSession(false)).isNotNull();
        assertThat(result.getRequest().getSession(false).getMaxInactiveInterval()).isEqualTo(3600);
    }

    @Test
    void login_withSuperAdminRole_grantsSuperAdminAuthority() throws Exception {
        givenStoredAdmin(AdminRole.SUPER_ADMIN);

        mockMvc.perform(loginRequest(USERNAME, RAW_PASSWORD))
            .andExpect(status().isFound())
            .andExpect(authenticated().withRoles("SUPER_ADMIN"));
    }

    @Test
    void login_withAdminRole_doesNotGrantSuperAdminAuthority() throws Exception {
        givenStoredAdmin(AdminRole.ADMIN);

        mockMvc.perform(loginRequest(USERNAME, RAW_PASSWORD))
            .andExpect(status().isFound())
            .andExpect(authenticated().withAuthorities(
                List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))));
    }

    @Test
    void admin_isDeniedSuperAdminOnlyPaths() throws Exception {
        mockMvc.perform(get("/admin/accounts/probe").with(asAdmin()))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
        mockMvc.perform(post("/admin/settings/probe").with(asAdmin()).with(csrf()))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
        mockMvc.perform(patch("/api/admin/setting-configs/probe").with(asAdmin()).with(csrf()))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void admin_isDeniedMemberDeletePath() throws Exception {
        mockMvc.perform(post("/admin/members/probe-id/delete").with(asAdmin()).with(csrf()))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void superAdmin_canDeleteMember() throws Exception {
        mockMvc.perform(post("/admin/members/probe-id/delete").with(asSuperAdmin()).with(csrf()))
            .andExpect(status().isOk());
    }

    @Test
    void unauthenticatedMemberDelete_redirectsToLogin() throws Exception {
        mockMvc.perform(post("/admin/members/probe-id/delete"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", endsWith("/admin/login")));
    }

    @Test
    void admin_canListMembersAndGrantBonus() throws Exception {
        mockMvc.perform(get("/admin/members/probe").with(asAdmin()))
            .andExpect(status().isOk());
        mockMvc.perform(post("/admin/members/probe-id/call-bonuses/grant").with(asAdmin()).with(csrf()))
            .andExpect(status().isOk());
    }

    @Test
    void admin_canReadSettingsAndOtherPaths() throws Exception {
        mockMvc.perform(get("/admin/settings/probe").with(asAdmin()))
            .andExpect(status().isOk());
        mockMvc.perform(get("/admin/other/probe").with(asAdmin()))
            .andExpect(status().isOk());
    }

    @Test
    void superAdmin_canAccessAllPaths() throws Exception {
        mockMvc.perform(get("/admin/accounts/probe").with(asSuperAdmin()))
            .andExpect(status().isOk());
        mockMvc.perform(post("/admin/settings/probe").with(asSuperAdmin()).with(csrf()))
            .andExpect(status().isOk());
        mockMvc.perform(patch("/api/admin/setting-configs/probe").with(asSuperAdmin()).with(csrf()))
            .andExpect(status().isOk());
        mockMvc.perform(get("/admin/settings/probe").with(asSuperAdmin()))
            .andExpect(status().isOk());
        mockMvc.perform(get("/admin/other/probe").with(asSuperAdmin()))
            .andExpect(status().isOk());
    }

    @Test
    void login_withWrongPasswordOrUnknownUser_redirectsToErrorWithSameResult() throws Exception {
        givenStoredAdmin(AdminRole.ADMIN);
        given(adminRepository.findByUsernameAndDeletedFalse("ghost")).willReturn(Optional.empty());

        mockMvc.perform(loginRequest(USERNAME, "wrong-password"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", "/admin/login?error"));
        mockMvc.perform(loginRequest("ghost", RAW_PASSWORD))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", "/admin/login?error"));
    }

    @Test
    void login_withoutCsrfAndSession_redirectsToLogin() throws Exception {
        givenStoredAdmin(AdminRole.ADMIN);

        // 로그인 화면을 오래 열어 두어 세션이 만료된 경우: 저장된 토큰이 없으면 로그인 화면으로 다시 보낸다
        mockMvc.perform(post("/admin/login")
                .param("username", USERNAME)
                .param("password", RAW_PASSWORD))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", endsWith("/admin/login")))
            .andExpect(unauthenticated());
    }

    @Test
    void login_withWrongCsrf_returns403() throws Exception {
        givenStoredAdmin(AdminRole.ADMIN);
        MockHttpSession session = sessionWithCsrfToken();

        mockMvc.perform(post("/admin/login")
                .session(session)
                .param("_csrf", "wrong-token")
                .param("username", USERNAME)
                .param("password", RAW_PASSWORD))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"))
            .andExpect(unauthenticated());
    }

    @Test
    void adminSession_canAccessProbe() throws Exception {
        mockMvc.perform(get("/admin/probe").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string("ok"));
        mockMvc.perform(get("/api/admin/probe").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.result").value("ok"));
    }

    @Test
    void postWithoutCsrf_returns403() throws Exception {
        // 살아 있는 세션에 토큰이 저장된 상태에서 요청에 토큰이 없으면 잘못된 토큰으로 판정되어 403이다
        MockHttpSession session = sessionWithCsrfToken();

        mockMvc.perform(post("/admin/probe").session(session).with(asAdmin()))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void expiredSessionFormPost_redirectsToLogin() throws Exception {
        mockMvc.perform(post("/admin/probe"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", endsWith("/admin/login")));
    }

    @Test
    void postWithCsrf_returns200() throws Exception {
        mockMvc.perform(post("/admin/probe").with(asAdmin()).with(csrf()))
            .andExpect(status().isOk());
    }

    @Test
    void logout_isPostOnly() throws Exception {
        givenStoredAdmin(AdminRole.ADMIN);
        MockHttpSession session = (MockHttpSession) mockMvc.perform(loginRequest(USERNAME, RAW_PASSWORD))
            .andExpect(authenticated())
            .andReturn().getRequest().getSession(false);

        mockMvc.perform(post("/admin/logout").session(session).with(csrf()))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", "/admin/login?logout"))
            .andExpect(unauthenticated());
        assertThat(session.isInvalid()).isTrue();

        // GET은 로그아웃 필터에 걸리지 않고 MVC까지 내려가 처리할 핸들러가 없다
        mockMvc.perform(get("/admin/logout").with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(header().doesNotExist("Location"));
    }

    @Test
    void restPostWithoutCsrf_returns403Json() throws Exception {
        mockMvc.perform(post("/api/admin/probe").with(asAdmin()))
            .andExpect(status().isForbidden())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void expiredSessionHtmxPost_redirects() throws Exception {
        mockMvc.perform(post("/admin/probe").header(HTMX_HEADER, "true"))
            .andExpect(status().isUnauthorized())
            .andExpect(header().string("HX-Redirect", "/admin/login"));
    }

    @Test
    void htmxPostWithInvalidCsrf_returns403Json() throws Exception {
        mockMvc.perform(post("/admin/probe").header(HTMX_HEADER, "true").with(asAdmin()).with(csrf().useInvalidToken()))
            .andExpect(status().isForbidden())
            .andExpect(header().doesNotExist("HX-Redirect"))
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    private void givenStoredAdmin(AdminRole role) {
        Admin admin = Admin.builder()
            .username(USERNAME)
            .password(passwordEncoder.encode(RAW_PASSWORD))
            .name("운영자")
            .role(role)
            .build();
        ReflectionTestUtils.setField(admin, "id", ADMIN_ID);
        given(adminRepository.findByUsernameAndDeletedFalse(USERNAME)).willReturn(Optional.of(admin));
    }

    // 로그인 화면을 렌더링하면 CSRF 토큰이 세션에 저장된다
    private MockHttpSession sessionWithCsrfToken() throws Exception {
        return (MockHttpSession) mockMvc.perform(get("/admin/login"))
            .andExpect(status().isOk())
            .andReturn().getRequest().getSession(false);
    }

    private MockHttpServletRequestBuilder loginRequest(String username, String password) {
        return post("/admin/login")
            .with(csrf())
            .param("username", username)
            .param("password", password);
    }

    @RestController
    static class ProbeController {

        @GetMapping("/admin/probe")
        String pageProbe() {
            return "ok";
        }

        @PostMapping("/admin/probe")
        String pagePostProbe() {
            return "ok";
        }

        @GetMapping("/admin/accounts/probe")
        String accountsProbe() {
            return "ok";
        }

        @PostMapping("/admin/settings/probe")
        String settingsPostProbe() {
            return "ok";
        }

        @GetMapping("/admin/settings/probe")
        String settingsGetProbe() {
            return "ok";
        }

        @PatchMapping("/api/admin/setting-configs/probe")
        String settingConfigsPatchProbe() {
            return "ok";
        }

        @PostMapping("/admin/members/{id}/delete")
        String memberDeleteProbe() {
            return "ok";
        }

        @GetMapping("/admin/members/probe")
        String memberListProbe() {
            return "ok";
        }

        @PostMapping("/admin/members/{id}/call-bonuses/grant")
        String memberBonusGrantProbe() {
            return "ok";
        }

        @GetMapping("/admin/other/probe")
        String otherProbe() {
            return "ok";
        }

        @GetMapping("/api/admin/probe")
        Map<String, String> restProbe() {
            return Map.of("result", "ok");
        }

    }

}
