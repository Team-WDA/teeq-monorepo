package kr.teeq.api.aicharacter.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import kr.teeq.api.aicharacter.application.dto.request.SubmitAiCharacterRequest;
import kr.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.teeq.api.common.application.exception.ErrorResponse;
import kr.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;

@Tag(name = "AI 캐릭터", description = "AI 캐릭터 생성·재설정과 내 AI 캐릭터 조회")
public interface AiCharacterControllerDocs {

    @Operation(summary = "AI 캐릭터 생성·재설정",
        description = """
            온보딩 답변 7개와 캐릭터 이름을 한 번에 제출한다. AI 서버가 캐릭터 번호와 성향 태그 3개를 정해 저장한다.
            캐릭터가 없으면 새로 만들어 201, 이미 있으면 같은 캐릭터를 덮어써 200으로 응답한다.
            재설정하면 기존 온보딩 답변도 새 답변으로 교체된다. 통화 기록과 피드백은 그대로 둔다.
            AI 서버 호출에 실패하면 저장하지 않으므로 기존 캐릭터와 답변이 그대로 남는다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "재설정 성공. 갱신된 캐릭터를 반환"),
        @ApiResponse(responseCode = "201", description = "생성 성공. 만들어진 캐릭터를 반환"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 이름이 비었거나 규칙 위반(한글·영문·숫자 2~10자), 답변 목록이 없거나 답변 안에 비어 있는 질문·선택지 코드가 있음(`errorMessage`에 사유). "
                + "`MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아니거나 없는 질문·선택지 코드임. "
                + "`ONBOARDING_ANSWER_INCOMPLETE`: 질문 누락 또는 선택 수 부족. "
                + "`ONBOARDING_ANSWER_DUPLICATED`: 같은 질문 2회 또는 같은 선택지 중복. "
                + "`INVALID_ONBOARDING_OPTION`: 그 질문에 없는 선택지 또는 선택 수 초과",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`STATE_CONFLICT`: 같은 회원의 동시 제출이 충돌함(잠시 후 다시 시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "502",
            description = "`AI_SERVER_UNAVAILABLE`: AI 서버 호출 실패 또는 응답 이상(저장되지 않음, 다시 시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<AiCharacterResponse> submit(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @Valid SubmitAiCharacterRequest request);

    @Operation(summary = "내 AI 캐릭터 조회",
        description = "로그인한 회원의 AI 캐릭터를 반환한다. 캐릭터를 만들기 전이면 404이며, 앱은 온보딩 화면으로 보낸다.")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "조회 성공"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`AI_CHARACTER_NOT_FOUND`: 아직 AI 캐릭터를 만들지 않음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<AiCharacterResponse> get(@Parameter(hidden = true) AuthenticatedMember authenticatedMember);

}
