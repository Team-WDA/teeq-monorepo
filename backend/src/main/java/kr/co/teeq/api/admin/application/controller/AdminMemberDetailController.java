package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.application.view.AdminCallHistoryListModel;
import kr.co.teeq.api.admin.application.view.AdminCallUsageModel;
import kr.co.teeq.api.admin.application.view.AdminFeedbackListModel;
import kr.co.teeq.api.admin.application.view.AdminTabs;
import kr.co.teeq.api.call.application.dto.request.CallBonusGrantRequest;
import kr.co.teeq.api.call.application.dto.request.CallHistorySearchRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryPageResponse;
import kr.co.teeq.api.call.application.service.CallBonusService;
import kr.co.teeq.api.call.application.service.CallHistoryQueryService;
import kr.co.teeq.api.call.application.service.CallLimitService;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.feedback.application.dto.request.FeedbackSearchRequest;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackPageResponse;
import kr.co.teeq.api.feedback.application.service.FeedbackQueryService;
import kr.co.teeq.api.member.application.service.MemberQueryService;
import kr.co.teeq.api.member.core.principal.AuthenticatedAdmin;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingSubmissionSearchRequest;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionPageResponse;
import kr.co.teeq.api.onboarding.application.service.OnboardingSubmissionQueryService;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.support.application.dto.response.BugReportPageResponse;
import kr.co.teeq.api.support.application.service.BugReportQueryService;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
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
 * 회원 허브 화면. 회원 헤더(위치 경로, 기본 요약, 삭제 버튼)와 탭 줄 아래에 탭별 화면을 보인다.
 * 이 컨트롤러는 개요·통화 기록·통화 사용량·추가 통화 시간·온보딩 응답·버그 제보·피드백 탭을 다루고, 모든 탭 핸들러는 헤더가 읽는 모델 변수를 같은 방식으로 채운다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/members/{member-id}")
public class AdminMemberDetailController {

    private static final String OVERVIEW_VIEW = "admin/member-overview";
    private static final String CALLS_VIEW = "admin/member-calls";
    private static final String CALL_USAGES_VIEW = "admin/member-call-usages";
    private static final String CALL_BONUSES_VIEW = "admin/member-call-bonuses";
    private static final String ONBOARDING_SUBMISSIONS_VIEW = "admin/member-onboarding-submissions";
    private static final String BUG_REPORTS_VIEW = "admin/member-bug-reports";
    private static final String FEEDBACKS_VIEW = "admin/member-feedbacks";
    private static final String MEMBERS_PATH = "/admin/members/";
    private static final int RECENT_CALL_COUNT = 5;

    private final MemberQueryService memberQueryService;
    private final CallHistoryQueryService callHistoryQueryService;
    private final CallBonusService callBonusService;
    private final CallLimitService callLimitService;
    private final OnboardingSubmissionQueryService onboardingSubmissionQueryService;
    private final BugReportQueryService bugReportQueryService;
    private final FeedbackQueryService feedbackQueryService;
    private final AdminCallUsageModel adminCallUsageModel;
    private final ZoneId koreaZoneId;
    private final Validator validator;

    @LogMonitoring
    @GetMapping
    public String overview(@PathVariable("member-id") UUID memberId, Model model) {
        addHubAttributes(model, memberId, AdminTabs.MEMBER_OVERVIEW_KEY);
        CallHistorySearchRequest request = new CallHistorySearchRequest(memberId, null, null, null, null, false);
        CallHistoryPageResponse recentCalls = callHistoryQueryService.search(request,
            PageRequest.of(0, RECENT_CALL_COUNT));
        model.addAttribute("callSummary", callHistoryQueryService.getMemberSummary(memberId));
        AdminCallHistoryListModel.populate(model, request, recentCalls, MEMBERS_PATH + memberId, false, koreaZoneId);
        model.addAttribute("allCallsPath", MEMBERS_PATH + memberId + "/calls");
        return OVERVIEW_VIEW;
    }

    @LogMonitoring
    @GetMapping("/calls")
    public String calls(
        @PathVariable("member-id") UUID memberId,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(required = false) CallStatus status,
        @RequestParam(defaultValue = "false") boolean abnormalOnly,
        @RequestParam(defaultValue = "0") int page,
        Model model) {
        addHubAttributes(model, memberId, AdminTabs.MEMBER_CALLS_KEY);
        CallHistorySearchRequest request = new CallHistorySearchRequest(memberId, null, from, to, status,
            abnormalOnly);
        CallHistoryPageResponse result = callHistoryQueryService.search(request,
            AdminCallHistoryListModel.pageable(page));
        AdminCallHistoryListModel.populate(model, request, result, MEMBERS_PATH + memberId + "/calls", false,
            koreaZoneId);
        return CALLS_VIEW;
    }

