package kr.co.teeq.api.aicharacter.application.controller;

import jakarta.validation.Valid;
import kr.co.teeq.api.aicharacter.application.dto.request.GenerateAiCharacterRequest;
import kr.co.teeq.api.aicharacter.application.dto.request.RenameAiCharacterRequest;
import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.aicharacter.application.service.AiCharacterService;
import kr.co.teeq.api.aicharacter.application.service.AiCharacterGenerationResult;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ai-characters")
@RequiredArgsConstructor
public class AiCharacterController implements AiCharacterControllerDocs {

    private final AiCharacterService aiCharacterService;

    @PutMapping("/me")
    public ResponseEntity<AiCharacterResponse> generate(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @Valid @RequestBody GenerateAiCharacterRequest request) {
        AiCharacterGenerationResult result = aiCharacterService.generate(authenticatedMember.member().getId(), request);
        HttpStatus status = result.created() ? HttpStatus.CREATED : HttpStatus.OK;
        return ResponseEntity.status(status).body(result.response());
    }

    @PatchMapping("/me/name")
    public ResponseEntity<AiCharacterResponse> rename(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @Valid @RequestBody RenameAiCharacterRequest request) {
        return ResponseEntity.ok(aiCharacterService.rename(authenticatedMember.member().getId(), request));
    }

    @GetMapping("/me")
    public ResponseEntity<AiCharacterResponse> get(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        return ResponseEntity.ok(aiCharacterService.get(authenticatedMember.member().getId()));
    }

}
