package kr.co.teeq.api.admin.application.controller;

import kr.co.teeq.api.common.core.constant.CharacterType;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingSubmissionSearchRequest;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingAnswerGroupResponse;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionPageResponse;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionResponse;
import kr.co.teeq.api.onboarding.application.dto.response.SubmissionCharacterResponse;
import kr.co.teeq.api.onboarding.application.service.OnboardingSubmissionQueryService;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.Pageable;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminOnboardingSubmissionController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminOnboardingSubmissionController.class
})
class AdminOnboardingSubmissionControllerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final UUID SUBMISSION_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c");
    private static final String PATH = "/admin/onboarding-submissions";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private OnboardingSubmissionQueryService onboardingSubmissionQueryService;

    private OnboardingSubmissionResponse submission(boolean active) {
        return new OnboardingSubmissionResponse(SUBMISSION_ID, MEMBER_ID, 2, Instant.parse("2026-10-17T03:00:00Z"),
            active, new SubmissionCharacterResponse(CharacterType.CHARACTER_3, "persona-1", List.of("다정함", "차분함", "유머러스")),
            List.of(new OnboardingAnswerGroupResponse(OnboardingQuestion.RELATIONSHIP,
                List.of(OnboardingOption.RELATIONSHIP_CLOSE_FRIEND))));
    }

    private OnboardingSubmissionPageResponse pageOf(List<OnboardingSubmissionResponse> items, int page, int size,
        long totalElements) {
        return new OnboardingSubmissionPageResponse(items, page, size, totalElements);
    }

    private OnboardingSubmissionSearchRequest noFilters() {
        return new OnboardingSubmissionSearchRequest(null, null, null, null, null);
    }

    @Test
    void search_withFilters_callsQueryService() throws Exception {
        OnboardingSubmissionSearchRequest request = new OnboardingSubmissionSearchRequest(MEMBER_ID,
            LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31), OnboardingOption.VOICE_TONE_LOW_DEEP, true);
        given(onboardingSubmissionQueryService.search(any(), any())).willReturn(pageOf(List.of(), 2, 10, 0));

        mockMvc.perform(get(PATH)
                .with(asAdmin())
                .param("memberId", MEMBER_ID.toString())
                .param("from", "2026-10-01")
                .param("to", "2026-10-31")
                .param("optionCode", "VOICE_TONE_LOW_DEEP")
                .param("active", "true")
                .param("page", "2")
                .param("size", "10"))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/onboarding-submissions"))
            // 필터가 폼에 남는다
            .andExpect(content().string(containsString("value=\"" + MEMBER_ID + "\"")))
            .andExpect(content().string(containsString("value=\"2026-10-01\"")))
            .andExpect(content().string(containsString("value=\"2026-10-31\"")))
            .andExpect(content().string(containsString("<option value=\"VOICE_TONE_LOW_DEEP\" selected")))
            .andExpect(content().string(containsString("<option value=\"true\" selected")));

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(onboardingSubmissionQueryService).search(org.mockito.ArgumentMatchers.eq(request), pageable.capture());
        assertThat(pageable.getValue().getPageNumber()).isEqualTo(2);
        assertThat(pageable.getValue().getPageSize()).isEqualTo(10);
    }

    @Test
    void search_withoutParams_usesNoFiltersAndDefaultPaging() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("제출 이력이 없습니다")));

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(onboardingSubmissionQueryService).search(org.mockito.ArgumentMatchers.eq(noFilters()),
            pageable.capture());
        assertThat(pageable.getValue().getPageNumber()).isZero();
        assertThat(pageable.getValue().getPageSize()).isEqualTo(20);
    }

    @Test
    void search_withBlankFilterFields_treatsThemAsNoFilter() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH)
                .with(asAdmin())
                .param("memberId", "")
                .param("from", "")
                .param("to", "")
                .param("optionCode", "")
                .param("active", ""))
            .andExpect(status().isOk());

        verify(onboardingSubmissionQueryService).search(org.mockito.ArgumentMatchers.eq(noFilters()), any());
    }

    @Test
    void search_activeTriState_mapsToNullTrueFalse() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin()).param("active", "false"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("<option value=\"false\" selected")));
        verify(onboardingSubmissionQueryService).search(
            org.mockito.ArgumentMatchers.eq(new OnboardingSubmissionSearchRequest(null, null, null, null, false)),
            any());

        mockMvc.perform(get(PATH).with(asAdmin()).param("active", "true"))
            .andExpect(status().isOk());
        verify(onboardingSubmissionQueryService).search(
            org.mockito.ArgumentMatchers.eq(new OnboardingSubmissionSearchRequest(null, null, null, null, true)),
            any());

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(content().string(containsString("<option value=\"\" selected")));
    }

    @Test
    void search_rendersSubmissionRowsAndPaging() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any()))
            .willReturn(pageOf(List.of(submission(true)), 1, 1, 3));

        mockMvc.perform(get(PATH)
                .with(asAdmin())
                .param("memberId", MEMBER_ID.toString())
                .param("page", "1")
                .param("size", "1"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString(MEMBER_ID.toString())))
            // KST 표시: 2026-10-17T03:00Z = 12:00
            .andExpect(content().string(containsString("2026-10-17 12:00:00")))
            .andExpect(content().string(containsString("다정함")))
            // 답변은 접어 두는 details 안에 코드로 보인다
            .andExpect(content().string(containsString("<details")))
            .andExpect(content().string(containsString("RELATIONSHIP")))
            .andExpect(content().string(containsString("RELATIONSHIP_CLOSE_FRIEND")))
            // 현재 페이지 / 전체 페이지, 이전/다음이 필터를 유지한다
            .andExpect(content().string(containsString("2 / 3")))
            .andExpect(content().string(containsString("href=\"/admin/onboarding-submissions?memberId=" + MEMBER_ID
                + "&amp;page=0&amp;size=1\"")))
            .andExpect(content().string(containsString("href=\"/admin/onboarding-submissions?memberId=" + MEMBER_ID
                + "&amp;page=2&amp;size=1\"")));
    }

    @Test
    void search_onFirstAndLastPage_hidesUnavailableLinks() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any()))
            .willReturn(pageOf(List.of(submission(true)), 0, 1, 1));

        mockMvc.perform(get(PATH).with(asAdmin()).param("size", "1"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("1 / 1")))
            .andExpect(content().string(not(containsString("page=1"))))
            .andExpect(content().string(not(containsString("page=-1"))));
    }

    @Test
    void search_withInactiveSubmission_showsInactiveBadge() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any()))
            .willReturn(pageOf(List.of(submission(false)), 0, 20, 1));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("비활성")));
    }

    @Test
    void search_withHugePage_clampsInsteadOfFailing() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 100, 0));

        // 50000000 * 100은 int 범위를 넘는다(기본 크기 20이면 넘지 않으므로 최대 크기로 확인한다)
        mockMvc.perform(get(PATH).with(asAdmin()).param("page", "50000000").param("size", "100"))
            .andExpect(status().isOk());

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(onboardingSubmissionQueryService).search(any(), pageable.capture());
        assertThat(pageable.getValue().getOffset()).isLessThanOrEqualTo(Integer.MAX_VALUE);
        assertThat(pageable.getValue().getPageSize()).isEqualTo(100);
        assertThat(pageable.getValue().getPageNumber()).isEqualTo(Integer.MAX_VALUE / 100);
    }

    @Test
    void search_withMaximumPageNumber_clampsInsteadOfFailing() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 100, 0));

        mockMvc.perform(get(PATH).with(asAdmin()).param("page", String.valueOf(Integer.MAX_VALUE)).param("size", "100"))
            .andExpect(status().isOk());

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(onboardingSubmissionQueryService).search(any(), pageable.capture());
        assertThat(pageable.getValue().getOffset()).isLessThanOrEqualTo(Integer.MAX_VALUE);
    }

    @Test
    void search_withNegativePageOrZeroSize_fallsBackToDefaults() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin()).param("page", "-5").param("size", "0"))
            .andExpect(status().isOk());

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(onboardingSubmissionQueryService).search(any(), pageable.capture());
        assertThat(pageable.getValue().getPageNumber()).isZero();
        assertThat(pageable.getValue().getPageSize()).isEqualTo(20);
    }

    @Test
    void search_withOversizedSize_capsToMaximumPageSize() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 100, 0));

        mockMvc.perform(get(PATH).with(asAdmin()).param("size", "100000"))
            .andExpect(status().isOk());

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(onboardingSubmissionQueryService).search(any(), pageable.capture());
        assertThat(pageable.getValue().getPageSize()).isEqualTo(100);
    }

    @Test
    void search_withInvalidOptionCode_showsErrorMessage() throws Exception {
        mockMvc.perform(get(PATH).with(asAdmin()).param("optionCode", "NOT_AN_OPTION"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.INVALID_REQUEST.message())));

        verify(onboardingSubmissionQueryService, never()).search(any(), any());
    }

    @Test
    void search_withMalformedMemberIdDateOrActive_showsErrorMessage() throws Exception {
        mockMvc.perform(get(PATH).with(asAdmin()).param("memberId", "abc"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));
        mockMvc.perform(get(PATH).with(asAdmin()).param("from", "2026-13-45"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));
        mockMvc.perform(get(PATH).with(asAdmin()).param("active", "maybe"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));

        verify(onboardingSubmissionQueryService, never()).search(any(), any());
    }

    @Test
    void search_withFromAfterTo_showsErrorMessage() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any()))
            .willThrow(new CustomException(ErrorCode.INVALID_REQUEST));

        mockMvc.perform(get(PATH).with(asAdmin()).param("from", "2026-10-05").param("to", "2026-10-01"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.INVALID_REQUEST.message())));
    }

    @Test
    void memberIdCell_linksToCallBonusScreen() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any()))
            .willReturn(pageOf(List.of(submission(true)), 0, 20, 1));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("href=\"/admin/call-bonuses?memberId=" + MEMBER_ID + "\"")));
    }

    @Test
    void search_withoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get(PATH))
            .andExpect(status().is3xxRedirection())
            .andExpect(header().string("Location", containsString("/admin/login")));
    }

}
