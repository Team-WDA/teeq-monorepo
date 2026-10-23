package kr.co.teeq.api.member.core.entity;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.constant.Role;
import org.junit.jupiter.api.Test;

class MemberTest {

    @Test
    void createSocialMember_createsMemberWithNicknameAndAgreements() {
        Member member = Member.createSocialMember(LoginType.APPLE, "apple-subject", "soyeon@teeq.com", "소연");

        assertThat(member.getNickname()).isEqualTo("소연");
        assertThat(member.getEmail()).isEqualTo("soyeon@teeq.com");
        assertThat(member.getSocialUserId()).isEqualTo("apple-subject");
        assertThat(member.isServiceTermsAgreed()).isTrue();
        assertThat(member.isPrivacyPolicyAgreed()).isTrue();
        assertThat(member.getLoginType()).isEqualTo(LoginType.APPLE);
        assertThat(member.getRole()).isEqualTo(Role.USER);
    }

    @Test
    void changeNickname_replacesNickname() {
        Member member = Member.createSocialMember(LoginType.GOOGLE, "google-uid", "soyeon@teeq.com", "소연");

        member.changeNickname("민준");

        assertThat(member.getNickname()).isEqualTo("민준");
    }

    @Test
    void markGreeted_recordsLastGreetedAt() {
        Member member = Member.createSocialMember(LoginType.APPLE, "apple-subject", "soyeon@teeq.com", "소연");
        Instant greetedAt = Instant.parse("2026-10-21T01:00:00Z");

        assertThat(member.getLastGreetedAt()).isNull();

        member.markGreeted(greetedAt);

        assertThat(member.getLastGreetedAt()).isEqualTo(greetedAt);
    }

}
