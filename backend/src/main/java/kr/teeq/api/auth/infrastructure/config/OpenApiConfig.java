package kr.teeq.api.auth.infrastructure.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    private static final String BEARER_SCHEME_NAME = "bearerAuth";

    // 모든 API에 Bearer 인증을 기본 적용한다. 공개 API는 각 ControllerDocs에서 @SecurityRequirements로 해제한다
    @Bean
    public OpenAPI openApi() {
        return new OpenAPI()
            .info(new Info()
                .title("TeeQ API")
                .description("TeeQ 백엔드 API. 인증이 필요한 API는 `Authorization: Bearer <accessToken>` 헤더를 보낸다."))
            .components(new Components().addSecuritySchemes(BEARER_SCHEME_NAME, new SecurityScheme()
                .type(SecurityScheme.Type.HTTP)
                .scheme("bearer")
                .bearerFormat("JWT")))
            .addSecurityItem(new SecurityRequirement().addList(BEARER_SCHEME_NAME));
    }

}
