package kr.co.teeq.api.member.core.repository;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class MemberSpecificationsTest {

    @Test
    void escapeLikePattern_escapesBackslashPercentAndUnderscore() {
        assertThat(MemberSpecifications.escapeLikePattern("a%b_c\\d")).isEqualTo("a\\%b\\_c\\\\d");
    }

    @Test
    void toLikePattern_trimsLowercasesAndEscapes() {
        assertThat(MemberSpecifications.toLikePattern(" A%b ")).isEqualTo("%a\\%b%");
    }

    @Test
    void escapeLikePattern_plainKeyword_isUnchanged() {
        assertThat(MemberSpecifications.escapeLikePattern("soyeon")).isEqualTo("soyeon");
    }

}
