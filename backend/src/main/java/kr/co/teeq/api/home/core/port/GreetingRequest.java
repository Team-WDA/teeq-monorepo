package kr.co.teeq.api.home.core.port;

import java.time.Instant;
import java.util.UUID;

// lastGreetedAt은 이번 요청으로 갱신하기 이전 값이고, AI가 한 번도 한마디를 만든 적이 없으면 null이다
public record GreetingRequest(UUID memberId, String personaId, String nickname, String characterName,
                              Instant lastGreetedAt) {

}
