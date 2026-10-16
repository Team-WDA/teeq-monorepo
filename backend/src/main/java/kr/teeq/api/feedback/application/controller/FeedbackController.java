package kr.teeq.api.feedback.application.controller;

import jakarta.validation.Valid;
import kr.teeq.api.feedback.application.dto.request.DetailedFeedbackRequest;
import kr.teeq.api.feedback.application.dto.request.RequiredFeedbackRequest;
import kr.teeq.api.feedback.application.dto.response.FeedbackStatusResponse;
import kr.teeq.api.feedback.application.dto.response.RequiredFeedbackResponse;
import kr.teeq.api.feedback.application.service.CallFeedbackService;
import kr.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/calls/{call-session-id}")
@RequiredArgsConstructor
public class FeedbackController implements FeedbackControllerDocs {

    private final CallFeedbackService callFeedbackService;

    @GetMapping("/feedback-status")
    public ResponseEntity<FeedbackStatusResponse> getFeedbackStatus(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @PathVariable("call-session-id") String callSessionId) {
        return ResponseEntity.ok(
            callFeedbackService.getStatus(authenticatedMember.member().getId(), callSessionId));
    }

    @PostMapping("/required-feedback")
    public ResponseEntity<RequiredFeedbackResponse> submitRequiredFeedback(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @PathVariable("call-session-id") String callSessionId,
        @Valid @RequestBody RequiredFeedbackRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
            callFeedbackService.submitRequired(authenticatedMember.member().getId(), callSessionId, request));
    }

    @PostMapping("/detailed-feedback")
    public ResponseEntity<Void> submitDetailedFeedback(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @PathVariable("call-session-id") String callSessionId,
        @Valid @RequestBody DetailedFeedbackRequest request) {
        callFeedbackService.submitDetailed(authenticatedMember.member().getId(), callSessionId, request);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

}
