package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.call.application.service.CallUsageService;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * 통화 사용량 화면. 필터는 GET 쿼리스트링에 남기며, 형식이 틀린 값은 오류 화면(400)으로 보인다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/call-usages")
public class AdminCallUsageController {

    private static final String CALL_USAGES_VIEW = "admin/call-usages";
    // 기간을 주지 않았을 때 보여 주는 최근 일수(오늘 포함)
    private static final int DEFAULT_RANGE_DAYS = 7;

    private final CallUsageService callUsageService;
    private final Clock clock;
    private final ZoneId koreaZoneId;

    @LogMonitoring
    @GetMapping
    public String callUsages(
        @RequestParam(defaultValue = "DAY") CallUsageUnit unit,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(required = false) UUID memberId,
        Model model) {
        LocalDate toDate = to != null ? to : LocalDate.now(clock.withZone(koreaZoneId));
        LocalDate fromDate = from != null ? from : toDate.minusDays(DEFAULT_RANGE_DAYS - 1);

        List<CallUsageResponse> usages = callUsageService.getUsages(unit, fromDate, toDate, memberId);

        model.addAttribute("unit", unit);
        model.addAttribute("from", fromDate);
        model.addAttribute("to", toDate);
        model.addAttribute("memberId", memberId);
        model.addAttribute("usages", usages);
        model.addAttribute("totalUsedSeconds", usages.stream().mapToLong(CallUsageResponse::usedSeconds).sum());
        model.addAttribute("totalCallCount", usages.stream().mapToLong(CallUsageResponse::callCount).sum());
        return CALL_USAGES_VIEW;
    }

}
