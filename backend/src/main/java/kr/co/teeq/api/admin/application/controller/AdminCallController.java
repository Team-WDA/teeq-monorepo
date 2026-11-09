package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import java.time.LocalDate;
import java.time.ZoneId;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDetailResponse;
import kr.co.teeq.api.admin.application.service.AdminCallDetailService;
import kr.co.teeq.api.admin.application.view.AdminCallHistoryListModel;
import kr.co.teeq.api.admin.application.view.CallDisplayLabel;
import kr.co.teeq.api.call.application.dto.request.CallHistorySearchRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryPageResponse;
import kr.co.teeq.api.call.application.service.CallHistoryQueryService;
import kr.co.teeq.api.call.core.constant.CallStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * 통화 기록 화면. 전체 회원의 통화 목록(검색·필터·페이지 이동)과 통화 한 건의 상세(대화 포함)를 보여 준다.
 * 페이지 크기는 고정이라 Pageable을 받지 않고, 형식이 틀린 값은 오류 화면(400)으로 보인다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/calls")
public class AdminCallController {

    private static final String CALLS_PATH = "/admin/calls";
    private static final String CALLS_VIEW = "admin/calls";
    private static final String CALL_DETAIL_VIEW = "admin/call-detail";

    private final CallHistoryQueryService callHistoryQueryService;
    private final AdminCallDetailService adminCallDetailService;
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
        return CALLS_VIEW;
    }

    @LogMonitoring
    @GetMapping("/{call-session-id}")
    public String detail(@PathVariable("call-session-id") String callSessionId, Model model) {
        AdminCallDetailResponse detail = adminCallDetailService.getDetail(callSessionId);
        model.addAttribute("detail", detail);
        model.addAttribute("callStatusLabel", CallDisplayLabel.status(detail.call().status()));
        model.addAttribute("callEndReasonLabel", CallDisplayLabel.endReason(detail.call().endReason()));
        return CALL_DETAIL_VIEW;
    }

}
