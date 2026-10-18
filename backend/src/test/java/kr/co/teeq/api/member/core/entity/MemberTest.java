package kr.co.teeq.api.member.core.entity;

import static org.assertj.core.api.Assertions.assertThat;

import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.constant.Role;
import org.junit.jupiter.api.Test;

class MemberTest {

    @Test
    void createSocialMember_createsIncompleteMember() {
        Member member = Member.createSocialMember(LoginType.APPLE, "apple-subject", "soyeon@teeq.com");

        assertThat(member.getNickname()).isNull();
        assertThat(member.isServiceTermsAgreed()).isFalse();
        assertThat(member.isPrivacyPolicyAgreed()).isFalse();
        assertThat(member.isSignupCompleted()).isFalse();
        assertThat(member.getLoginType()).isEqualTo(LoginType.APPLE);
        assertThat(member.getRole()).isEqualTo(Role.USER);
    }

    @Test
    void completeSignup_setsNicknameAndAgreements() {
        Member member = Member.createSocialMember(LoginType.APPLE, "apple-subject", "soyeon@teeq.com");

        member.completeSignup("소연");

        assertThat(member.getNickname()).isEqualTo("소연");
        assertThat(member.isSignupCompleted()).isTrue();
        assertThat(member.isServiceTermsAgreed()).isTrue();
        assertThat(member.isPrivacyPolicyAgreed()).isTrue();
    }

    @Test
    void builder_emailMember_isSignupCompleted() {
        Member member = Member.builder()
            .email("soyeon@teeq.com")
            .password("encoded")
            .nickname("소연")
            .serviceTermsAgreed(true)
            .privacyPolicyAgreed(true)
            .build();

        assertThat(member.isSignupCompleted()).isTrue();
    }

}
