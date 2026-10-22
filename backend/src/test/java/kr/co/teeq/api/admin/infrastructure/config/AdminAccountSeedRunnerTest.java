package kr.co.teeq.api.admin.infrastructure.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties;
import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties.BootstrapAccount;
import kr.co.teeq.api.member.core.constant.AdminRole;
import kr.co.teeq.api.member.core.entity.Admin;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class AdminAccountSeedRunnerTest {

    private static final BootstrapAccount OPERATOR = new BootstrapAccount("operator", "raw-password", "운영자");

    @Mock
    private AdminRepository adminRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private AdminAccountSeedRunner runnerOf(BootstrapAccount account) {
        return new AdminAccountSeedRunner(new AdminAccountProperties(account), adminRepository, passwordEncoder);
    }

    @Test
    void run_whenSuperAdminExists_doesNothing() {
        given(adminRepository.countByRoleAndDeletedFalse(AdminRole.SUPER_ADMIN)).willReturn(1L);

        runnerOf(OPERATOR).run(null);

        verify(adminRepository, never()).save(any());
        verifyNoInteractions(passwordEncoder);
    }

    @Test
    void run_whenNoSuperAdminAndConfigured_createsSuperAdmin() {
        given(adminRepository.countByRoleAndDeletedFalse(AdminRole.SUPER_ADMIN)).willReturn(0L);
        given(adminRepository.existsByUsernameAndDeletedFalse("operator")).willReturn(false);
        given(passwordEncoder.encode("raw-password")).willReturn("encoded-hash");

        runnerOf(OPERATOR).run(null);

        ArgumentCaptor<Admin> captor = ArgumentCaptor.forClass(Admin.class);
        verify(adminRepository).save(captor.capture());
        assertThat(captor.getValue().getUsername()).isEqualTo("operator");
        assertThat(captor.getValue().getPassword()).isEqualTo("encoded-hash");
        assertThat(captor.getValue().getName()).isEqualTo("운영자");
        assertThat(captor.getValue().getRole()).isEqualTo(AdminRole.SUPER_ADMIN);
    }

    @Test
    void run_whenNoSuperAdminAndNotConfigured_doesNotSave() {
        given(adminRepository.countByRoleAndDeletedFalse(AdminRole.SUPER_ADMIN)).willReturn(0L);

        runnerOf(null).run(null);

        verify(adminRepository, never()).save(any());
        verifyNoInteractions(passwordEncoder);
    }

    @Test
    void run_whenSameUsernameActive_doesNotSave() {
        given(adminRepository.countByRoleAndDeletedFalse(AdminRole.SUPER_ADMIN)).willReturn(0L);
        given(adminRepository.existsByUsernameAndDeletedFalse("operator")).willReturn(true);

        runnerOf(OPERATOR).run(null);

        verify(adminRepository, never()).save(any());
        verifyNoInteractions(passwordEncoder);
    }

}
