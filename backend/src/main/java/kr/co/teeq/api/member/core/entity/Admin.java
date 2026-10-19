package kr.co.teeq.api.member.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import kr.co.teeq.api.common.core.entity.BaseEntity;
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

    @Builder
    private Admin(String username, String password, String name) {
        this.username = username;
        this.password = password;
        this.name = name;
    }

}
