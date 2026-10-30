package kr.co.teeq.api.home.core.port;

// AI 서버에 홈 한마디 생성을 요청하는 port.
// 호칭이 포함된 완성 문구와 표정을 돌려주고, 통신 실패·계약 위반은 AI_SERVER_UNAVAILABLE이다.
// mood가 계약 밖의 값이면 WELCOME으로 대체한다
public interface GreetingGenerationPort {

    GreetingResult generate(GreetingRequest request);

}
