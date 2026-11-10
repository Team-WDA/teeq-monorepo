package kr.co.teeq.api.admin.application.dto.response;

/**
 * 대시보드 AI 서버 상태 카드. today는 KST 오늘 하루, allTime은 전체 누적이다.
 * unavailable이면 AI 서버가 응답하지 못한 것이며 두 행은 0이다.
 */
public record AdminAiSummaryResponse(boolean unavailable, AdminAiMetricsRow today, AdminAiMetricsRow allTime) {

}
