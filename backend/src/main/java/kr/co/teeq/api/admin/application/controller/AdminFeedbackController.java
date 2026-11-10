package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import java.time.LocalDate;
import kr.co.teeq.api.admin.application.view.AdminCallHistoryListModel;
import kr.co.teeq.api.admin.application.view.AdminFeedbackListModel;
import kr.co.teeq.api.feedback.application.dto.request.FeedbackSearchRequest;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackPageResponse;
import kr.co.teeq.api.feedback.application.service.FeedbackQueryService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * 피드백 화면. 전체 회원의 통화 피드백 목록(기간·별점·상세 제출 필터, 페이지 이동)을 보이고 행은 통화 상세로 이어진다.
 * 페이지 크기는 고정이라 Pageable을 받지 않고, 형식이 틀린 값은 오류 화면(400)으로 보인다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/feedbacks")
public class AdminFeedbackController {

    private static final String FEEDBACKS_PATH = "/admin/feedbacks";
    private static final String FEEDBACKS_VIEW = "admin/feedbacks";

    private final FeedbackQueryService feedbackQueryService;

    @LogMonitoring
    @GetMapping
    public String feedbacks(
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(required = false) Integer rating,
        @RequestParam(defaultValue = "false") boolean detailedOnly,
        @RequestParam(defaultValue = "0") int page,
        Model model) {
        FeedbackSearchRequest request = new FeedbackSearchRequest(null, from, to, rating, detailedOnly);
        FeedbackPageResponse result = feedbackQueryService.search(request, AdminCallHistoryListModel.pageable(page));
        AdminFeedbackListModel.populate(model, request, result, FEEDBACKS_PATH, true);
        return FEEDBACKS_VIEW;
    }

}
