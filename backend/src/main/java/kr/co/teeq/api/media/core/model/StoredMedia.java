package kr.co.teeq.api.media.core.model;

// 저장된 미디어 파일의 저장 키와 메타데이터
public record StoredMedia(String key, String contentType, long sizeBytes) {

}
