package kr.co.teeq.api.onboarding.application.controller;

import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingAnswersResponse;
import kr.co.teeq.api.onboarding.application.service.OnboardingAnswerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/onboarding")
@RequiredArgsConstructor
public class OnboardingController implements OnboardingControllerDocs {

    private final OnboardingAnswerService onboardingAnswerService;

    @GetMapping("/answers")
    public ResponseEntity<OnboardingAnswersResponse> getAnswers(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        return ResponseEntity.ok(onboardingAnswerService.getAnswers(authenticatedMember.member()));
    }

}
