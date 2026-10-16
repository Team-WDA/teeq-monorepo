package kr.teeq.api.call.application.controller;

import jakarta.validation.Valid;
import kr.teeq.api.call.application.dto.request.CallHistoryRecordRequest;
import kr.teeq.api.call.application.dto.request.CallLimitCheckRequest;
import kr.teeq.api.call.application.dto.response.CallHistoryRecordResult;
import kr.teeq.api.call.application.dto.response.CallHistoryResponse;
import kr.teeq.api.call.application.dto.response.CallLimitCheckResponse;
import kr.teeq.api.call.application.service.CallHistoryService;
import kr.teeq.api.call.application.service.CallLimitService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/internal")
@RequiredArgsConstructor
public class CallInternalController implements CallInternalControllerDocs {

    private final CallLimitService callLimitService;
    private final CallHistoryService callHistoryService;

    @PostMapping("/call-limit-checks")
    public ResponseEntity<CallLimitCheckResponse> checkCallLimit(@Valid @RequestBody CallLimitCheckRequest request) {
        return ResponseEntity.ok(new CallLimitCheckResponse(callLimitService.checkStartable(request.memberId())));
    }

    @PostMapping("/call-histories")
    public ResponseEntity<CallHistoryResponse> recordCallHistory(@Valid @RequestBody CallHistoryRecordRequest request) {
        CallHistoryRecordResult result = callHistoryService.record(request);
        HttpStatus status = result.created() ? HttpStatus.CREATED : HttpStatus.OK;
        return ResponseEntity.status(status).body(result.history());
    }

}
