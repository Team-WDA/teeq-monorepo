package kr.co.teeq.api.call.application.controller;

import kr.co.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.co.teeq.api.call.application.service.CallLimitService;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/call-limits")
@RequiredArgsConstructor
public class CallLimitController implements CallLimitControllerDocs {

    private final CallLimitService callLimitService;

    @GetMapping("/today")
    public ResponseEntity<CallLimitStatusResponse> getTodayStatus(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        return ResponseEntity.ok(callLimitService.getTodayStatus(authenticatedMember.member().getId()));
    }

}
