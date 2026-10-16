package kr.teeq.api.aicharacter.application.service;

import kr.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;

// created는 컨트롤러가 201(최초 생성)과 200(재설정)을 가르는 데 쓴다
public record AiCharacterSubmitResult(AiCharacterResponse response, boolean created) {

}
