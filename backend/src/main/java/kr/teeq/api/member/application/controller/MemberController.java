package kr.teeq.api.member.application.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Pattern;
import kr.teeq.api.member.application.dto.request.ChangeNicknameRequest;
import kr.teeq.api.member.application.dto.response.MemberResponse;
import kr.teeq.api.member.application.dto.response.NicknameAvailabilityResponse;
import kr.teeq.api.member.application.service.MemberService;
import kr.teeq.api.member.core.constant.MemberValidation;
import kr.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/members")
@RequiredArgsConstructor
public class MemberController {

    private final MemberService memberService;

    @GetMapping("/nickname-availability")
    public ResponseEntity<NicknameAvailabilityResponse> checkNicknameAvailability(
        @RequestParam
        @Pattern(regexp = MemberValidation.NICKNAME_REGEX, message = MemberValidation.NICKNAME_MESSAGE)
        String nickname) {
        return ResponseEntity.ok(memberService.checkNicknameAvailability(nickname));
    }

    @GetMapping("/me")
    public ResponseEntity<MemberResponse> getMe(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        return ResponseEntity.ok(memberService.getMe(authenticatedMember.member()));
    }

    @PatchMapping("/me/nickname")
    public ResponseEntity<MemberResponse> changeNickname(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @Valid @RequestBody ChangeNicknameRequest request) {
        return ResponseEntity.ok(memberService.changeNickname(authenticatedMember.member(), request));
    }

}
