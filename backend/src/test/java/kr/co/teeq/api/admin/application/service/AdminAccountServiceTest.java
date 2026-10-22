package kr.co.teeq.api.admin.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.admin.application.dto.request.AdminAccountCreateRequest;
import kr.co.teeq.api.admin.application.dto.response.AdminAccountResponse;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.AdminRole;
import kr.co.teeq.api.member.core.entity.Admin;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class AdminAccountServiceTest {

    private static final UUID ACTOR_ID = UUID.fromString("00000000-0000-7000-8000-0000000000a1");
    private static final UUID TARGET_ID = UUID.fromString("00000000-0000-7000-8000-0000000000b2");
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-10-22T00:00:00Z"), ZoneOffset.UTC);

    @Mock
    private AdminRepository adminRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private AdminAccountService service() {
        return new AdminAccountService(adminRepository, passwordEncoder, CLOCK);
    }

    private Admin adminOf(UUID id, String username, AdminRole role) {
        Admin admin = Admin.builder().username(username).password("old-hash").name("이름").role(role).build();
        ReflectionTestUtils.setField(admin, "id", id);
        return admin;
    }

    private void assertErrorCode(Runnable action, ErrorCode expected) {
        assertThatThrownBy(action::run)
            .isInstanceOfSatisfying(CustomException.class, e -> assertThat(e.getErrorCode()).isEqualTo(expected));
    }

    // ---- getAll ----

    @Test
    void getAll_returnsActiveAdminsInRepositoryOrder() {
        Admin first = adminOf(ACTOR_ID, "first", AdminRole.SUPER_ADMIN);
        Admin second = adminOf(TARGET_ID, "second", AdminRole.ADMIN);
        given(adminRepository.findAllByDeletedFalseOrderByCreatedAtAsc()).willReturn(List.of(first, second));

        List<AdminAccountResponse> responses = service().getAll();

        assertThat(responses).extracting(AdminAccountResponse::username).containsExactly("first", "second");
        assertThat(responses).extracting(AdminAccountResponse::role)
            .containsExactly(AdminRole.SUPER_ADMIN, AdminRole.ADMIN);
    }

    // ---- create ----

    private AdminAccountCreateRequest createRequest() {
        return new AdminAccountCreateRequest("new.admin", "Password1!", "새 관리자", AdminRole.ADMIN);
    }

    @Test
    void create_savesEncodedPasswordAndRole() {
        given(adminRepository.existsByUsernameAndDeletedFalse("new.admin")).willReturn(false);
        given(passwordEncoder.encode("Password1!")).willReturn("encoded-hash");
        given(adminRepository.saveAndFlush(any(Admin.class))).willAnswer(invocation -> invocation.getArgument(0));

        AdminAccountResponse response = service().create(ACTOR_ID, createRequest());

        ArgumentCaptor<Admin> captor = ArgumentCaptor.forClass(Admin.class);
        verify(adminRepository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().getUsername()).isEqualTo("new.admin");
        assertThat(captor.getValue().getPassword()).isEqualTo("encoded-hash");
        assertThat(captor.getValue().getName()).isEqualTo("새 관리자");
        assertThat(captor.getValue().getRole()).isEqualTo(AdminRole.ADMIN);
        assertThat(response.username()).isEqualTo("new.admin");
        assertThat(response.toString()).doesNotContain("encoded-hash").doesNotContain("Password1!");
    }

    @Test
    void create_withDuplicateUsername_throwsDuplicateAdminUsername() {
        given(adminRepository.existsByUsernameAndDeletedFalse("new.admin")).willReturn(true);

        assertErrorCode(() -> service().create(ACTOR_ID, createRequest()), ErrorCode.DUPLICATE_ADMIN_USERNAME);
        verify(adminRepository, never()).saveAndFlush(any());
    }

    @Test
    void create_whenActiveUsernameIndexViolated_throwsDuplicateAdminUsername() {
        given(adminRepository.existsByUsernameAndDeletedFalse("new.admin")).willReturn(false);
        given(passwordEncoder.encode("Password1!")).willReturn("encoded-hash");
        given(adminRepository.saveAndFlush(any(Admin.class))).willThrow(new DataIntegrityViolationException(
            "constraint", new RuntimeException("duplicate key value violates unique constraint "
                + "\"uq_admin_username_active\"")));

        assertErrorCode(() -> service().create(ACTOR_ID, createRequest()), ErrorCode.DUPLICATE_ADMIN_USERNAME);
    }

    @Test
    void create_whenOtherIntegrityViolation_propagates() {
        given(adminRepository.existsByUsernameAndDeletedFalse("new.admin")).willReturn(false);
        given(passwordEncoder.encode("Password1!")).willReturn("encoded-hash");
        given(adminRepository.saveAndFlush(any(Admin.class))).willThrow(new DataIntegrityViolationException(
            "constraint", new RuntimeException("null value in column \"name\"")));

        assertThatThrownBy(() -> service().create(ACTOR_ID, createRequest()))
            .isInstanceOf(DataIntegrityViolationException.class);
    }

    // ---- changeRole ----

    @Test
    void changeRole_promotesAdminToSuperAdmin() {
        Admin target = adminOf(TARGET_ID, "target", AdminRole.ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(TARGET_ID)).willReturn(Optional.of(target));

        service().changeRole(ACTOR_ID, TARGET_ID, AdminRole.SUPER_ADMIN);

        assertThat(target.getRole()).isEqualTo(AdminRole.SUPER_ADMIN);
    }

    @Test
    void changeRole_withMissingTarget_throwsAdminNotFound() {
        given(adminRepository.findByIdAndDeletedFalse(TARGET_ID)).willReturn(Optional.empty());

        assertErrorCode(() -> service().changeRole(ACTOR_ID, TARGET_ID, AdminRole.ADMIN), ErrorCode.ADMIN_NOT_FOUND);
    }

    @Test
    void changeRole_onSelf_throwsSelfChangeForbidden() {
        Admin self = adminOf(ACTOR_ID, "self", AdminRole.SUPER_ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(ACTOR_ID)).willReturn(Optional.of(self));

        assertErrorCode(() -> service().changeRole(ACTOR_ID, ACTOR_ID, AdminRole.ADMIN),
            ErrorCode.ADMIN_SELF_CHANGE_FORBIDDEN);
        assertThat(self.getRole()).isEqualTo(AdminRole.SUPER_ADMIN);
    }

    @Test
    void changeRole_demotingLastSuperAdmin_throwsProtectedEvenForOtherActor() {
        Admin target = adminOf(TARGET_ID, "target", AdminRole.SUPER_ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(TARGET_ID)).willReturn(Optional.of(target));
        given(adminRepository.countByRoleAndDeletedFalse(AdminRole.SUPER_ADMIN)).willReturn(1L);

        assertErrorCode(() -> service().changeRole(ACTOR_ID, TARGET_ID, AdminRole.ADMIN),
            ErrorCode.LAST_SUPER_ADMIN_PROTECTED);
        assertThat(target.getRole()).isEqualTo(AdminRole.SUPER_ADMIN);
    }

    @Test
    void changeRole_demotingSuperAdminWhenOthersExist_succeeds() {
        Admin target = adminOf(TARGET_ID, "target", AdminRole.SUPER_ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(TARGET_ID)).willReturn(Optional.of(target));
        given(adminRepository.countByRoleAndDeletedFalse(AdminRole.SUPER_ADMIN)).willReturn(2L);

        service().changeRole(ACTOR_ID, TARGET_ID, AdminRole.ADMIN);

        assertThat(target.getRole()).isEqualTo(AdminRole.ADMIN);
    }

    @Test
    void changeRole_withSameRole_doesNothing() {
        Admin target = adminOf(TARGET_ID, "target", AdminRole.SUPER_ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(TARGET_ID)).willReturn(Optional.of(target));

        service().changeRole(ACTOR_ID, TARGET_ID, AdminRole.SUPER_ADMIN);

        assertThat(target.getRole()).isEqualTo(AdminRole.SUPER_ADMIN);
        verify(adminRepository, never()).countByRoleAndDeletedFalse(any());
    }

    // ---- deactivate ----

    @Test
    void deactivate_marksAdminDeleted() {
        Admin target = adminOf(TARGET_ID, "target", AdminRole.ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(TARGET_ID)).willReturn(Optional.of(target));

        service().deactivate(ACTOR_ID, TARGET_ID);

        assertThat(target.isDeleted()).isTrue();
        assertThat(target.getDeletedAt()).isEqualTo(CLOCK.instant());
        verify(adminRepository, never()).countByRoleAndDeletedFalse(any());
    }

    @Test
    void deactivate_onSelf_throwsSelfChangeForbidden() {
        Admin self = adminOf(ACTOR_ID, "self", AdminRole.SUPER_ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(ACTOR_ID)).willReturn(Optional.of(self));

        assertErrorCode(() -> service().deactivate(ACTOR_ID, ACTOR_ID), ErrorCode.ADMIN_SELF_CHANGE_FORBIDDEN);
        assertThat(self.isDeleted()).isFalse();
    }

    @Test
    void deactivate_lastSuperAdmin_throwsProtected() {
        Admin target = adminOf(TARGET_ID, "target", AdminRole.SUPER_ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(TARGET_ID)).willReturn(Optional.of(target));
        given(adminRepository.countByRoleAndDeletedFalse(AdminRole.SUPER_ADMIN)).willReturn(1L);

        assertErrorCode(() -> service().deactivate(ACTOR_ID, TARGET_ID), ErrorCode.LAST_SUPER_ADMIN_PROTECTED);
        assertThat(target.isDeleted()).isFalse();
    }

    @Test
    void deactivate_withMissingTarget_throwsAdminNotFound() {
        given(adminRepository.findByIdAndDeletedFalse(TARGET_ID)).willReturn(Optional.empty());

        assertErrorCode(() -> service().deactivate(ACTOR_ID, TARGET_ID), ErrorCode.ADMIN_NOT_FOUND);
    }

    // ---- resetPassword ----

    @Test
    void resetPassword_replacesPasswordWithEncodedValue() {
        Admin target = adminOf(TARGET_ID, "target", AdminRole.ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(TARGET_ID)).willReturn(Optional.of(target));
        given(passwordEncoder.encode("NewPassword1!")).willReturn("new-hash");

        service().resetPassword(ACTOR_ID, TARGET_ID, "NewPassword1!");

        assertThat(target.getPassword()).isEqualTo("new-hash");
    }

    @Test
    void resetPassword_onSelf_throwsSelfChangeForbidden() {
        Admin self = adminOf(ACTOR_ID, "self", AdminRole.SUPER_ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(ACTOR_ID)).willReturn(Optional.of(self));

        assertErrorCode(() -> service().resetPassword(ACTOR_ID, ACTOR_ID, "NewPassword1!"),
            ErrorCode.ADMIN_SELF_CHANGE_FORBIDDEN);
        assertThat(self.getPassword()).isEqualTo("old-hash");
    }

    @Test
    void resetPassword_withMissingTarget_throwsAdminNotFound() {
        given(adminRepository.findByIdAndDeletedFalse(TARGET_ID)).willReturn(Optional.empty());

        assertErrorCode(() -> service().resetPassword(ACTOR_ID, TARGET_ID, "NewPassword1!"),
            ErrorCode.ADMIN_NOT_FOUND);
    }

    // ---- changeOwnPassword ----

    @Test
    void changeOwnPassword_withMatchingCurrentPassword_replacesPassword() {
        Admin self = adminOf(ACTOR_ID, "self", AdminRole.ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(ACTOR_ID)).willReturn(Optional.of(self));
        given(passwordEncoder.matches("Current1!", "old-hash")).willReturn(true);
        given(passwordEncoder.encode("NewPassword1!")).willReturn("new-hash");

        service().changeOwnPassword(ACTOR_ID, "Current1!", "NewPassword1!");

        assertThat(self.getPassword()).isEqualTo("new-hash");
    }

    @Test
    void changeOwnPassword_withWrongCurrentPassword_throwsInvalidCurrentPassword() {
        Admin self = adminOf(ACTOR_ID, "self", AdminRole.ADMIN);
        given(adminRepository.findByIdAndDeletedFalse(ACTOR_ID)).willReturn(Optional.of(self));
        given(passwordEncoder.matches("Wrong1!", "old-hash")).willReturn(false);

        assertErrorCode(() -> service().changeOwnPassword(ACTOR_ID, "Wrong1!", "NewPassword1!"),
            ErrorCode.INVALID_CURRENT_PASSWORD);
        assertThat(self.getPassword()).isEqualTo("old-hash");
    }

    @Test
    void changeOwnPassword_withMissingAdmin_throwsAdminNotFound() {
        given(adminRepository.findByIdAndDeletedFalse(ACTOR_ID)).willReturn(Optional.empty());

        assertErrorCode(() -> service().changeOwnPassword(ACTOR_ID, "Current1!", "NewPassword1!"),
            ErrorCode.ADMIN_NOT_FOUND);
    }

}
