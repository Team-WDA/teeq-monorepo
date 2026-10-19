package kr.co.teeq.api.admin.infrastructure.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.List;
import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties;
import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties.Account;
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

    private static final Account OPERATOR = new Account("operator", "raw-password", "운영자");

    @Mock
    private AdminRepository adminRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private AdminAccountSeedRunner runnerOf(Account... accounts) {
        return new AdminAccountSeedRunner(
            new AdminAccountProperties(List.of(accounts)), adminRepository, passwordEncoder);
    }

    @Test
    void run_createsAdminWhenUsernameAbsent() {
        given(adminRepository.existsByUsernameAndDeletedFalse("operator")).willReturn(false);
        given(passwordEncoder.encode("raw-password")).willReturn("encoded-hash");

        runnerOf(OPERATOR).run(null);

        ArgumentCaptor<Admin> captor = ArgumentCaptor.forClass(Admin.class);
        verify(adminRepository).save(captor.capture());
        assertThat(captor.getValue().getUsername()).isEqualTo("operator");
        assertThat(captor.getValue().getPassword()).isEqualTo("encoded-hash");
        assertThat(captor.getValue().getName()).isEqualTo("운영자");
    }

    @Test
    void run_skipsWhenActiveUsernameExists() {
        given(adminRepository.existsByUsernameAndDeletedFalse("operator")).willReturn(true);

        runnerOf(OPERATOR).run(null);

        verify(adminRepository, never()).save(any());
        verifyNoInteractions(passwordEncoder);
    }

    @Test
    void run_withEmptyAccounts_doesNothing() {
        runnerOf().run(null);

        verifyNoInteractions(adminRepository, passwordEncoder);
    }

    @Test
    void run_withDuplicateUsernameInList_createsOnce() {
        given(adminRepository.existsByUsernameAndDeletedFalse("operator")).willReturn(false, true);
        given(passwordEncoder.encode("raw-password")).willReturn("encoded-hash");

        runnerOf(OPERATOR, OPERATOR).run(null);

        verify(adminRepository, times(1)).save(any(Admin.class));
    }

}
