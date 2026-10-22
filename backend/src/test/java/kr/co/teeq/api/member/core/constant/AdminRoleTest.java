package kr.co.teeq.api.member.core.constant;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class AdminRoleTest {

    @Test
    void authority_prefixesRole() {
        assertThat(AdminRole.SUPER_ADMIN.authority()).isEqualTo("ROLE_SUPER_ADMIN");
        assertThat(AdminRole.ADMIN.authority()).isEqualTo("ROLE_ADMIN");
    }

    @Test
    void values_areSuperAdminThenAdmin() {
        assertThat(AdminRole.values()).containsExactly(AdminRole.SUPER_ADMIN, AdminRole.ADMIN);
    }

}
