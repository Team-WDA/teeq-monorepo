package kr.co.teeq.api.call.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import kr.co.teeq.api.call.application.dto.response.CallStartResponse;
import kr.co.teeq.api.call.application.service.CallService;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/calls")
@RequiredArgsConstructor
public class CallController implements CallControllerDocs {

    private final CallService callService;

    @LogMonitoring
    @PostMapping
    public ResponseEntity<CallStartResponse> start(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(callService.start(authenticatedMember.member()));
    }

}
