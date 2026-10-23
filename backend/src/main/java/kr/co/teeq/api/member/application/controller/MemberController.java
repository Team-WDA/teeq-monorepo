package kr.co.teeq.api.member.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Pattern;
import kr.co.teeq.api.member.application.dto.request.ChangeNicknameRequest;
import kr.co.teeq.api.member.application.dto.response.MemberResponse;
import kr.co.teeq.api.member.application.dto.response.NicknameAvailabilityResponse;
import kr.co.teeq.api.member.application.service.MemberDeletionService;
import kr.co.teeq.api.member.application.service.MemberService;
import kr.co.teeq.api.member.application.service.ProfileImageService;
import kr.co.teeq.api.member.core.constant.MemberValidation;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/members")
@RequiredArgsConstructor
public class MemberController implements MemberControllerDocs {

    private final MemberService memberService;
    private final ProfileImageService profileImageService;
    private final MemberDeletionService memberDeletionService;

    @LogMonitoring
    @GetMapping("/nickname-availability")
    public ResponseEntity<NicknameAvailabilityResponse> checkNicknameAvailability(
        @RequestParam
        @Pattern(regexp = MemberValidation.NICKNAME_REGEX, message = MemberValidation.NICKNAME_MESSAGE)
        String nickname) {
        return ResponseEntity.ok(memberService.checkNicknameAvailability(nickname));
    }

    @LogMonitoring
    @GetMapping("/me")
    public ResponseEntity<MemberResponse> getMe(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        return ResponseEntity.ok(memberService.getMe(authenticatedMember.member()));
    }

    @LogMonitoring
    @PatchMapping("/me/nickname")
    public ResponseEntity<MemberResponse> changeNickname(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @Valid @RequestBody ChangeNicknameRequest request) {
        return ResponseEntity.ok(memberService.changeNickname(authenticatedMember.member(), request));
    }

    @LogMonitoring
    @PutMapping(value = "/me/profile-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<MemberResponse> replaceProfileImage(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @RequestPart("image") MultipartFile image) {
        profileImageService.replace(authenticatedMember.member(), image);
        return ResponseEntity.ok(memberService.getMe(authenticatedMember.member()));
    }

    @LogMonitoring
    @DeleteMapping("/me/profile-image")
    public ResponseEntity<Void> deleteProfileImage(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        profileImageService.delete(authenticatedMember.member());
        return ResponseEntity.noContent().build();
    }

    @LogMonitoring
    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteMe(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        memberDeletionService.delete(authenticatedMember.member().getId());
        return ResponseEntity.noContent().build();
    }

}
