package kr.co.teeq.api.admin.infrastructure.properties;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

// 기동 시 시드할 관리자 계정 목록. password는 시크릿이므로 로그·예외 메시지에 넣지 않는다
@Validated
@ConfigurationProperties(prefix = "admin")
public record AdminAccountProperties(List<@Valid Account> accounts) {

    public AdminAccountProperties {
        accounts = accounts == null ? List.of() : List.copyOf(accounts);
    }

    public record Account(@NotBlank String username, @NotBlank String password, @NotBlank String name) {

    }

}
