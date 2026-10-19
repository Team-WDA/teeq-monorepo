package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import jakarta.validation.constraints.Min;
import java.time.LocalDate;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Controller;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

// GlobalExceptionHandler(JSON)도 함께 올려 관리자 화면 advice가 먼저 적용되는지 확인한다
@WebMvcTest(controllers = AdminExceptionHandlerTest.ProbeController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminExceptionHandlerTest.ProbeController.class
})
class AdminExceptionHandlerTest {

    private static final String HTMX_HEADER = "HX-Request";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @Test
    void customException_rendersAdminErrorViewInsteadOfJson() throws Exception {
        mockMvc.perform(get("/admin/probe/custom-exception").with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"))
            .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
            .andExpect(content().string(containsString(ErrorCode.MEMBER_NOT_FOUND.message())))
            .andExpect(content().string(containsString("<html")))
            .andExpect(content().string(not(containsString("errorCode"))));
    }

    @Test
    void customExceptionOnHtmx_rendersOneLineErrorFragment() throws Exception {
        mockMvc.perform(get("/admin/probe/custom-exception").header(HTMX_HEADER, "true").with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/fragments/error-message :: error-message"))
            // 셸의 알림 영역에 오류 문구를 끼워 넣도록 대상과 방식을 지정한다
            .andExpect(header().string("HX-Retarget", "#htmx-error-notice"))
            .andExpect(header().string("HX-Reswap", "innerHTML"))
            .andExpect(content().string(containsString("class=\"error-message\"")))
            .andExpect(content().string(containsString(ErrorCode.MEMBER_NOT_FOUND.message())))
            .andExpect(content().string(not(containsString("<html"))));
    }

    @Test
    void customExceptionOnNormalRequest_hasNoHtmxHeaders() throws Exception {
        mockMvc.perform(get("/admin/probe/custom-exception").with(asAdmin()))
            .andExpect(header().doesNotExist("HX-Retarget"))
            .andExpect(header().doesNotExist("HX-Reswap"));
    }

    @Test
    void bindingFailure_rendersInvalidRequestInsteadOf500() throws Exception {
        mockMvc.perform(get("/admin/probe/binding").param("from", "not-a-date").with(asAdmin()))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.INVALID_REQUEST.message())));
    }

    @Test
    void methodValidationFailure_rendersInvalidRequestInsteadOf500() throws Exception {
        mockMvc.perform(get("/admin/probe/method-validation").param("size", "0").with(asAdmin()))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.INVALID_REQUEST.message())));
    }

    @Test
    void unreadableBody_rendersInvalidRequestInsteadOf500() throws Exception {
        mockMvc.perform(post("/admin/probe/body")
                .with(asAdmin())
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{not-json"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.INVALID_REQUEST.message())));
    }

    @Test
    void unexpectedException_rendersInternalErrorWithoutDetail() throws Exception {
        mockMvc.perform(get("/admin/probe/unexpected").with(asAdmin()))
            .andExpect(status().isInternalServerError())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.INTERNAL_SERVER_ERROR.message())))
            .andExpect(content().string(not(containsString(ProbeController.INTERNAL_DETAIL))));
    }

    @Test
    void accessDeniedException_propagatesToSecurityChain() throws Exception {
        // 화면 오류로 바꾸지 않고 다시 던져 관리자 체인의 접근 거부 처리(403 JSON)가 응답한다
        mockMvc.perform(get("/admin/probe/access-denied").with(asAdmin()))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Controller
    static class ProbeController {

        static final String INTERNAL_DETAIL = "select * from member where secret";

        @GetMapping("/admin/probe/custom-exception")
        String customException() {
            throw new CustomException(ErrorCode.MEMBER_NOT_FOUND);
        }

        @GetMapping("/admin/probe/unexpected")
        String unexpected() {
            throw new IllegalStateException(INTERNAL_DETAIL);
        }

        @GetMapping("/admin/probe/access-denied")
        String accessDenied() {
            throw new AccessDeniedException("거부");
        }

        // 필터 폼의 날짜 형식이 틀리면 바인딩 예외가 난다
        @GetMapping("/admin/probe/binding")
        String binding(@ModelAttribute ProbeFilter filter) {
            return "admin/error";
        }

        // 파라미터 제약 위반은 내장 메서드 검증 예외가 난다
        @GetMapping("/admin/probe/method-validation")
        String methodValidation(@RequestParam @Min(1) int size) {
            return "admin/error";
        }

        @PostMapping("/admin/probe/body")
        String body(@RequestBody ProbeFilter filter) {
            return "admin/error";
        }

    }

    record ProbeFilter(@DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from) {

    }

}
