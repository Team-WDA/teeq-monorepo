package kr.teeq.api.call.application.controller;

import jakarta.validation.Valid;
import kr.teeq.api.call.application.dto.request.CallUsageReportRequest;
import kr.teeq.api.call.application.dto.response.CallHistoryResponse;
import kr.teeq.api.call.application.service.CallHistoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ai-server/calls")
@RequiredArgsConstructor
public class AiServerCallController implements AiServerCallControllerDocs {

    private final CallHistoryService callHistoryService;

    @PostMapping("/{call-session-id}/usage")
    public ResponseEntity<CallHistoryResponse> reportUsage(
        @PathVariable("call-session-id") String callSessionId,
        @Valid @RequestBody CallUsageReportRequest request) {
        return ResponseEntity.ok(callHistoryService.reportUsage(callSessionId, request));
    }

}
