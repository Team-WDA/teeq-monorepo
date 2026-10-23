package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.request.CallBonusGrantRequest;
import kr.co.teeq.api.call.application.service.CallBonusService;
import kr.co.teeq.api.member.application.dto.request.MemberSearchRequest;
import kr.co.teeq.api.member.application.dto.response.MemberPageResponse;
import kr.co.teeq.api.member.application.service.MemberDeletionService;
import kr.co.teeq.api.member.application.service.MemberQueryService;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.principal.AuthenticatedAdmin;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
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
import org.springframework.web.util.UriComponentsBuilder;

/**
 * 회원 관리 화면. 목록(검색·필터·페이지 이동), 상세(기본 정보, 통화 보너스 부여·취소·이력), 회원 삭제를 다룬다.
 * 삭제는 SUPER_ADMIN만 호출할 수 있고(보안 설정에서 막는다), 성공하면 목록으로 돌아가 안내를 보인다(PRG).
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/members")
public class AdminMemberController {

    private static final String MEMBERS_PATH = "/admin/members";
    private static final String MEMBERS_VIEW = "admin/members";
    private static final String MEMBER_DETAIL_VIEW = "admin/member-detail";
    private static final String MEMBER_DETAIL_REDIRECT_PREFIX = "redirect:/admin/members/";

    private final MemberQueryService memberQueryService;
    private final MemberDeletionService memberDeletionService;
    private final CallBonusService callBonusService;
    private final Validator validator;

    @LogMonitoring
    @GetMapping
    public String members(
        @RequestParam(required = false) String keyword,
        @RequestParam(required = false) LoginType loginType,
        @RequestParam(required = false) Boolean deleted,
        Pageable pageable,
        Model model) {
        MemberSearchRequest request = new MemberSearchRequest(keyword, loginType);
        MemberPageResponse result = memberQueryService.search(request, clampPage(pageable));

        long totalPages = (result.totalElements() + result.size() - 1) / result.size();
        model.addAttribute("keyword", keyword);
        model.addAttribute("loginType", loginType);
        model.addAttribute("loginTypes", LoginType.values());
        model.addAttribute("deletedNotice", Boolean.TRUE.equals(deleted));
        model.addAttribute("result", result);
        model.addAttribute("currentPageNumber", result.page() + 1);
        model.addAttribute("totalPages", Math.max(totalPages, 1));
        if (result.page() > 0) {
            model.addAttribute("previousPageUrl", pageUrl(request, result.page() - 1, result.size()));
        }
        if (result.page() + 1 < totalPages) {
            model.addAttribute("nextPageUrl", pageUrl(request, result.page() + 1, result.size()));
        }
        return MEMBERS_VIEW;
    }

    @LogMonitoring
    @GetMapping("/{member-id}")
    public String detail(@PathVariable("member-id") UUID memberId, Model model) {
        addDetailAttributes(model, memberId);
        return MEMBER_DETAIL_VIEW;
    }

    // bonusDate는 비우면 서비스가 오늘(KST)로 처리한다. 입력 오류는 서비스를 부르지 않고 폼에 한국어 문구로 보인다
    @LogMonitoring
    @PostMapping("/{member-id}/call-bonuses/grant")
    public ModelAndView grantBonus(
        @AuthenticationPrincipal AuthenticatedAdmin admin,
        @PathVariable("member-id") UUID memberId,
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
            addDetailAttributes(model, memberId);
            model.addAttribute("formErrorMessages", formErrorMessages);
            model.addAttribute("submittedSeconds", seconds);
            model.addAttribute("submittedBonusDate", bonusDate);
            model.addAttribute("submittedReason", reason);
            ModelAndView modelAndView = new ModelAndView(MEMBER_DETAIL_VIEW, model.asMap());
            modelAndView.setStatus(HttpStatus.UNPROCESSABLE_CONTENT);
            return modelAndView;
        }

        callBonusService.grant(admin.adminId(), memberId, request);
        return new ModelAndView(MEMBER_DETAIL_REDIRECT_PREFIX + memberId);
    }

    @LogMonitoring
    @PostMapping("/{member-id}/call-bonuses/{call-bonus-id}/cancel")
    public String cancelBonus(
        @AuthenticationPrincipal AuthenticatedAdmin admin,
        @PathVariable("member-id") UUID memberId,
        @PathVariable("call-bonus-id") UUID callBonusId) {
        callBonusService.cancel(admin.adminId(), memberId, callBonusId);
        return MEMBER_DETAIL_REDIRECT_PREFIX + memberId;
    }

    @LogMonitoring
    @PostMapping("/{member-id}/delete")
    public String delete(@PathVariable("member-id") UUID memberId) {
        memberDeletionService.delete(memberId);
        return "redirect:" + MEMBERS_PATH + "?deleted=true";
    }

    private void addDetailAttributes(Model model, UUID memberId) {
        model.addAttribute("member", memberQueryService.getSummary(memberId));
        model.addAttribute("bonuses", callBonusService.getAll(memberId));
    }

    // page * size가 int 범위를 넘으면 조회 오프셋이 넘쳐 500이 되므로, 넘치지 않는 마지막 페이지로 줄인다
    private Pageable clampPage(Pageable pageable) {
        int size = pageable.getPageSize();
        return PageRequest.of(Math.min(pageable.getPageNumber(), Integer.MAX_VALUE / size), size);
    }

    // 이전/다음 링크: 값이 있는 필터만 그대로 싣는다
    private String pageUrl(MemberSearchRequest request, int page, int size) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromPath(MEMBERS_PATH);
        if (request.keyword() != null && !request.keyword().isBlank()) {
            builder.queryParam("keyword", request.keyword());
        }
        if (request.loginType() != null) {
            builder.queryParam("loginType", request.loginType().name());
        }
        return builder.queryParam("page", page).queryParam("size", size).build().encode().toUriString();
    }

}
