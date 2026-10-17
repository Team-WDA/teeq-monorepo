package kr.co.teeq.api.home.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.home.application.dto.response.HomeResponse;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;

@Tag(name = "홈", description = "홈 화면 조회")
public interface HomeControllerDocs {

    @Operation(summary = "홈 조회",
        description = """
            캐릭터 이름과 성향 태그, 오늘의 한마디, 오늘 통화 한도, 필수 피드백이 남은 통화를 한 번에 반환한다.
            오늘의 한마디는 하루(KST 0시 기준) 한 번 정해지며, 생성에 실패하면 기본 문구로 대체되므로 오류가 되지 않는다.
            필수 피드백이 남은 통화가 없으면 `pendingFeedback`은 null이다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "조회 성공"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`AI_CHARACTER_NOT_FOUND`: 아직 AI 캐릭터를 만들지 않음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<HomeResponse> getHome(@Parameter(hidden = true) AuthenticatedMember authenticatedMember);

}
