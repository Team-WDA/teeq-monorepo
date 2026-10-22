package kr.co.teeq.api.admin.infrastructure.properties;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

// 최초 SUPER_ADMIN 1명을 만들기 위한 선택적 부트스트랩 설정. password는 시크릿이므로 로그·예외 메시지에 넣지 않는다
@Validated
@ConfigurationProperties(prefix = "admin")
public record AdminAccountProperties(@Valid BootstrapAccount bootstrapAccount) {

    public record BootstrapAccount(@NotBlank String username, @NotBlank String password, @NotBlank String name) {

        @Override
        public String toString() {
            return "BootstrapAccount[username=" + username + ", password=****, name=" + name + "]";
        }

    }

}
