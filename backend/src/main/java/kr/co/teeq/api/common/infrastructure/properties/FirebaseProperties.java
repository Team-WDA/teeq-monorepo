package kr.co.teeq.api.common.infrastructure.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;

// Firebase Admin SDK 설정. 서비스 계정 JSON 파일 위치만 받고, 프로젝트 ID는 JSON에서 읽는다
@ConfigurationProperties(prefix = "firebase")
public record FirebaseProperties(String serviceAccountLocation) {

    public FirebaseProperties {
        if (serviceAccountLocation == null || serviceAccountLocation.isBlank()) {
            throw new IllegalStateException("firebase.service-account-location이 비어 있습니다");
        }
    }

}
