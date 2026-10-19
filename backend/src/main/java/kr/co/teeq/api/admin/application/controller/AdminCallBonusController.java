package kr.co.teeq.api.admin.application.controller;

import io.swagger.v3.oas.annotations.Hidden;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.request.CallBonusGrantRequest;
import kr.co.teeq.api.call.application.service.CallBonusService;
import kr.co.teeq.api.member.core.principal.AuthenticatedAdmin;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
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
 * 통화 보너스 화면. 회원 UUID를 정하면 부여 이력 표와 부여 폼을 보여 주고, 부여·취소가 성공하면 같은 회원의 목록으로 돌아간다(PRG).
 * 서비스의 {@code getAll}은 회원 존재를 확인하지 않으므로 없는 회원은 빈 목록으로 보이고, 부여할 때 서비스가 회원 없음 오류를 낸다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/call-bonuses")
public class AdminCallBonusController {

    private static final String CALL_BONUSES_VIEW = "admin/call-bonuses";
    private static final String CALL_BONUSES_REDIRECT_PREFIX = "redirect:/admin/call-bonuses?memberId=";

    private final CallBonusService callBonusService;
    private final Validator validator;

    @GetMapping
    public String callBonuses(@RequestParam(required = false) UUID memberId, Model model) {
        addScreenAttributes(model, memberId);
        return CALL_BONUSES_VIEW;
    }

    // bonusDate는 비우면 서비스가 오늘(KST)로 처리한다. 입력 오류는 서비스를 부르지 않고 폼에 한국어 문구로 보인다
    @PostMapping("/grant")
    public ModelAndView grant(
        @AuthenticationPrincipal AuthenticatedAdmin admin,
        @RequestParam UUID memberId,
        @RequestParam(required = false) Integer seconds,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate bonusDate,
        @RequestParam(defaultValue = "") String reason,
        Model model) {
        CallBonusGrantRequest request = new CallBonusGrantRequest(seconds, bonusDate, reason);
        List<String> formErrorMessages = validator.validate(request).stream()
            .map(ConstraintViolation::getMessage)
            .sorted()
            .toList();
        if (!formErrorMessages.isEmpty()) {
            addScreenAttributes(model, memberId);
            model.addAttribute("formErrorMessages", formErrorMessages);
            model.addAttribute("submittedSeconds", seconds);
            model.addAttribute("submittedBonusDate", bonusDate);
            model.addAttribute("submittedReason", reason);
            ModelAndView modelAndView = new ModelAndView(CALL_BONUSES_VIEW, model.asMap());
            modelAndView.setStatus(HttpStatus.UNPROCESSABLE_CONTENT);
            return modelAndView;
        }

        callBonusService.grant(admin.adminId(), memberId, request);
        return new ModelAndView(CALL_BONUSES_REDIRECT_PREFIX + memberId);
    }

    @PostMapping("/{call-bonus-id}/cancel")
    public String cancel(
        @AuthenticationPrincipal AuthenticatedAdmin admin,
        @PathVariable("call-bonus-id") UUID callBonusId,
        @RequestParam UUID memberId) {
        callBonusService.cancel(admin.adminId(), memberId, callBonusId);
        return CALL_BONUSES_REDIRECT_PREFIX + memberId;
    }

    // 회원을 정하지 않았으면 UUID 입력 폼만 보이도록 목록을 싣지 않는다
    private void addScreenAttributes(Model model, UUID memberId) {
        model.addAttribute("memberId", memberId);
        if (memberId != null) {
            model.addAttribute("bonuses", callBonusService.getAll(memberId));
        }
    }

}
