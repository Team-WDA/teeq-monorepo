package kr.co.teeq.api.member.core.entity;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class AdminTest {

    @Test
    void builder_setsFields() {
        Admin admin = Admin.builder()
            .username("operator")
            .password("$2a$10$hashedPassword")
            .name("운영자")
            .build();

        assertThat(admin.getUsername()).isEqualTo("operator");
        assertThat(admin.getName()).isEqualTo("운영자");
        assertThat(admin.getPassword()).isEqualTo("$2a$10$hashedPassword");
    }

}
