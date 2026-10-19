package kr.co.teeq.api.admin.infrastructure.config;

import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties;
import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties.Account;
import kr.co.teeq.api.member.core.entity.Admin;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

// 기동 시 설정의 관리자 계정을 만든다. 활성 계정이 이미 있으면 아무것도 바꾸지 않는다
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminAccountSeedRunner implements ApplicationRunner {

    private final AdminAccountProperties adminAccountProperties;
    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(ApplicationArguments arguments) {
        for (Account account : adminAccountProperties.accounts()) {
            seed(account);
        }
    }

    private void seed(Account account) {
        if (adminRepository.existsByUsernameAndDeletedFalse(account.username())) {
            return;
        }
        adminRepository.save(Admin.builder()
            .username(account.username())
            .password(passwordEncoder.encode(account.password()))
            .name(account.name())
            .build());
        log.info("관리자 계정 생성: username={}", account.username());
    }

}
