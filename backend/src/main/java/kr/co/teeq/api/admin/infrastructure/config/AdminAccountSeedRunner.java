package kr.co.teeq.api.admin.infrastructure.config;

import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties;
import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties.BootstrapAccount;
import kr.co.teeq.api.member.core.constant.AdminRole;
import kr.co.teeq.api.member.core.entity.Admin;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

// 활성 SUPER_ADMIN이 한 명도 없을 때만 설정의 부트스트랩 계정을 SUPER_ADMIN으로 만든다. 기존 계정은 바꾸지 않는다
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminAccountSeedRunner implements ApplicationRunner {

    private final AdminAccountProperties adminAccountProperties;
    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(ApplicationArguments arguments) {
        if (adminRepository.countByRoleAndDeletedFalse(AdminRole.SUPER_ADMIN) > 0) {
            return;
        }
        BootstrapAccount account = adminAccountProperties.bootstrapAccount();
        if (account == null) {
            log.error("활성 SUPER_ADMIN이 없고 admin.bootstrap-account 설정도 없어 관리자 계정을 만들지 못했습니다.");
            return;
        }
        if (adminRepository.existsByUsernameAndDeletedFalse(account.username())) {
            log.error("admin.bootstrap-account와 같은 username의 활성 계정이 이미 있어 만들지 않았습니다: username={}",
                account.username());
            return;
        }
        adminRepository.save(Admin.builder()
            .username(account.username())
            .password(passwordEncoder.encode(account.password()))
            .name(account.name())
            .role(AdminRole.SUPER_ADMIN)
            .build());
        log.info("부트스트랩 SUPER_ADMIN 계정 생성: username={}", account.username());
    }

}
