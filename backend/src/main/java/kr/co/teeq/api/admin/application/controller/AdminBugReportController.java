package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import java.util.UUID;
import kr.co.teeq.api.support.application.dto.response.BugReportDetailResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportPageResponse;
import kr.co.teeq.api.support.application.service.BugReportCommandService;
import kr.co.teeq.api.support.application.service.BugReportQueryService;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
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
 * 버그 제보 화면. 목록(상태·출처 필터, 페이지 이동), 상세(본문·환경·이미지·로그), 상태 변경을 다룬다.
 * 상태 변경은 htmx로 보내고 응답은 상태 폼 조각만 돌려준다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/bug-reports")
public class AdminBugReportController {

    private static final String BUG_REPORTS_PATH = "/admin/bug-reports";
    private static final String BUG_REPORTS_VIEW = "admin/bug-reports";
    private static final String BUG_REPORT_DETAIL_VIEW = "admin/bug-report-detail";
    private static final String STATUS_FORM_FRAGMENT = "admin/fragments/bug-report-status-form :: bug-report-status-form";

    private final BugReportQueryService bugReportQueryService;
    private final BugReportCommandService bugReportCommandService;

    @LogMonitoring
    @GetMapping
    public String bugReports(
        @RequestParam(required = false) BugReportStatus status,
        @RequestParam(required = false) BugReportSource source,
        Pageable pageable,
        Model model) {
        BugReportPageResponse result = bugReportQueryService.search(status, source, clampPage(pageable));

        long totalPages = (result.totalElements() + result.size() - 1) / result.size();
        model.addAttribute("statusFilter", status);
        model.addAttribute("sourceFilter", source);
        model.addAttribute("statuses", BugReportStatus.values());
        model.addAttribute("sources", BugReportSource.values());
        model.addAttribute("result", result);
        model.addAttribute("currentPageNumber", result.page() + 1);
        model.addAttribute("totalPages", Math.max(totalPages, 1));
        if (result.page() > 0) {
            model.addAttribute("previousPageUrl", pageUrl(status, source, result.page() - 1, result.size()));
        }
        if (result.page() + 1 < totalPages) {
            model.addAttribute("nextPageUrl", pageUrl(status, source, result.page() + 1, result.size()));
        }
        return BUG_REPORTS_VIEW;
    }

    @LogMonitoring
    @GetMapping("/{bug-report-id}")
    public String detail(@PathVariable("bug-report-id") UUID bugReportId, Model model) {
        BugReportDetailResponse bugReport = bugReportQueryService.getDetail(bugReportId);
        model.addAttribute("bugReport", bugReport);
        model.addAttribute("bugReportId", bugReport.id());
        model.addAttribute("currentStatus", bugReport.status());
        model.addAttribute("statuses", BugReportStatus.values());
        return BUG_REPORT_DETAIL_VIEW;
    }

    // 같은 상태로 바꾸면 서비스가 STATE_CONFLICT를 던지고 공통 오류 처리가 알림으로 보인다
    @LogMonitoring
    @PostMapping("/{bug-report-id}/status")
    public ModelAndView changeStatus(
        @PathVariable("bug-report-id") UUID bugReportId,
        @RequestParam BugReportStatus status) {
        BugReportStatus changed = bugReportCommandService.changeStatus(bugReportId, status);
        return new ModelAndView(STATUS_FORM_FRAGMENT)
            .addObject("bugReportId", bugReportId)
            .addObject("currentStatus", changed)
            .addObject("statuses", BugReportStatus.values());
    }

    // page * size가 int 범위를 넘으면 조회 오프셋이 넘쳐 500이 되므로, 넘치지 않는 마지막 페이지로 줄인다
    private Pageable clampPage(Pageable pageable) {
        int size = pageable.getPageSize();
        return PageRequest.of(Math.min(pageable.getPageNumber(), Integer.MAX_VALUE / size), size);
    }

    // 이전/다음 링크: 값이 있는 필터만 그대로 싣는다
    private String pageUrl(BugReportStatus status, BugReportSource source, int page, int size) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromPath(BUG_REPORTS_PATH);
        if (status != null) {
            builder.queryParam("status", status.name());
        }
        if (source != null) {
            builder.queryParam("source", source.name());
        }
        return builder.queryParam("page", page).queryParam("size", size).build().encode().toUriString();
    }

}
