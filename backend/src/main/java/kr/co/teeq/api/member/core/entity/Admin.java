package kr.co.teeq.api.member.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.member.core.constant.AdminRole;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "admin")
public class Admin extends BaseEntity {

    @Column(nullable = false)
    private String username;

    // 평문이 아니라 BCrypt 해시를 받는다
    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AdminRole role;

    @Builder
    private Admin(String username, String password, String name, AdminRole role) {
        this.username = username;
        this.password = password;
        this.name = name;
        this.role = role;
    }

    public void changeRole(AdminRole role) {
        this.role = role;
    }

    // 평문이 아니라 BCrypt 해시를 받는다
    public void changePassword(String encodedPassword) {
        this.password = encodedPassword;
    }

}
