package kr.co.teeq.api.member.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.constant.Role;
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

    // 소셜 계정은 가입 완료 전까지 null이다
    @Column
    private String nickname;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    private boolean serviceTermsAgreed;

    @Column(nullable = false)
    private boolean privacyPolicyAgreed;

    // 가입 계정은 항상 USER다. 관리자 계정은 Admin 엔티티로 분리되어 있다
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

    // 소셜 계정은 닉네임·약관 동의 없이 만들고, 가입 완료 때 채운다
    public static Member createSocialMember(LoginType loginType, String socialUserId, String email) {
        Member member = new Member();
        member.email = email;
        member.loginType = loginType;
        member.socialUserId = socialUserId;
        member.role = Role.USER;
        return member;
    }

    public void completeSignup(String nickname) {
        this.nickname = nickname;
        this.serviceTermsAgreed = true;
        this.privacyPolicyAgreed = true;
    }

    public boolean isSignupCompleted() {
        return nickname != null;
    }

    public void changeNickname(String nickname) {
        this.nickname = nickname;
    }

    public void changePassword(String encodedPassword) {
        this.password = encodedPassword;
    }

}
