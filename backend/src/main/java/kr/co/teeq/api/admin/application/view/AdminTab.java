package kr.co.teeq.api.admin.application.view;

/**
 * 관리자 화면 탭 줄의 탭 하나.
 *
 * @param key   활성 탭을 고르는 키
 * @param label 탭에 보이는 이름
 * @param path  탭을 눌렀을 때 이동할 경로(컨텍스트 경로 제외)
 */
public record AdminTab(String key, String label, String path) {
}
