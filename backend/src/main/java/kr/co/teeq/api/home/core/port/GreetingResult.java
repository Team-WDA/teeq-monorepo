package kr.co.teeq.api.home.core.port;

import kr.co.teeq.api.home.core.constant.CharacterMood;

// 호칭이 포함된 완성 문구와 그 문구에 맞는 표정
public record GreetingResult(String message, CharacterMood mood) {

}
