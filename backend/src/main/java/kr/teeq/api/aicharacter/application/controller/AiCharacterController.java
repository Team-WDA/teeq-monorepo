package kr.teeq.api.aicharacter.application.controller;

import jakarta.validation.Valid;
import kr.teeq.api.aicharacter.application.dto.request.SubmitAiCharacterRequest;
import kr.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.teeq.api.aicharacter.application.service.AiCharacterService;
import kr.teeq.api.aicharacter.application.service.AiCharacterSubmitResult;
import kr.teeq.api.member.core.principal.AuthenticatedMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
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
    public ResponseEntity<AiCharacterResponse> submit(
        @AuthenticationPrincipal AuthenticatedMember authenticatedMember,
        @Valid @RequestBody SubmitAiCharacterRequest request) {
        AiCharacterSubmitResult result = aiCharacterService.submit(authenticatedMember.member().getId(), request);
        HttpStatus status = result.created() ? HttpStatus.CREATED : HttpStatus.OK;
        return ResponseEntity.status(status).body(result.response());
    }

    @GetMapping("/me")
    public ResponseEntity<AiCharacterResponse> get(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
        return ResponseEntity.ok(aiCharacterService.get(authenticatedMember.member().getId()));
    }

}
