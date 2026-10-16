package kr.teeq.api.call.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record CallLimitCheckRequest(
    @NotNull(message = "회원 ID를 입력해 주세요.")
    @Schema(description = "통화를 시작하려는 회원 ID")
    UUID memberId
) {

}
