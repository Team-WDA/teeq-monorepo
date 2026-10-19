package kr.co.teeq.api.onboarding.application.controller;

import java.time.LocalDate;
import java.util.UUID;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingSubmissionSearchRequest;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionPageResponse;
import kr.co.teeq.api.onboarding.application.service.OnboardingSubmissionQueryService;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/onboarding-submissions")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class OnboardingSubmissionAdminController implements OnboardingSubmissionAdminControllerDocs {

    private final OnboardingSubmissionQueryService onboardingSubmissionQueryService;

    @GetMapping
    public ResponseEntity<OnboardingSubmissionPageResponse> search(
        @RequestParam(value = "memberId", required = false) UUID memberId,
        @RequestParam(value = "from", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(value = "to", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(value = "optionCode", required = false) OnboardingOption optionCode,
        @RequestParam(value = "active", required = false) Boolean active,
        Pageable pageable) {
        OnboardingSubmissionSearchRequest request =
            new OnboardingSubmissionSearchRequest(memberId, from, to, optionCode, active);
        return ResponseEntity.ok(onboardingSubmissionQueryService.search(request, pageable));
    }

}
