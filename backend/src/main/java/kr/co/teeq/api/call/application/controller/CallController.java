package kr.co.teeq.api.call.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import kr.co.teeq.api.call.application.dto.response.CallHistoryResponse;
import kr.co.teeq.api.call.application.dto.response.CallStartResponse;
import kr.co.teeq.api.call.application.service.CallHistoryService;
import kr.co.teeq.api.call.application.service.CallService;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/calls")
@RequiredArgsConstructor
public class CallController implements CallControllerDocs {

    private final CallService callService;
    private final CallHistoryService callHistoryService;

    @LogMonitoring
    @PostMapping
    public ResponseEntity<CallStartResponse> start(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(callService.start(authenticatedMember.member()));
    }

    @LogMonitoring
    @PostMapping("/{call-session-id}/cancel")
    public ResponseEntity<CallHistoryResponse> cancel(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @PathVariable("call-session-id") String callSessionId) {
        return ResponseEntity.ok(callHistoryService.cancel(authenticatedMember.member(), callSessionId));
    }

}
