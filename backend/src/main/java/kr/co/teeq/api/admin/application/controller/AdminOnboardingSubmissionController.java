package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import java.time.LocalDate;
import java.util.UUID;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingSubmissionSearchRequest;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionPageResponse;
import kr.co.teeq.api.onboarding.application.service.OnboardingSubmissionQueryService;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * 온보딩 응답 이력 화면. 필터는 GET 쿼리스트링에 남기며, 형식이 틀린 값은 오류 화면(400)으로 보인다.
 * 정렬은 서비스가 최신순으로 고정하므로 정렬 파라미터를 받지 않는다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/onboarding-submissions")
public class AdminOnboardingSubmissionController {

    private static final String ONBOARDING_SUBMISSIONS_PATH = "/admin/onboarding-submissions";
    private static final String ONBOARDING_SUBMISSIONS_VIEW = "admin/onboarding-submissions";

    private final OnboardingSubmissionQueryService onboardingSubmissionQueryService;

    @LogMonitoring
    @GetMapping
    public String search(
        @RequestParam(required = false) UUID memberId,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(required = false) OnboardingOption optionCode,
        @RequestParam(required = false) Boolean active,
        Pageable pageable,
        Model model) {
        OnboardingSubmissionSearchRequest request =
            new OnboardingSubmissionSearchRequest(memberId, from, to, optionCode, active);
        OnboardingSubmissionPageResponse result =
            onboardingSubmissionQueryService.search(request, clampPage(pageable));

        long totalPages = (result.totalElements() + result.size() - 1) / result.size();
        model.addAttribute("memberId", memberId);
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
            model.addAttribute("previousPageUrl", pageUrl(request, result.page() - 1, result.size()));
        }
        if (result.page() + 1 < totalPages) {
            model.addAttribute("nextPageUrl", pageUrl(request, result.page() + 1, result.size()));
        }
        return ONBOARDING_SUBMISSIONS_VIEW;
    }

    // page * size가 int 범위를 넘으면 조회 오프셋이 넘쳐 500이 되므로, 넘치지 않는 마지막 페이지로 줄인다
    private Pageable clampPage(Pageable pageable) {
        int size = pageable.getPageSize();
        return PageRequest.of(Math.min(pageable.getPageNumber(), Integer.MAX_VALUE / size), size);
    }

    // 이전/다음 링크: 값이 있는 필터만 그대로 싣는다
    private String pageUrl(OnboardingSubmissionSearchRequest request, int page, int size) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromPath(ONBOARDING_SUBMISSIONS_PATH);
        if (request.memberId() != null) {
            builder.queryParam("memberId", request.memberId());
        }
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
        return builder.queryParam("page", page).queryParam("size", size).build().encode().toUriString();
    }

}
