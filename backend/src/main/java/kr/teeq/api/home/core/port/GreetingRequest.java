package kr.teeq.api.home.core.port;

import java.util.List;
import java.util.UUID;

// speechStyle은 온보딩 말투 선택지 이름이다. home.core가 onboarding.core에 의존하지 않도록 문자열로 넘긴다
public record GreetingRequest(UUID memberId, String nickname, String characterName, int characterNumber,
                              List<String> personalityTags, String speechStyle) {

}
