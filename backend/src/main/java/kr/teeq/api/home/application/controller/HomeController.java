package kr.teeq.api.home.application.controller;

import kr.teeq.api.home.application.dto.response.HomeResponse;
import kr.teeq.api.home.application.service.HomeService;
import kr.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/home")
@RequiredArgsConstructor
public class HomeController implements HomeControllerDocs {

    private final HomeService homeService;

    @GetMapping
    public ResponseEntity<HomeResponse> getHome(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        return ResponseEntity.ok(homeService.getHome(authenticatedMember.member().getId(),
            authenticatedMember.member().getNickname()));
    }

}
