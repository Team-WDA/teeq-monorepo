package kr.co.teeq.api.member.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.application.dto.request.MemberSearchRequest;
import kr.co.teeq.api.member.application.dto.response.MemberPageResponse;
import kr.co.teeq.api.member.application.dto.response.MemberSummaryResponse;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class MemberQueryServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final Instant CREATED_AT = Instant.parse("2026-10-20T01:00:00Z");

    @Mock
    private MemberRepository memberRepository;

    @InjectMocks
    private MemberQueryService memberQueryService;

    private Member member(String nickname) {
        Member member = Member.createSocialMember(LoginType.GOOGLE, "google-uid", "soyeon@teeq.com", nickname);
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        ReflectionTestUtils.setField(member, "createdAt", CREATED_AT);
        return member;
    }

    @Test
    @SuppressWarnings("unchecked")
    void search_convertsPageAndFixesSort() {
        Pageable requested = PageRequest.of(2, 10, Sort.by(Sort.Direction.ASC, "email"));
        Page<Member> page = new PageImpl<>(List.of(member("소연")), PageRequest.of(2, 10), 21);
        given(memberRepository.findAll(any(Specification.class), any(Pageable.class))).willReturn(page);

        MemberPageResponse response =
            memberQueryService.search(new MemberSearchRequest(" soyeon ", LoginType.GOOGLE), requested);

        assertThat(response.page()).isEqualTo(2);
        assertThat(response.size()).isEqualTo(10);
        assertThat(response.totalElements()).isEqualTo(21);
        assertThat(response.members()).hasSize(1);
        assertThat(response.members().get(0).id()).isEqualTo(MEMBER_ID);
        ArgumentCaptor<Pageable> pageableCaptor = ArgumentCaptor.forClass(Pageable.class);
        verify(memberRepository).findAll(any(Specification.class), pageableCaptor.capture());
        Pageable used = pageableCaptor.getValue();
        assertThat(used.getPageNumber()).isEqualTo(2);
        assertThat(used.getPageSize()).isEqualTo(10);
        assertThat(used.getSort())
            .isEqualTo(Sort.by(Sort.Direction.DESC, "createdAt").and(Sort.by(Sort.Direction.DESC, "id")));
    }

    @Test
    void getSummary_existingMember_returnsSummary() {
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member("소연")));

        MemberSummaryResponse response = memberQueryService.getSummary(MEMBER_ID);

        assertThat(response.id()).isEqualTo(MEMBER_ID);
        assertThat(response.nickname()).isEqualTo("소연");
        assertThat(response.email()).isEqualTo("soyeon@teeq.com");
        assertThat(response.createdAt()).isEqualTo(CREATED_AT);
    }

    @Test
    void getSummary_missingMember_throwsMemberNotFound() {
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> memberQueryService.getSummary(MEMBER_ID))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.MEMBER_NOT_FOUND));
    }

}
