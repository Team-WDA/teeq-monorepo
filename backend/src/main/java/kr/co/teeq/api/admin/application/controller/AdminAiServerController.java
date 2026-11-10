package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import java.time.LocalDate;
import kr.co.teeq.api.admin.application.service.AdminAiMetricsService;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * AI 서버 화면. AI 서버의 기간별 지연·비용과 BE 비정상 종료 건수를 보여 준다.
 * AI 서버가 응답하지 못해도 서비스가 unavailable로 돌려주므로 오류 화면 없이 200으로 실패 상태를 그린다.
 * 형식이 틀린 값과 시작일이 종료일보다 늦은 기간은 오류 화면(400)으로 보인다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/ai-server")
public class AdminAiServerController {

    private static final String AI_SERVER_VIEW = "admin/ai-server";
    private static final String AI_SERVER_SUMMARY_FRAGMENT = "admin/fragments/ai-server-summary :: ai-server-summary";

    private final AdminAiMetricsService adminAiMetricsService;

    @LogMonitoring
    @GetMapping
    public String metrics(
        @RequestParam(defaultValue = "DAY") CallUsageUnit unit,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        Model model) {
        model.addAttribute("metrics", adminAiMetricsService.getMetrics(unit, from, to));
        model.addAttribute("unit", unit);
        model.addAttribute("from", from);
        model.addAttribute("to", to);
        return AI_SERVER_VIEW;
    }

    // 대시보드 AI 서버 상태 카드의 htmx 조각. AI 서버가 실패해도 200으로 실패 상태 조각을 돌려준다
    @LogMonitoring
    @GetMapping("/summary")
    public String summary(Model model) {
        model.addAttribute("summary", adminAiMetricsService.getSummary());
        return AI_SERVER_SUMMARY_FRAGMENT;
    }

}
