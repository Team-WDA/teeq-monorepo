package kr.teeq.api.auth.application.controller;

import jakarta.validation.Valid;
import kr.teeq.api.auth.application.dto.request.ChangePasswordRequest;
import kr.teeq.api.auth.application.dto.request.SignUpRequest;
import kr.teeq.api.auth.application.dto.response.AuthResponse;
import kr.teeq.api.auth.application.service.AuthService;
import kr.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

// 경로는 members 리소스이지만 가입, 비밀번호 변경, 계정 삭제는 토큰 폐기와 얽혀 있어 auth 도메인이 처리한다
@RestController
@RequestMapping("/api/members")
@RequiredArgsConstructor
public class AccountController implements AccountControllerDocs {

    private final AuthService authService;

    @PostMapping
    public ResponseEntity<AuthResponse> signUp(@Valid @RequestBody SignUpRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.signUp(request));
    }

    @PatchMapping("/me/password")
    public ResponseEntity<AuthResponse> changePassword(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @Valid @RequestBody ChangePasswordRequest request) {
        return ResponseEntity.ok(authService.changePassword(authenticatedMember.member(), request));
    }

    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteAccount(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        authService.deleteAccount(authenticatedMember.member());
        return ResponseEntity.noContent().build();
    }

}
