package kr.co.teeq.api.member.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.time.Instant;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.constant.Role;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "member")
public class Member extends BaseEntity {

    @Column(nullable = false)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LoginType loginType;

    // 소셜 제공자가 부여한 사용자 식별값(Firebase uid)
    @Column(nullable = false)
    private String socialUserId;

    @Column(nullable = false)
    private String nickname;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    private boolean serviceTermsAgreed;

    @Column(nullable = false)
    private boolean privacyPolicyAgreed;

    // AI가 홈 한마디를 마지막으로 정상 생성한 시각. 기본 문구를 쓴 경우는 갱신하지 않는다
    @Column
    private Instant lastGreetedAt;

    // 소셜 로그인 가입은 닉네임과 필수 약관 동의를 받은 뒤에만 회원을 만든다. 가입 계정은 항상 USER다
    public static Member createSocialMember(LoginType loginType, String socialUserId, String email, String nickname) {
        Member member = new Member();
        member.email = email;
        member.loginType = loginType;
        member.socialUserId = socialUserId;
        member.nickname = nickname;
        member.role = Role.USER;
        member.serviceTermsAgreed = true;
        member.privacyPolicyAgreed = true;
        return member;
    }

    public void changeNickname(String nickname) {
        this.nickname = nickname;
    }

    public void markGreeted(Instant greetedAt) {
        this.lastGreetedAt = greetedAt;
    }

}
