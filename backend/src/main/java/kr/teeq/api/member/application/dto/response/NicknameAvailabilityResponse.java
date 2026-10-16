package kr.teeq.api.member.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

public record NicknameAvailabilityResponse(
    @Schema(description = "사용 가능 여부. true면 아직 아무도 쓰지 않는 닉네임이다(대소문자 구분 없이 비교).", example = "true")
    boolean available
) {

}
