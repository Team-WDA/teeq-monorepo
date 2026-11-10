package kr.co.teeq.api.admin.application.view;

import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.call.application.service.CallUsageService;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.ui.Model;

/**
 * 통화 사용량 영역(필터 폼, 집계 표)이 읽는 모델 변수를 채운다.
 * 전체 통화 사용량 화면과 회원 허브의 통화 사용량 탭이 같은 fragment를 쓰므로 기간 계산과 변수 이름을 한 곳에 둔다.
 */
@Component
@RequiredArgsConstructor
public class AdminCallUsageModel {

    // 기간을 주지 않았을 때 보여 주는 최근 일수(오늘 포함)
    private static final int DEFAULT_RANGE_DAYS = 7;

    private final CallUsageService callUsageService;
    private final Clock clock;
    private final ZoneId koreaZoneId;

    // memberId가 null이면 전체 회원을 집계한다. basePath는 필터 폼이 조회를 보낼 경로다
    public void populate(Model model, CallUsageUnit unit, LocalDate from, LocalDate to, UUID memberId,
        String basePath) {
        LocalDate toDate = to != null ? to : LocalDate.now(clock.withZone(koreaZoneId));
        LocalDate fromDate = from != null ? from : toDate.minusDays(DEFAULT_RANGE_DAYS - 1);

        List<CallUsageResponse> usages = callUsageService.getUsages(unit, fromDate, toDate, memberId);

        model.addAttribute("unit", unit);
        model.addAttribute("from", fromDate);
        model.addAttribute("to", toDate);
        model.addAttribute("usageBasePath", basePath);
        model.addAttribute("usages", usages);
        model.addAttribute("totalUsedSeconds", usages.stream().mapToLong(CallUsageResponse::usedSeconds).sum());
        model.addAttribute("totalCallCount", usages.stream().mapToLong(CallUsageResponse::callCount).sum());
    }

}
