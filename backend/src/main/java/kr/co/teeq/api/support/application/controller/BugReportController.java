package kr.co.teeq.api.support.application.controller;

import jakarta.validation.Valid;
import java.util.List;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import kr.co.teeq.api.support.application.dto.request.BugReportCreateRequest;
import kr.co.teeq.api.support.application.dto.response.BugReportCreateResponse;
import kr.co.teeq.api.support.application.service.BugReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/bug-reports")
@RequiredArgsConstructor
public class BugReportController implements BugReportControllerDocs {

    private final BugReportService bugReportService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<BugReportCreateResponse> create(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @RequestPart("request") @Valid BugReportCreateRequest request,
        @RequestPart(value = "images", required = false) List<MultipartFile> images) {
        BugReportCreateResponse response = bugReportService.create(authenticatedMember.member(), request, images);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

}
