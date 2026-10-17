package kr.co.teeq.api.auth.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.auth.application.dto.response.AuthResponse;
import kr.co.teeq.api.auth.core.port.SocialIdentity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class SocialLoginCommandServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final AuthResponse RESPONSE =
        new AuthResponse("access", "refresh", MEMBER_ID, null, false, LoginType.APPLE, null);

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private AuthTokenIssuer authTokenIssuer;

    @InjectMocks
    private SocialLoginCommandService socialLoginCommandService;

    private SocialIdentity identity(String email) {
        return new SocialIdentity(LoginType.APPLE, "apple-subject", email);
    }

    private void stubNoExistingMember() {
        given(memberRepository.findByLoginTypeAndSocialUserIdAndDeletedFalse(LoginType.APPLE, "apple-subject"))
            .willReturn(Optional.empty());
    }

    @Test
    void loginOrSignUp_existingMember_issuesTokensWithoutCreating() {
        Member existing = Member.createSocialMember(LoginType.APPLE, "apple-subject", "soyeon@teeq.com");
        given(memberRepository.findByLoginTypeAndSocialUserIdAndDeletedFalse(LoginType.APPLE, "apple-subject"))
            .willReturn(Optional.of(existing));
        given(authTokenIssuer.issue(existing)).willReturn(RESPONSE);

        SocialLoginResult result = socialLoginCommandService.loginOrSignUp(identity("soyeon@teeq.com"));

        assertThat(result.created()).isFalse();
        assertThat(result.response()).isEqualTo(RESPONSE);
        verify(memberRepository, never()).saveAndFlush(any());
    }

    @Test
    void loginOrSignUp_existingMemberWithoutEmail_succeeds() {
        Member existing = Member.createSocialMember(LoginType.APPLE, "apple-subject", "soyeon@teeq.com");
        given(memberRepository.findByLoginTypeAndSocialUserIdAndDeletedFalse(LoginType.APPLE, "apple-subject"))
            .willReturn(Optional.of(existing));
        given(authTokenIssuer.issue(existing)).willReturn(RESPONSE);

        SocialLoginResult result = socialLoginCommandService.loginOrSignUp(identity(null));

        assertThat(result.created()).isFalse();
        verify(memberRepository, never()).saveAndFlush(any());
    }

    @Test
    void loginOrSignUp_newMember_savesIncompleteMemberAndIssuesTokens() {
        stubNoExistingMember();
        given(memberRepository.existsByEmailAndDeletedFalse("soyeon@teeq.com")).willReturn(false);
        given(memberRepository.saveAndFlush(any(Member.class))).willAnswer(invocation -> invocation.getArgument(0));
        given(authTokenIssuer.issue(any(Member.class))).willReturn(RESPONSE);

        SocialLoginResult result = socialLoginCommandService.loginOrSignUp(identity(" Soyeon@Teeq.com "));

        ArgumentCaptor<Member> captor = ArgumentCaptor.forClass(Member.class);
        verify(memberRepository).saveAndFlush(captor.capture());
        Member saved = captor.getValue();
        assertThat(saved.getNickname()).isNull();
        assertThat(saved.isServiceTermsAgreed()).isFalse();
        assertThat(saved.isPrivacyPolicyAgreed()).isFalse();
        assertThat(saved.getLoginType()).isEqualTo(LoginType.APPLE);
        assertThat(saved.getSocialUserId()).isEqualTo("apple-subject");
        assertThat(saved.getEmail()).isEqualTo("soyeon@teeq.com");
        assertThat(saved.getPassword()).isNull();
        assertThat(result.created()).isTrue();
        assertThat(result.response()).isEqualTo(RESPONSE);
    }

    @Test
    void loginOrSignUp_newMemberWithoutEmail_throwsTokenInvalid() {
        stubNoExistingMember();

        assertThatThrownBy(() -> socialLoginCommandService.loginOrSignUp(identity(null)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.SOCIAL_TOKEN_INVALID));
        verify(memberRepository, never()).saveAndFlush(any());
    }

    @Test
    void loginOrSignUp_newMemberWithExistingEmail_throwsDuplicateEmail() {
        stubNoExistingMember();
        given(memberRepository.existsByEmailAndDeletedFalse("soyeon@teeq.com")).willReturn(true);

        assertThatThrownBy(() -> socialLoginCommandService.loginOrSignUp(identity("soyeon@teeq.com")))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.DUPLICATE_EMAIL));
        verify(memberRepository, never()).saveAndFlush(any());
    }

}
