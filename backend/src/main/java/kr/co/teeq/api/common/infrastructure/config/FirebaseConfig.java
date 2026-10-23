package kr.co.teeq.api.common.infrastructure.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;
import java.io.IOException;
import java.io.InputStream;
import kr.co.teeq.api.common.infrastructure.properties.FirebaseProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

/**
 * 서비스 계정 파일로 Firebase 앱을 만든다. 파일이 없거나 읽을 수 없으면 기동에 실패한다.
 */
@Configuration
@RequiredArgsConstructor
public class FirebaseConfig {

    private final FirebaseProperties firebaseProperties;
    private final ResourceLoader resourceLoader;

    // 애플리케이션 종료 때 SDK 내부 스레드를 정리하도록 destroyMethod를 지정한다
    @Bean(destroyMethod = "delete")
    public FirebaseApp firebaseApp() {
        Resource serviceAccount = resourceLoader.getResource(firebaseProperties.serviceAccountLocation());
        if (!serviceAccount.exists()) {
            throw new IllegalStateException("Firebase 서비스 계정 파일을 찾을 수 없습니다: "
                + firebaseProperties.serviceAccountLocation());
        }
        try (InputStream inputStream = serviceAccount.getInputStream()) {
            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(inputStream))
                .build();
            return FirebaseApp.initializeApp(options);
        } catch (IOException exception) {
            throw new IllegalStateException("Firebase 서비스 계정 파일을 읽을 수 없습니다", exception);
        }
    }

    @Bean
    public FirebaseAuth firebaseAuth(FirebaseApp firebaseApp) {
        return FirebaseAuth.getInstance(firebaseApp);
    }

}
