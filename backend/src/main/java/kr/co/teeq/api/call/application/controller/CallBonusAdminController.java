package kr.co.teeq.api.call.application.controller;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.request.CallBonusGrantRequest;
import kr.co.teeq.api.call.application.dto.response.CallBonusResponse;
import kr.co.teeq.api.call.application.service.CallBonusService;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/members/{member-id}/call-bonuses")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class CallBonusAdminController implements CallBonusAdminControllerDocs {

    private final CallBonusService callBonusService;

    @PostMapping
    public ResponseEntity<CallBonusResponse> grant(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @PathVariable("member-id") UUID memberId,
        @Valid @RequestBody CallBonusGrantRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
            callBonusService.grant(authenticatedMember.member(), memberId, request));
    }

    @GetMapping
    public ResponseEntity<List<CallBonusResponse>> getAll(@PathVariable("member-id") UUID memberId) {
        return ResponseEntity.ok(callBonusService.getAll(memberId));
    }

    @DeleteMapping("/{call-bonus-id}")
    public ResponseEntity<Void> cancel(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @PathVariable("member-id") UUID memberId,
        @PathVariable("call-bonus-id") UUID callBonusId) {
        callBonusService.cancel(authenticatedMember.member(), memberId, callBonusId);
        return ResponseEntity.noContent().build();
    }

}
