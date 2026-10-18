package kr.co.teeq.api.member.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.application.dto.request.ChangeNicknameRequest;
import kr.co.teeq.api.member.application.dto.request.SignupCompletionRequest;
import kr.co.teeq.api.member.application.dto.response.MemberResponse;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.entity.ProfileImage;
import kr.co.teeq.api.member.core.port.AiCharacterExistencePort;
import kr.co.teeq.api.member.core.port.ProfileImageStoragePort;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import kr.co.teeq.api.member.core.repository.ProfileImageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class MemberServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final UUID OTHER_MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c");

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private AiCharacterExistencePort aiCharacterExistencePort;

    @Mock
    private ProfileImageRepository profileImageRepository;

    @Mock
    private ProfileImageStoragePort profileImageStoragePort;

    private MemberService memberService;

    @BeforeEach
    void setUp() {
        memberService = new MemberService(memberRepository, aiCharacterExistencePort, profileImageRepository,
            profileImageStoragePort);
    }

    private Member member(UUID id, String nickname) {
        Member member = Member.builder()
            .email("soyeon@teeq.com")
            .password("encoded")
            .nickname(nickname)
            .serviceTermsAgreed(true)
            .privacyPolicyAgreed(true)
            .build();
        ReflectionTestUtils.setField(member, "id", id);
        return member;
    }

    @Test
    void changeNickname_toCaseVariantOfOwnNickname_isAllowed() {
        Member me = member(MEMBER_ID, "soyeon");
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(me));
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("Soyeon")).willReturn(Optional.of(me));
        given(memberRepository.saveAndFlush(any(Member.class))).willAnswer(invocation -> invocation.getArgument(0));

        MemberResponse response = memberService.changeNickname(me, new ChangeNicknameRequest("Soyeon"));

        assertThat(me.getNickname()).isEqualTo("Soyeon");
        assertThat(response.nickname()).isEqualTo("Soyeon");
    }

    @Test
    void changeNickname_toAnotherMembersNickname_throwsDuplicateNickname() {
        Member me = member(MEMBER_ID, "soyeon");
        Member other = member(OTHER_MEMBER_ID, "minjun");
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(me));
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("MinJun")).willReturn(Optional.of(other));

        assertThatThrownBy(() -> memberService.changeNickname(me, new ChangeNicknameRequest("MinJun")))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.DUPLICATE_NICKNAME));
        assertThat(me.getNickname()).isEqualTo("soyeon");
    }

    @Test
    void changeNickname_raceOnUniqueIndex_mapsToDuplicateNickname() {
        Member me = member(MEMBER_ID, "soyeon");
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(me));
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("새닉네임")).willReturn(Optional.empty());
        given(memberRepository.saveAndFlush(any(Member.class))).willThrow(new DataIntegrityViolationException(
            "constraint",
            new RuntimeException("duplicate key value violates unique constraint \"uq_member_nickname_active\"")));

        assertThatThrownBy(() -> memberService.changeNickname(me, new ChangeNicknameRequest("새닉네임")))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.DUPLICATE_NICKNAME));
    }

    private Member incompleteSocialMember() {
        Member member = Member.createSocialMember(LoginType.APPLE, "apple-subject", "soyeon@privaterelay.appleid.com");
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        return member;
    }

    @Test
    void completeSignup_incompleteMember_setsNicknameAndReturnsResponse() {
        Member me = incompleteSocialMember();
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(me));
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("소연")).willReturn(Optional.empty());
        given(memberRepository.saveAndFlush(any(Member.class))).willAnswer(invocation -> invocation.getArgument(0));

        MemberResponse response = memberService.completeSignup(me, new SignupCompletionRequest("소연", true, true));

        assertThat(me.isSignupCompleted()).isTrue();
        assertThat(me.isServiceTermsAgreed()).isTrue();
        assertThat(me.isPrivacyPolicyAgreed()).isTrue();
        assertThat(response.nickname()).isEqualTo("소연");
        assertThat(response.loginType()).isEqualTo(LoginType.APPLE);
    }

    @Test
    void completeSignup_alreadyCompleted_throwsStateConflict() {
        Member me = member(MEMBER_ID, "soyeon");
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(me));

        assertThatThrownBy(() -> memberService.completeSignup(me, new SignupCompletionRequest("새닉네임", true, true)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        assertThat(me.getNickname()).isEqualTo("soyeon");
    }

    @Test
    void completeSignup_duplicateNickname_throwsDuplicateNickname() {
        Member me = incompleteSocialMember();
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(me));
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("MinJun"))
            .willReturn(Optional.of(member(OTHER_MEMBER_ID, "minjun")));

        assertThatThrownBy(() -> memberService.completeSignup(me, new SignupCompletionRequest("MinJun", true, true)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.DUPLICATE_NICKNAME));
        assertThat(me.isSignupCompleted()).isFalse();
    }

    @Test
    void completeSignup_uniqueIndexViolation_throwsDuplicateNickname() {
        Member me = incompleteSocialMember();
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(me));
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("새닉네임")).willReturn(Optional.empty());
        given(memberRepository.saveAndFlush(any(Member.class))).willThrow(new DataIntegrityViolationException(
            "constraint",
            new RuntimeException("duplicate key value violates unique constraint \"uq_member_nickname_active\"")));

        assertThatThrownBy(() -> memberService.completeSignup(me, new SignupCompletionRequest("새닉네임", true, true)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.DUPLICATE_NICKNAME));
    }

    @Test
    void completeSignup_memberDeletedAfterAuthentication_throwsMemberNotFound() {
        Member me = incompleteSocialMember();
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> memberService.completeSignup(me, new SignupCompletionRequest("소연", true, true)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.MEMBER_NOT_FOUND));
    }

    @Test
    void getMe_withActiveProfileImage_returnsImageUrl() {
        Member me = member(MEMBER_ID, "soyeon");
        given(profileImageRepository.findByMemberIdAndDeletedFalse(MEMBER_ID))
            .willReturn(Optional.of(ProfileImage.of(MEMBER_ID, "key.png", "image/png", 10L)));
        given(profileImageStoragePort.urlFor("key.png")).willReturn("/media/profile-images/key.png");

        assertThat(memberService.getMe(me).profileImageUrl()).isEqualTo("/media/profile-images/key.png");
    }

    @Test
    void getMe_withoutProfileImage_returnsNullUrl() {
        Member me = member(MEMBER_ID, "soyeon");
        given(profileImageRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.empty());

        assertThat(memberService.getMe(me).profileImageUrl()).isNull();
    }

    @Test
    void checkNicknameAvailability_reportsFalseWhenTaken() {
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("소연"))
            .willReturn(Optional.of(member(OTHER_MEMBER_ID, "소연")));
        given(memberRepository.findByNicknameIgnoreCaseAndDeletedFalse("민준")).willReturn(Optional.empty());

        assertThat(memberService.checkNicknameAvailability("소연").available()).isFalse();
        assertThat(memberService.checkNicknameAvailability("민준").available()).isTrue();
        verify(memberRepository).findByNicknameIgnoreCaseAndDeletedFalse("민준");
    }

}
