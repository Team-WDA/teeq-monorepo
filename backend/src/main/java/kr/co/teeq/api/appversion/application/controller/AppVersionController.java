package kr.co.teeq.api.appversion.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import kr.co.teeq.api.appversion.application.dto.response.AppVersionCheckResponse;
import kr.co.teeq.api.appversion.application.service.AppVersionService;
import kr.co.teeq.api.appversion.core.constant.AppPlatform;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/app-versions")
@RequiredArgsConstructor
public class AppVersionController implements AppVersionControllerDocs {

    private final AppVersionService appVersionService;

    @LogMonitoring
    @GetMapping("/check")
    public ResponseEntity<AppVersionCheckResponse> check(@RequestParam AppPlatform platform,
        @RequestParam String appVersion) {
        return ResponseEntity.ok(appVersionService.check(platform, appVersion));
    }

}
