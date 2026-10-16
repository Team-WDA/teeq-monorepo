package kr.teeq.api.call.application.dto.response;

// 기록 결과와 신규 여부. 컨트롤러가 신규면 201, 중복 수신이면 200으로 응답하는 데 쓴다
public record CallHistoryRecordResult(CallHistoryResponse history, boolean created) {

}
