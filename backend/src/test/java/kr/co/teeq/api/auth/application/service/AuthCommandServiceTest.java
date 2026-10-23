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
import kr.co.teeq.api.auth.core.port.VerifiedIdentity;
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
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class AuthCommandServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final AuthResponse RESPONSE =
        new AuthResponse("access", "refresh", MEMBER_ID, "소연", false, LoginType.GOOGLE, null);
    private static final VerifiedIdentity IDENTITY = new VerifiedIdentity(LoginType.GOOGLE, "uid-1", "soyeon@teeq.com");
    private static final String NICKNAME = "소연";

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private AuthTokenIssuer authTokenIssuer;

    @InjectMocks
    private AuthCommandService authCommandService;

    private void stubNoExistingMember() {
        given(memberRepository.findByFirebaseUidAndDeletedFalse("uid-1"))
            .willReturn(Optional.empty());
    }

    private void assertErrorCode(Throwable thrown, ErrorCode expected) {
        assertThat(thrown).isInstanceOfSatisfying(CustomException.class,
            exception -> assertThat(exception.getErrorCode()).isEqualTo(expected));
    }

    @Test
    void login_existingMember_issuesTokens() {
        Member existing = Member.createMember(LoginType.GOOGLE, "uid-1", "soyeon@teeq.com", NICKNAME);
        given(memberRepository.findByFirebaseUidAndDeletedFalse("uid-1"))
            .willReturn(Optional.of(existing));
        given(authTokenIssuer.issue(existing)).willReturn(RESPONSE);

        assertThat(authCommandService.login(IDENTITY)).isEqualTo(RESPONSE);
    }

    @Test
    void login_emailMemberWithEmailIdentity_issuesTokens() {
        Member existing = Member.createMember(LoginType.EMAIL, "uid-1", "soyeon@teeq.com", NICKNAME);
        given(memberRepository.findByFirebaseUidAndDeletedFalse("uid-1")).willReturn(Optional.of(existing));
        given(authTokenIssuer.issue(existing)).willReturn(RESPONSE);

        assertThat(authCommandService.login(new VerifiedIdentity(LoginType.EMAIL, "uid-1", "soyeon@teeq.com")))
            .isEqualTo(RESPONSE);
    }

    @Test
    void login_providerDiffersFromStoredLoginType_throwsTokenInvalidWithoutIssuing() {
        Member existing = Member.createMember(LoginType.APPLE, "uid-1", "soyeon@teeq.com", NICKNAME);
        given(memberRepository.findByFirebaseUidAndDeletedFalse("uid-1")).willReturn(Optional.of(existing));

        assertThatThrownBy(() -> authCommandService.login(IDENTITY))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.AUTH_TOKEN_INVALID));
        verify(authTokenIssuer, never()).issue(any());
    }

    @Test
    void login_unknownUid_throwsSignupRequiredWithoutCreating() {
        stubNoExistingMember();

        assertThatThrownBy(() -> authCommandService.login(IDENTITY))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.AUTH_SIGNUP_REQUIRED));
        verify(memberRepository, never()).saveAndFlush(any());
    }

    @Test
    void signUp_newMember_savesMemberWithAgreedTermsAndIssuesTokens() {
        stubNoExistingMember();
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(NICKNAME)).willReturn(Optional.empty());
        given(memberRepository.saveAndFlush(any(Member.class))).willAnswer(invocation -> invocation.getArgument(0));
        given(authTokenIssuer.issue(any(Member.class))).willReturn(RESPONSE);

        AuthResponse response = authCommandService.signUp(IDENTITY, NICKNAME);

        ArgumentCaptor<Member> captor = ArgumentCaptor.forClass(Member.class);
        verify(memberRepository).saveAndFlush(captor.capture());
        Member saved = captor.getValue();
        assertThat(saved.getNickname()).isEqualTo(NICKNAME);
        assertThat(saved.getLoginType()).isEqualTo(LoginType.GOOGLE);
        assertThat(saved.getFirebaseUid()).isEqualTo("uid-1");
        assertThat(saved.getEmail()).isEqualTo("soyeon@teeq.com");
        assertThat(saved.isServiceTermsAgreed()).isTrue();
        assertThat(saved.isPrivacyPolicyAgreed()).isTrue();
        assertThat(response).isEqualTo(RESPONSE);
    }

    @Test
    void signUp_existingUid_throwsStateConflict() {
        Member existing = Member.createMember(LoginType.GOOGLE, "uid-1", "soyeon@teeq.com", NICKNAME);
        given(memberRepository.findByFirebaseUidAndDeletedFalse("uid-1"))
            .willReturn(Optional.of(existing));

        assertThatThrownBy(() -> authCommandService.signUp(IDENTITY, "다른닉"))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.STATE_CONFLICT));
        verify(memberRepository, never()).saveAndFlush(any());
    }

    @Test
    void signUp_takenNickname_throwsDuplicateNickname() {
        stubNoExistingMember();
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(NICKNAME))
            .willReturn(Optional.of(Member.createMember(LoginType.APPLE, "uid-9", "other@teeq.com", NICKNAME)));

        assertThatThrownBy(() -> authCommandService.signUp(IDENTITY, NICKNAME))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.DUPLICATE_NICKNAME));
        verify(memberRepository, never()).saveAndFlush(any());
    }

    @Test
    void signUp_concurrentSameUid_convertsFirebaseUidIndexViolationToStateConflict() {
        stubNoExistingMember();
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(NICKNAME)).willReturn(Optional.empty());
        given(memberRepository.saveAndFlush(any(Member.class))).willThrow(new DataIntegrityViolationException(
            "violation", new RuntimeException("duplicate key value violates unique constraint \"uq_member_firebase_uid_active\"")));

        assertThatThrownBy(() -> authCommandService.signUp(IDENTITY, NICKNAME))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.STATE_CONFLICT));
    }

    @Test
    void signUp_concurrentSameNickname_convertsNicknameIndexViolationToDuplicateNickname() {
        stubNoExistingMember();
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(NICKNAME)).willReturn(Optional.empty());
        given(memberRepository.saveAndFlush(any(Member.class))).willThrow(new DataIntegrityViolationException(
            "violation", new RuntimeException("duplicate key value violates unique constraint \"uq_member_nickname_active\"")));

        assertThatThrownBy(() -> authCommandService.signUp(IDENTITY, NICKNAME))
            .satisfies(thrown -> assertErrorCode(thrown, ErrorCode.DUPLICATE_NICKNAME));
    }

    @Test
    void signUp_unknownIntegrityViolation_isRethrown() {
        stubNoExistingMember();
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse(NICKNAME)).willReturn(Optional.empty());
        given(memberRepository.saveAndFlush(any(Member.class))).willThrow(new DataIntegrityViolationException(
            "violation", new RuntimeException("null value in column")));

        assertThatThrownBy(() -> authCommandService.signUp(IDENTITY, NICKNAME))
            .isInstanceOf(DataIntegrityViolationException.class);
    }

}
