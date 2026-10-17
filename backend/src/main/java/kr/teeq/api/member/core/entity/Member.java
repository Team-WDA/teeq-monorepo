package kr.teeq.api.member.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import kr.teeq.api.common.core.entity.BaseEntity;
import kr.teeq.api.member.core.constant.LoginType;
import kr.teeq.api.member.core.constant.Role;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "member")
public class Member extends BaseEntity {

    @Column(nullable = false)
    private String email;

    // 소셜 계정은 비밀번호가 없다
    @Column
    private String password;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LoginType loginType;

    // 소셜 제공자가 부여한 사용자 식별값. 이메일 계정은 null이다
    @Column
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

    // 가입 계정은 항상 USER다. ADMIN 생성은 별도 절차에서 다룬다
    @Builder
    private Member(String email, String password, String nickname, boolean serviceTermsAgreed,
        boolean privacyPolicyAgreed) {
        this.email = email;
        this.password = password;
        this.loginType = LoginType.EMAIL;
        this.nickname = nickname;
        this.role = Role.USER;
        this.serviceTermsAgreed = serviceTermsAgreed;
        this.privacyPolicyAgreed = privacyPolicyAgreed;
    }

    public static Member createSocialMember(LoginType loginType, String socialUserId, String email, String nickname,
        boolean serviceTermsAgreed, boolean privacyPolicyAgreed) {
        Member member = new Member();
        member.email = email;
        member.loginType = loginType;
        member.socialUserId = socialUserId;
        member.nickname = nickname;
        member.role = Role.USER;
        member.serviceTermsAgreed = serviceTermsAgreed;
        member.privacyPolicyAgreed = privacyPolicyAgreed;
        return member;
    }

    public void changeNickname(String nickname) {
        this.nickname = nickname;
    }

    public void changePassword(String encodedPassword) {
        this.password = encodedPassword;
    }

}
