package kr.co.teeq.api.call.application.controller;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.call.application.service.CallUsageService;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/call-usages")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class CallUsageAdminController implements CallUsageAdminControllerDocs {

    private final CallUsageService callUsageService;

    @GetMapping
    public ResponseEntity<List<CallUsageResponse>> getUsages(
        @RequestParam("unit") CallUsageUnit unit,
        @RequestParam("from") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam("to") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(value = "memberId", required = false) UUID memberId) {
        return ResponseEntity.ok(callUsageService.getUsages(unit, from, to, memberId));
    }

}
