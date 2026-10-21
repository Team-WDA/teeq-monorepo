package kr.co.teeq.api.call.core.port;

import java.util.UUID;
import kr.co.teeq.api.call.core.constant.LimitKind;

// AI 서버에 통화 세션 생성을 요청할 때 보내는 값. limitKind는 maxDurationSeconds를 정한 한도 종류다
public record AiCallSessionRequest(UUID memberId, String personaId, String nickname, String characterName,
                                   long maxDurationSeconds, LimitKind limitKind) {

}
