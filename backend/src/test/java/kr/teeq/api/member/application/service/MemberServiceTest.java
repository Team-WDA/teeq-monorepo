package kr.teeq.api.member.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.application.dto.request.ChangeNicknameRequest;
import kr.teeq.api.member.application.dto.response.MemberResponse;
import kr.teeq.api.member.core.entity.Member;
import kr.teeq.api.member.core.port.AiCharacterExistencePort;
import kr.teeq.api.member.core.repository.MemberRepository;
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

    private MemberService memberService;

    @BeforeEach
    void setUp() {
        memberService = new MemberService(memberRepository, aiCharacterExistencePort);
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
