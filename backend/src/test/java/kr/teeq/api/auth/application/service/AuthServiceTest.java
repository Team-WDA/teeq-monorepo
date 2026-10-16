package kr.teeq.api.auth.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.auth.application.dto.request.ChangePasswordRequest;
import kr.teeq.api.auth.application.dto.request.LoginRequest;
import kr.teeq.api.auth.application.dto.request.RefreshRequest;
import kr.teeq.api.auth.application.dto.request.SignUpRequest;
import kr.teeq.api.auth.application.dto.response.AuthResponse;
import kr.teeq.api.auth.core.entity.RefreshToken;
import kr.teeq.api.auth.core.port.IssuedRefreshToken;
import kr.teeq.api.auth.core.port.TokenProvider;
import kr.teeq.api.auth.core.repository.RefreshTokenRepository;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.constant.Role;
import kr.teeq.api.member.core.entity.Member;
import kr.teeq.api.member.core.port.AiCharacterExistencePort;
import kr.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    private static final Instant NOW = Instant.parse("2026-10-16T00:00:00Z");
    private static final Instant REFRESH_EXPIRES_AT = NOW.plusSeconds(60L * 60 * 24 * 30);
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    @Mock
    private TokenProvider tokenProvider;

    @Mock
    private AiCharacterExistencePort aiCharacterExistencePort;

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder(4);
    private final Clock clock = Clock.fixed(NOW, ZoneOffset.UTC);

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(memberRepository, refreshTokenRepository, tokenProvider, passwordEncoder, clock,
            aiCharacterExistencePort);
    }

    private Member memberWithPassword(String rawPassword) {
        Member member = Member.builder()
            .email("soyeon@teeq.com")
            .password(passwordEncoder.encode(rawPassword))
            .nickname("소연")
            .serviceTermsAgreed(true)
            .privacyPolicyAgreed(true)
            .build();
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        return member;
    }

    private void stubTokenIssue(String accessToken, String refreshToken) {
        given(tokenProvider.issueAccessToken(MEMBER_ID)).willReturn(accessToken);
        given(tokenProvider.issueRefreshToken(MEMBER_ID))
            .willReturn(new IssuedRefreshToken(refreshToken, REFRESH_EXPIRES_AT));
    }

    private void assertFailsWith(Runnable action, ErrorCode expected) {
        assertThatThrownBy(action::run)
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(expected));
    }

    // ---------- signUp ----------

    @Test
    void signUp_duplicateEmail_throwsDuplicateEmail() {
        given(memberRepository.existsByEmailAndDeletedFalse("soyeon@teeq.com")).willReturn(true);

        assertFailsWith(() -> authService.signUp(
            new SignUpRequest("Soyeon@Teeq.com", "abcd1234", "소연", true, true)), ErrorCode.DUPLICATE_EMAIL);
    }

    @Test
    void signUp_duplicateNicknameIgnoringCase_throwsDuplicateNickname() {
        given(memberRepository.existsByEmailAndDeletedFalse("soyeon@teeq.com")).willReturn(false);
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("Soyeon"))
            .willReturn(Optional.of(memberWithPassword("abcd1234")));

        assertFailsWith(() -> authService.signUp(
            new SignUpRequest("soyeon@teeq.com", "abcd1234", "Soyeon", true, true)), ErrorCode.DUPLICATE_NICKNAME);
    }

    @Test
    void signUp_success_normalizesEmailHashesPasswordAndIssuesTokens() {
        given(memberRepository.existsByEmailAndDeletedFalse("soyeon@teeq.com")).willReturn(false);
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("소연")).willReturn(Optional.empty());
        given(memberRepository.saveAndFlush(any(Member.class))).willAnswer(invocation -> {
            Member saved = invocation.getArgument(0);
            ReflectionTestUtils.setField(saved, "id", MEMBER_ID);
            return saved;
        });
        stubTokenIssue("access-token", "refresh-token");
        given(refreshTokenRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());

        AuthResponse response = authService.signUp(
            new SignUpRequest("Soyeon@Teeq.com", "abcd1234", "소연", true, true));

        ArgumentCaptor<Member> captor = ArgumentCaptor.forClass(Member.class);
        verify(memberRepository).saveAndFlush(captor.capture());
        Member saved = captor.getValue();
        assertThat(saved.getEmail()).isEqualTo("soyeon@teeq.com");
        assertThat(saved.getPassword()).isNotEqualTo("abcd1234");
        assertThat(passwordEncoder.matches("abcd1234", saved.getPassword())).isTrue();
        assertThat(saved.getRole()).isEqualTo(Role.USER);
        verify(refreshTokenRepository).save(any(RefreshToken.class));
        assertThat(response)
            .isEqualTo(new AuthResponse("access-token", "refresh-token", MEMBER_ID, "소연", false));
    }

    @Test
    void signUp_raceOnUniqueIndex_mapsToDuplicateCode() {
        given(memberRepository.existsByEmailAndDeletedFalse("soyeon@teeq.com")).willReturn(false);
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("소연")).willReturn(Optional.empty());
        given(memberRepository.saveAndFlush(any(Member.class))).willThrow(new DataIntegrityViolationException(
            "constraint", new RuntimeException("duplicate key value violates unique constraint \"uq_member_email_active\"")));

        assertFailsWith(() -> authService.signUp(
            new SignUpRequest("soyeon@teeq.com", "abcd1234", "소연", true, true)), ErrorCode.DUPLICATE_EMAIL);
    }

    // ---------- login ----------

    @Test
    void login_unknownEmailAndWrongPassword_failWithSameError() {
        given(memberRepository.findByEmailAndDeletedFalse("nobody@teeq.com")).willReturn(Optional.empty());
        given(memberRepository.findByEmailAndDeletedFalse("soyeon@teeq.com"))
            .willReturn(Optional.of(memberWithPassword("abcd1234")));

        assertFailsWith(() -> authService.login(new LoginRequest("nobody@teeq.com", "abcd1234")),
            ErrorCode.INVALID_CREDENTIALS);
        assertFailsWith(() -> authService.login(new LoginRequest("soyeon@teeq.com", "wrong1234")),
            ErrorCode.INVALID_CREDENTIALS);
    }

    @Test
    void login_withUppercaseEmail_findsSameAccountAndReplacesExistingRefreshToken() {
        Member member = memberWithPassword("abcd1234");
        RefreshToken existing = RefreshToken.builder()
            .memberId(MEMBER_ID).token("old-refresh").expiresAt(NOW).build();
        given(memberRepository.findByEmailAndDeletedFalse("soyeon@teeq.com")).willReturn(Optional.of(member));
        stubTokenIssue("access-token", "new-refresh");
        given(refreshTokenRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.of(existing));

        AuthResponse response = authService.login(new LoginRequest(" SOYEON@teeq.com ", "abcd1234"));

        assertThat(existing.getToken()).isEqualTo("new-refresh");
        assertThat(existing.getExpiresAt()).isEqualTo(REFRESH_EXPIRES_AT);
        verify(refreshTokenRepository, never()).save(any());
        assertThat(response.accessToken()).isEqualTo("access-token");
    }

    @Test
    void login_reportsWhetherTheMemberHasAnAiCharacter() {
        Member member = memberWithPassword("abcd1234");
        given(memberRepository.findByEmailAndDeletedFalse("soyeon@teeq.com")).willReturn(Optional.of(member));
        stubTokenIssue("access-token", "new-refresh");
        given(aiCharacterExistencePort.existsByMemberId(MEMBER_ID)).willReturn(true);

        AuthResponse response = authService.login(new LoginRequest("soyeon@teeq.com", "abcd1234"));

        assertThat(response.hasAiCharacter()).isTrue();
    }

    // ---------- refresh ----------

    @Test
    void refresh_rotatesToken_andRejectsTheOldOneAfterwards() {
        Member member = memberWithPassword("abcd1234");
        RefreshToken stored = RefreshToken.builder()
            .memberId(MEMBER_ID).token("old-refresh").expiresAt(NOW).build();
        given(tokenProvider.parseRefreshToken("old-refresh")).willReturn(MEMBER_ID);
        given(refreshTokenRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.of(stored));
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member));
        stubTokenIssue("new-access", "new-refresh");

        AuthResponse response = authService.refresh(new RefreshRequest("old-refresh"));

        assertThat(stored.getToken()).isEqualTo("new-refresh");
        assertThat(response.refreshToken()).isEqualTo("new-refresh");
        assertFailsWith(() -> authService.refresh(new RefreshRequest("old-refresh")),
            ErrorCode.INVALID_REFRESH_TOKEN);
    }

    @Test
    void refresh_afterLogout_throwsInvalidRefreshToken() {
        given(tokenProvider.parseRefreshToken("some-refresh")).willReturn(MEMBER_ID);
        given(refreshTokenRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());

        assertFailsWith(() -> authService.refresh(new RefreshRequest("some-refresh")),
            ErrorCode.INVALID_REFRESH_TOKEN);
    }

    @Test
    void refresh_forDeletedMember_throwsInvalidRefreshToken() {
        RefreshToken stored = RefreshToken.builder()
            .memberId(MEMBER_ID).token("some-refresh").expiresAt(NOW).build();
        given(tokenProvider.parseRefreshToken("some-refresh")).willReturn(MEMBER_ID);
        given(refreshTokenRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.of(stored));
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.empty());

        assertFailsWith(() -> authService.refresh(new RefreshRequest("some-refresh")),
            ErrorCode.INVALID_REFRESH_TOKEN);
    }

    // ---------- logout / changePassword / deleteAccount ----------

    @Test
    void logout_deletesRefreshToken() {
        authService.logout(memberWithPassword("abcd1234"));

        verify(refreshTokenRepository).deleteByMemberId(MEMBER_ID);
    }

    @Test
    void changePassword_wrongCurrentPassword_throwsAndIssuesNothing() {
        Member member = memberWithPassword("abcd1234");
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member));

        assertFailsWith(() -> authService.changePassword(member,
            new ChangePasswordRequest("wrong1234", "newpass123")), ErrorCode.INVALID_CURRENT_PASSWORD);
        verifyNoInteractions(tokenProvider);
    }

    @Test
    void changePassword_success_updatesHashAndIssuesNewTokens() {
        Member member = memberWithPassword("abcd1234");
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member));
        stubTokenIssue("new-access", "new-refresh");
        given(refreshTokenRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());

        AuthResponse response = authService.changePassword(member,
            new ChangePasswordRequest("abcd1234", "newpass123"));

        assertThat(passwordEncoder.matches("newpass123", member.getPassword())).isTrue();
        assertThat(passwordEncoder.matches("abcd1234", member.getPassword())).isFalse();
        assertThat(response.accessToken()).isEqualTo("new-access");
        verify(refreshTokenRepository).save(any(RefreshToken.class));
    }

    @Test
    void deleteAccount_softDeletesMemberAndRemovesRefreshToken() {
        Member member = memberWithPassword("abcd1234");
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member));

        authService.deleteAccount(member);

        assertThat(member.isDeleted()).isTrue();
        assertThat(member.getDeletedAt()).isEqualTo(NOW);
        verify(refreshTokenRepository).deleteByMemberId(MEMBER_ID);
    }

}