    @LogMonitoring
    @GetMapping("/call-usages")
    public String callUsages(
        @PathVariable("member-id") UUID memberId,
        @RequestParam(defaultValue = "DAY") CallUsageUnit unit,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        Model model) {
        addHubAttributes(model, memberId, AdminTabs.MEMBER_CALL_USAGES_KEY);
        adminCallUsageModel.populate(model, unit, from, to, memberId, MEMBERS_PATH + memberId + "/call-usages");
        return CALL_USAGES_VIEW;
    }

    @LogMonitoring
    @GetMapping("/call-bonuses")
    public String callBonuses(@PathVariable("member-id") UUID memberId, Model model) {
        addCallBonusAttributes(model, memberId);
        return CALL_BONUSES_VIEW;
    }

    // bonusDate는 비우면 서비스가 오늘(KST)로 처리한다. 입력 오류는 서비스를 부르지 않고 폼에 한국어 문구로 보인다
    @LogMonitoring
    @PostMapping("/call-bonuses/grant")
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
            addCallBonusAttributes(model, memberId);
            model.addAttribute("formErrorMessages", formErrorMessages);
            model.addAttribute("submittedSeconds", seconds);
            model.addAttribute("submittedBonusDate", bonusDate);
            model.addAttribute("submittedReason", reason);
            ModelAndView modelAndView = new ModelAndView(CALL_BONUSES_VIEW, model.asMap());
            modelAndView.setStatus(HttpStatus.UNPROCESSABLE_CONTENT);
            return modelAndView;
        }

        callBonusService.grant(admin.adminId(), memberId, request);
        return new ModelAndView(callBonusesRedirect(memberId));
    }

    @LogMonitoring
    @PostMapping("/call-bonuses/{call-bonus-id}/cancel")
    public String cancelBonus(
        @AuthenticationPrincipal AuthenticatedAdmin admin,
        @PathVariable("member-id") UUID memberId,
        @PathVariable("call-bonus-id") UUID callBonusId) {
        callBonusService.cancel(admin.adminId(), memberId, callBonusId);
        return callBonusesRedirect(memberId);
    }

    // 경로 회원으로 고정하므로 memberId 쿼리 파라미터는 받지 않는다(있어도 무시)
    @LogMonitoring
    @GetMapping("/onboarding-submissions")
    public String onboardingSubmissions(
        @PathVariable("member-id") UUID memberId,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(required = false) OnboardingOption optionCode,
        @RequestParam(required = false) Boolean active,
        @RequestParam(defaultValue = "0") int page,
        Model model) {
        addHubAttributes(model, memberId, AdminTabs.MEMBER_ONBOARDING_SUBMISSIONS_KEY);
        OnboardingSubmissionSearchRequest request =
            new OnboardingSubmissionSearchRequest(memberId, from, to, optionCode, active);
        OnboardingSubmissionPageResponse result =
            onboardingSubmissionQueryService.search(request, AdminCallHistoryListModel.pageable(page));

        String basePath = MEMBERS_PATH + memberId + "/onboarding-submissions";
        long totalPages = (result.totalElements() + result.size() - 1) / result.size();
        model.addAttribute("showMember", false);
        model.addAttribute("onboardingBasePath", basePath);
        model.addAttribute("from", from);
        model.addAttribute("to", to);
        model.addAttribute("optionCode", optionCode);
        // 셸 조각의 매개변수 active와 이름이 겹치지 않게 activeFilter로 둔다
        model.addAttribute("activeFilter", active);
        model.addAttribute("optionCodes", OnboardingOption.values());
        model.addAttribute("result", result);
        model.addAttribute("currentPageNumber", result.page() + 1);
        model.addAttribute("totalPages", Math.max(totalPages, 1));
        if (result.page() > 0) {
            model.addAttribute("previousPageUrl", onboardingPageUrl(basePath, request, result.page() - 1));
        }
        if (result.page() + 1 < totalPages) {
            model.addAttribute("nextPageUrl", onboardingPageUrl(basePath, request, result.page() + 1));
        }
        return ONBOARDING_SUBMISSIONS_VIEW;
    }

    @LogMonitoring
    @GetMapping("/bug-reports")
    public String bugReports(
        @PathVariable("member-id") UUID memberId,
        @RequestParam(required = false) BugReportStatus status,
        @RequestParam(required = false) BugReportSource source,
        @RequestParam(defaultValue = "0") int page,
        Model model) {
        addHubAttributes(model, memberId, AdminTabs.MEMBER_BUG_REPORTS_KEY);
        BugReportPageResponse result = bugReportQueryService.search(status, source, memberId,
            AdminCallHistoryListModel.pageable(page));

        String basePath = MEMBERS_PATH + memberId + "/bug-reports";
        long totalPages = (result.totalElements() + result.size() - 1) / result.size();
        model.addAttribute("showMember", false);
        model.addAttribute("bugReportBasePath", basePath);
        model.addAttribute("statusFilter", status);
        model.addAttribute("sourceFilter", source);
        model.addAttribute("statuses", BugReportStatus.values());
        model.addAttribute("sources", BugReportSource.values());
        model.addAttribute("result", result);
        model.addAttribute("currentPageNumber", result.page() + 1);
        model.addAttribute("totalPages", Math.max(totalPages, 1));
        if (result.page() > 0) {
            model.addAttribute("previousPageUrl", bugReportPageUrl(basePath, status, source, result.page() - 1));
        }
        if (result.page() + 1 < totalPages) {
            model.addAttribute("nextPageUrl", bugReportPageUrl(basePath, status, source, result.page() + 1));
        }
        return BUG_REPORTS_VIEW;
    }

    // 경로 회원으로 고정하므로 memberId 쿼리 파라미터는 받지 않는다(있어도 무시)
    @LogMonitoring
    @GetMapping("/feedbacks")
    public String feedbacks(
        @PathVariable("member-id") UUID memberId,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(required = false) Integer rating,
        @RequestParam(defaultValue = "false") boolean detailedOnly,
        @RequestParam(defaultValue = "0") int page,
        Model model) {
        addHubAttributes(model, memberId, AdminTabs.MEMBER_FEEDBACKS_KEY);
        FeedbackSearchRequest request = new FeedbackSearchRequest(memberId, from, to, rating, detailedOnly);
        FeedbackPageResponse result = feedbackQueryService.search(request, AdminCallHistoryListModel.pageable(page));
        AdminFeedbackListModel.populate(model, request, result, MEMBERS_PATH + memberId + "/feedbacks", false);
        return FEEDBACKS_VIEW;
    }

    // 이전/다음 링크: 값이 있는 필터만 싣고 회원 고정 경로를 벗어나지 않는다
    private String onboardingPageUrl(String basePath, OnboardingSubmissionSearchRequest request, int page) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromPath(basePath);
        if (request.from() != null) {
            builder.queryParam("from", request.from());
        }
        if (request.to() != null) {
            builder.queryParam("to", request.to());
        }
        if (request.optionCode() != null) {
            builder.queryParam("optionCode", request.optionCode().name());
        }
        if (request.active() != null) {
            builder.queryParam("active", request.active());
        }
        return builder.queryParam("page", page).build().encode().toUriString();
    }

    private String bugReportPageUrl(String basePath, BugReportStatus status, BugReportSource source, int page) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromPath(basePath);
        if (status != null) {
            builder.queryParam("status", status.name());
        }
        if (source != null) {
            builder.queryParam("source", source.name());
        }
        return builder.queryParam("page", page).build().encode().toUriString();
    }

    // 추가 통화 시간 탭 화면 변수: 오늘 한도 현황, 누적 통화 요약, 부여 이력
    private void addCallBonusAttributes(Model model, UUID memberId) {
        addHubAttributes(model, memberId, AdminTabs.MEMBER_CALL_BONUSES_KEY);
        model.addAttribute("todayLimit", callLimitService.getTodayLimit(memberId));
        model.addAttribute("callSummary", callHistoryQueryService.getMemberSummary(memberId));
        model.addAttribute("bonuses", callBonusService.getAll(memberId));
    }

    private String callBonusesRedirect(UUID memberId) {
        return "redirect:" + MEMBERS_PATH + memberId + "/call-bonuses";
    }

    // 허브 헤더와 탭 줄이 읽는 변수: 회원 요약, 탭 목록, 활성 탭 키
    private void addHubAttributes(Model model, UUID memberId, String activeTab) {
        model.addAttribute("member", memberQueryService.getSummary(memberId));
        model.addAttribute("memberTabs", AdminTabs.memberHub(memberId));
        model.addAttribute("activeTab", activeTab);
    }

}
