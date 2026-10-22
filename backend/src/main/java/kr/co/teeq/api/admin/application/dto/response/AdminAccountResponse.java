package kr.co.teeq.api.admin.application.dto.response;

import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.member.core.constant.AdminRole;
import kr.co.teeq.api.member.core.entity.Admin;

public record AdminAccountResponse(UUID id, String username, String name, AdminRole role, Instant createdAt) {

    public static AdminAccountResponse from(Admin admin) {
        return new AdminAccountResponse(
            admin.getId(), admin.getUsername(), admin.getName(), admin.getRole(), admin.getCreatedAt());
    }

}
