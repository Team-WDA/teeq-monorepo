package kr.co.teeq.api.admin.application.controller;

import io.swagger.v3.oas.annotations.Hidden;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.application.dto.request.AdminAccountCreateRequest;
import kr.co.teeq.api.admin.application.dto.request.AdminPasswordResetRequest;
import kr.co.teeq.api.admin.application.service.AdminAccountService;
import kr.co.teeq.api.member.core.constant.AdminRole;
import kr.co.teeq.api.member.core.principal.AuthenticatedAdmin;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

/**
 * 관리자 계정 관리 화면(SUPER_ADMIN 전용, 접근 제어는 관리자 보안 체인이 한다). 성공하면 목록으로 돌아간다(PRG).
 * 입력 오류로 화면을 다시 그릴 때는 비밀번호를 응답에 싣지 않는다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/accounts")
public class AdminAccountController {

    private static final String ACCOUNTS_VIEW = "admin/accounts";
    private static final String ACCOUNTS_REDIRECT = "redirect:/admin/accounts";

    private final AdminAccountService adminAccountService;
    private final Validator validator;

    @GetMapping
    public String accounts(@AuthenticationPrincipal AuthenticatedAdmin admin, Model model) {
        addScreenAttributes(model, admin);
        return ACCOUNTS_VIEW;
    }

    @PostMapping
    public ModelAndView create(
        @AuthenticationPrincipal AuthenticatedAdmin admin,
        @RequestParam(defaultValue = "") String username,
        @RequestParam(defaultValue = "") String password,
        @RequestParam(defaultValue = "") String name,
        @RequestParam(required = false) AdminRole role,
        Model model) {
        AdminAccountCreateRequest request = new AdminAccountCreateRequest(username, password, name, role);
        List<String> formErrorMessages = validate(request);
        if (!formErrorMessages.isEmpty()) {
            // 비밀번호는 다시 싣지 않는다
            model.addAttribute("submittedUsername", username);
            model.addAttribute("submittedName", name);
            model.addAttribute("submittedRole", role);
            return unprocessableScreen(admin, model, formErrorMessages);
        }

        adminAccountService.create(admin.adminId(), request);
        return new ModelAndView(ACCOUNTS_REDIRECT);
    }

    @PostMapping("/{admin-id}/role")
    public String changeRole(
        @AuthenticationPrincipal AuthenticatedAdmin admin,
        @PathVariable("admin-id") UUID targetAdminId,
        @RequestParam AdminRole role) {
        adminAccountService.changeRole(admin.adminId(), targetAdminId, role);
        return ACCOUNTS_REDIRECT;
    }

    @PostMapping("/{admin-id}/deactivate")
    public String deactivate(
        @AuthenticationPrincipal AuthenticatedAdmin admin,
        @PathVariable("admin-id") UUID targetAdminId) {
        adminAccountService.deactivate(admin.adminId(), targetAdminId);
        return ACCOUNTS_REDIRECT;
    }

    @PostMapping("/{admin-id}/password")
    public ModelAndView resetPassword(
        @AuthenticationPrincipal AuthenticatedAdmin admin,
        @PathVariable("admin-id") UUID targetAdminId,
        @RequestParam(defaultValue = "") String newPassword,
        Model model) {
        List<String> formErrorMessages = validate(new AdminPasswordResetRequest(newPassword));
        if (!formErrorMessages.isEmpty()) {
            return unprocessableScreen(admin, model, formErrorMessages);
        }

        adminAccountService.resetPassword(admin.adminId(), targetAdminId, newPassword);
        return new ModelAndView(ACCOUNTS_REDIRECT);
    }

    private List<String> validate(Object request) {
        return validator.validate(request).stream()
            .map(ConstraintViolation::getMessage)
            .sorted()
            .toList();
    }

    private ModelAndView unprocessableScreen(AuthenticatedAdmin admin, Model model, List<String> formErrorMessages) {
        addScreenAttributes(model, admin);
        model.addAttribute("formErrorMessages", formErrorMessages);
        ModelAndView modelAndView = new ModelAndView(ACCOUNTS_VIEW, model.asMap());
        modelAndView.setStatus(HttpStatus.UNPROCESSABLE_CONTENT);
        return modelAndView;
    }

    private void addScreenAttributes(Model model, AuthenticatedAdmin admin) {
        model.addAttribute("accounts", adminAccountService.getAll());
        model.addAttribute("roles", AdminRole.values());
        model.addAttribute("currentAdminId", admin.adminId());
    }

}
