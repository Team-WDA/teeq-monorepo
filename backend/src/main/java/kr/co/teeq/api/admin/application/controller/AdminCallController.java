package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDetailResponse;
import kr.co.teeq.api.admin.application.service.AdminCallDetailService;
import kr.co.teeq.api.admin.application.view.AdminCallHistoryListModel;
import kr.co.teeq.api.admin.application.view.AdminCallUsageModel;
import kr.co.teeq.api.admin.application.view.AdminTabs;
import kr.co.teeq.api.admin.application.view.CallDisplayLabel;
import kr.co.teeq.api.admin.application.view.FeedbackDisplayLabel;
import kr.co.teeq.api.call.application.dto.request.CallHistorySearchRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryPageResponse;
import kr.co.teeq.api.call.application.service.CallHistoryQueryService;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.feedback.application.dto.response.CallFeedbackResponse;
import kr.co.teeq.api.feedback.application.service.FeedbackQueryService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * 통화 기록 화면. 전체 회원의 통화 목록(검색·필터·페이지 이동), 사용량 집계, 통화 한 건의 상세(대화·피드백 포함)를 보여 준다.
 * 페이지 크기는 고정이라 Pageable을 받지 않고, 형식이 틀린 값은 오류 화면(400)으로 보인다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/calls")
public class AdminCallController {

    private static final String CALLS_PATH = "/admin/calls";
    private static final String CALLS_VIEW = "admin/calls";
    private static final String CALL_USAGES_PATH = "/admin/calls/usages";
    private static final String CALL_USAGES_VIEW = "admin/call-usages";
    private static final String CALL_DETAIL_VIEW = "admin/call-detail";

    private final CallHistoryQueryService callHistoryQueryService;
    private final AdminCallDetailService adminCallDetailService;
    private final AdminCallUsageModel adminCallUsageModel;
    private final FeedbackQueryService feedbackQueryService;
    private final ZoneId koreaZoneId;

    @LogMonitoring
    @GetMapping
    public String calls(
        @RequestParam(required = false) String keyword,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(required = false) CallStatus status,
        @RequestParam(defaultValue = "false") boolean abnormalOnly,
        @RequestParam(defaultValue = "0") int page,
        Model model) {
        CallHistorySearchRequest request = new CallHistorySearchRequest(
            null, AdminCallHistoryListModel.normalizeKeyword(keyword), from, to, status, abnormalOnly);
        CallHistoryPageResponse result = callHistoryQueryService.search(
            request, AdminCallHistoryListModel.pageable(page));
        AdminCallHistoryListModel.populate(model, request, result, CALLS_PATH, true, koreaZoneId);
        addTabAttributes(model, AdminTabs.CALLS_LIST_KEY);
        return CALLS_VIEW;
    }

    // 리터럴 경로라 /{call-session-id}보다 먼저 매핑된다
    @LogMonitoring
    @GetMapping("/usages")
    public String usages(
        @RequestParam(defaultValue = "DAY") CallUsageUnit unit,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        Model model) {
        adminCallUsageModel.populate(model, unit, from, to, null, CALL_USAGES_PATH);
        addTabAttributes(model, AdminTabs.CALLS_USAGES_KEY);
        return CALL_USAGES_VIEW;
    }

    @LogMonitoring
    @GetMapping("/{call-session-id}")
    public String detail(@PathVariable("call-session-id") String callSessionId, Model model) {
        AdminCallDetailResponse detail = adminCallDetailService.getDetail(callSessionId);
        model.addAttribute("detail", detail);
        model.addAttribute("callStatusLabel", CallDisplayLabel.status(detail.call().status()));
        model.addAttribute("callEndReasonLabel", CallDisplayLabel.endReason(detail.call().endReason()));
        // AI 서버를 부르는 상세 서비스가 트랜잭션을 잡지 않도록 피드백은 상세 조회 뒤에 따로 조회한다
        feedbackQueryService.getByCallSessionId(callSessionId)
            .ifPresent(feedback -> addFeedbackAttributes(model, feedback));
        return CALL_DETAIL_VIEW;
    }

    // 피드백 영역 변수: 응답 그대로와 enum 값의 한국어 라벨(지난 통화 기억은 없으면 넣지 않는다)
    private void addFeedbackAttributes(Model model, CallFeedbackResponse feedback) {
        CallFeedbackResponse.RequiredPart required = feedback.required();
        model.addAttribute("feedback", feedback);
        model.addAttribute("feedbackRevisitIntentionLabel",
            FeedbackDisplayLabel.revisitIntention(required.revisitIntention()));
        if (required.previousCallRecall() != null) {
            model.addAttribute("feedbackPreviousCallRecallLabel",
                FeedbackDisplayLabel.previousCallRecall(required.previousCallRecall()));
        }
        model.addAttribute("feedbackAwkwardMomentLabels",
            required.awkwardMoments().stream().map(FeedbackDisplayLabel::awkwardMoment).toList());
        List<String> startReasonLabels = feedback.detailed() == null
            ? List.of()
            : feedback.detailed().startReasons().stream().map(FeedbackDisplayLabel::startReason).toList();
        model.addAttribute("feedbackStartReasonLabels", startReasonLabels);
    }

    private void addTabAttributes(Model model, String activeTab) {
        model.addAttribute("callTabs", AdminTabs.calls());
        model.addAttribute("activeTab", activeTab);
    }

}
