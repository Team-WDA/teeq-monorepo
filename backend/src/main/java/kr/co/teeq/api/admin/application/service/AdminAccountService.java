package kr.co.teeq.api.admin.application.service;

import java.time.Clock;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.application.dto.request.AdminAccountCreateRequest;
import kr.co.teeq.api.admin.application.dto.response.AdminAccountResponse;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.AdminRole;
import kr.co.teeq.api.member.core.entity.Admin;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 관리자 계정의 목록, 생성, 권한 변경, 비활성화, 비밀번호 재설정과 본인 비밀번호 변경.
 * 마지막 SUPER_ADMIN 보호는 행위자의 현재 권한과 무관하게 활성 SUPER_ADMIN 수로 판단한다(오래된 세션 대비).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminAccountService {

    // 마이그레이션의 partial unique index 이름과 같아야 한다. 동시 생성으로 인덱스가 먼저 걸린 경우에만 409로 바꾼다
    private static final String USERNAME_ACTIVE_INDEX_NAME = "uq_admin_username_active";

    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;

    @Transactional(readOnly = true)
    public List<AdminAccountResponse> getAll() {
        return adminRepository.findAllByDeletedFalseOrderByCreatedAtAsc().stream()
            .map(AdminAccountResponse::from)
            .toList();
    }

    @Transactional
    public AdminAccountResponse create(UUID actorAdminId, AdminAccountCreateRequest request) {
        if (adminRepository.existsByUsernameAndDeletedFalse(request.username())) {
            throw new CustomException(ErrorCode.DUPLICATE_ADMIN_USERNAME);
        }
        Admin admin = Admin.builder()
            .username(request.username())
            .password(passwordEncoder.encode(request.password()))
            .name(request.name())
            .role(request.role())
            .build();
        try {
            adminRepository.saveAndFlush(admin);
        } catch (DataIntegrityViolationException exception) {
            String message = String.valueOf(exception.getMostSpecificCause().getMessage());
            if (message.contains(USERNAME_ACTIVE_INDEX_NAME)) {
                throw new CustomException(ErrorCode.DUPLICATE_ADMIN_USERNAME, exception);
            }
            throw exception;
        }
        log.info("관리자 계정 생성: actorAdminId={}, targetAdminId={}, role={}",
            actorAdminId, admin.getId(), admin.getRole());
        return AdminAccountResponse.from(admin);
    }

    @Transactional
    public void changeRole(UUID actorAdminId, UUID targetAdminId, AdminRole role) {
        Admin target = findChangeableTarget(actorAdminId, targetAdminId);
        if (target.getRole() == role) {
            return;
        }
        if (target.getRole() == AdminRole.SUPER_ADMIN) {
            verifyNotLastSuperAdmin();
        }
        target.changeRole(role);
        log.info("관리자 권한 변경: actorAdminId={}, targetAdminId={}, role={}", actorAdminId, targetAdminId, role);
    }

    @Transactional
    public void deactivate(UUID actorAdminId, UUID targetAdminId) {
        Admin target = findChangeableTarget(actorAdminId, targetAdminId);
        if (target.getRole() == AdminRole.SUPER_ADMIN) {
            verifyNotLastSuperAdmin();
        }
        target.delete(clock);
        log.info("관리자 계정 비활성화: actorAdminId={}, targetAdminId={}", actorAdminId, targetAdminId);
    }

    @Transactional
    public void resetPassword(UUID actorAdminId, UUID targetAdminId, String newPassword) {
        Admin target = findChangeableTarget(actorAdminId, targetAdminId);
        target.changePassword(passwordEncoder.encode(newPassword));
        log.info("관리자 비밀번호 재설정: actorAdminId={}, targetAdminId={}", actorAdminId, targetAdminId);
    }

    @Transactional
    public void changeOwnPassword(UUID adminId, String currentPassword, String newPassword) {
        Admin admin = findActiveAdmin(adminId);
        if (!passwordEncoder.matches(currentPassword, admin.getPassword())) {
            throw new CustomException(ErrorCode.INVALID_CURRENT_PASSWORD);
        }
        admin.changePassword(passwordEncoder.encode(newPassword));
        log.info("관리자 본인 비밀번호 변경: adminId={}", adminId);
    }

    private Admin findActiveAdmin(UUID adminId) {
        return adminRepository.findByIdAndDeletedFalse(adminId)
            .orElseThrow(() -> new CustomException(ErrorCode.ADMIN_NOT_FOUND));
    }

    // 대상 없음 -> 본인 대상 순서로 검사한다
    private Admin findChangeableTarget(UUID actorAdminId, UUID targetAdminId) {
        Admin target = findActiveAdmin(targetAdminId);
        if (actorAdminId.equals(targetAdminId)) {
            throw new CustomException(ErrorCode.ADMIN_SELF_CHANGE_FORBIDDEN);
        }
        return target;
    }

    private void verifyNotLastSuperAdmin() {
        if (adminRepository.countByRoleAndDeletedFalse(AdminRole.SUPER_ADMIN) <= 1) {
            throw new CustomException(ErrorCode.LAST_SUPER_ADMIN_PROTECTED);
        }
    }

}
