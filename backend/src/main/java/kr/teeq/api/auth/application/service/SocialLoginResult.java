package kr.teeq.api.auth.application.service;

import kr.teeq.api.auth.application.dto.response.AuthResponse;

// created는 컨트롤러가 201(신규 가입)과 200(기존 회원 로그인)을 가르는 데 쓴다
public record SocialLoginResult(AuthResponse response, boolean created) {

}
