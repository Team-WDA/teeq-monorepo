package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import java.util.List;
import kr.co.teeq.api.admin.application.dto.request.AdminOwnPasswordChangeRequest;
import kr.co.teeq.api.admin.application.service.AdminAccountService;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.principal.AuthenticatedAdmin;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

/**
 * 로그인한 관리자 본인의 비밀번호 변경 화면(모든 관리자). 성공하면 완료 문구가 있는 화면으로 돌아간다(PRG).
 * 입력 오류로 화면을 다시 그릴 때는 어떤 비밀번호도 응답에 싣지 않는다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/password")
public class AdminOwnPasswordController {

    private static final String OWN_PASSWORD_VIEW = "admin/own-password";
    private static final String PASSWORD_MISMATCH_MESSAGE = "새 비밀번호와 확인 값이 일치하지 않습니다.";

    private final AdminAccountService adminAccountService;
    private final Validator validator;

    @LogMonitoring
    @GetMapping
    public String ownPassword(@RequestParam(required = false) String changed, Model model) {
        model.addAttribute("changed", changed != null);
        return OWN_PASSWORD_VIEW;
    }

    @LogMonitoring
    @PostMapping
    public ModelAndView change(
        @AuthenticationPrincipal AuthenticatedAdmin admin,
        @RequestParam(defaultValue = "") String currentPassword,
        @RequestParam(defaultValue = "") String newPassword,
        @RequestParam(defaultValue = "") String newPasswordConfirm) {
        AdminOwnPasswordChangeRequest request =
            new AdminOwnPasswordChangeRequest(currentPassword, newPassword, newPasswordConfirm);
        List<String> formErrorMessages = validator.validate(request).stream()
            .map(ConstraintViolation::getMessage)
            .sorted()
            .toList();
        if (!formErrorMessages.isEmpty()) {
            return unprocessableScreen(formErrorMessages);
        }
        if (!newPassword.equals(newPasswordConfirm)) {
            return unprocessableScreen(List.of(PASSWORD_MISMATCH_MESSAGE));
        }

        try {
            adminAccountService.changeOwnPassword(admin.adminId(), currentPassword, newPassword);
        } catch (CustomException exception) {
            if (exception.getErrorCode() != ErrorCode.INVALID_CURRENT_PASSWORD) {
                throw exception;
            }
            return unprocessableScreen(List.of(exception.getErrorCode().message()));
        }
        return new ModelAndView("redirect:/admin/password?changed");
    }

    private ModelAndView unprocessableScreen(List<String> formErrorMessages) {
        ModelAndView modelAndView = new ModelAndView(OWN_PASSWORD_VIEW);
        modelAndView.addObject("changed", false);
        modelAndView.addObject("formErrorMessages", formErrorMessages);
        modelAndView.setStatus(HttpStatus.UNPROCESSABLE_CONTENT);
        return modelAndView;
    }

}
