package kr.co.teeq.api.aicharacter.application.service;

import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;

// created는 컨트롤러가 201(최초 생성)과 200(재생성)을 가르는 데 쓴다
public record AiCharacterGenerationResult(AiCharacterResponse response, boolean created) {

}
