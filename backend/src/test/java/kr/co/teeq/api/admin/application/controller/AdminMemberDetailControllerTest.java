package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.ADMIN_ID;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asSuperAdmin;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.matchesPattern;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.stringContainsInOrder;
import static org.mockito.ArgumentCaptor.forClass;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.application.view.AdminCallUsageModel;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.call.application.dto.request.CallBonusGrantRequest;
import kr.co.teeq.api.call.application.dto.request.CallHistorySearchRequest;
import kr.co.teeq.api.call.application.dto.response.CallBonusResponse;
import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;
import kr.co.teeq.api.call.application.dto.response.CallHistoryPageResponse;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.call.application.dto.response.MemberCallSummaryResponse;
import kr.co.teeq.api.call.application.dto.response.MemberTodayCallLimitResponse;
import kr.co.teeq.api.call.application.service.CallBonusService;
import kr.co.teeq.api.call.application.service.CallHistoryQueryService;
import kr.co.teeq.api.call.application.service.CallLimitService;
import kr.co.teeq.api.call.application.service.CallUsageService;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.call.core.constant.EndReason;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.feedback.application.dto.request.FeedbackSearchRequest;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackListItemResponse;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackPageResponse;
import kr.co.teeq.api.feedback.application.service.FeedbackQueryService;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;
import kr.co.teeq.api.member.application.dto.response.MemberSummaryResponse;
import kr.co.teeq.api.member.application.service.MemberQueryService;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingSubmissionSearchRequest;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingAnswerGroupResponse;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionPageResponse;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionResponse;
import kr.co.teeq.api.onboarding.application.dto.response.SubmissionCharacterResponse;
import kr.co.teeq.api.onboarding.application.service.OnboardingSubmissionQueryService;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import kr.co.teeq.api.support.application.dto.response.BugReportPageResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportSummaryResponse;
import kr.co.teeq.api.support.application.service.BugReportQueryService;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminMemberDetailController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminMemberDetailController.class,
    AdminCallUsageModel.class
})
class AdminMemberDetailControllerTest {

    private static final String PATH = "/admin/members/{memberId}";
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final String MEMBER_PATH = "/admin/members/" + MEMBER_ID;
    private static final UUID ACTIVE_BONUS_ID = UUID.fromString("0199aaaa-0000-7000-8000-000000000001");
    private static final UUID CANCELED_BONUS_ID = UUID.fromString("0199aaaa-0000-7000-8000-000000000002");
    private static final UUID CANCELING_ADMIN_ID = UUID.fromString("0199bbbb-0000-7000-8000-000000000003");
    private static final String BONUS_PATH = MEMBER_PATH + "/call-bonuses";
    private static final String DELETE_FORM_ACTION = "action=\"" + MEMBER_PATH + "/delete\"";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private MemberQueryService memberQueryService;

    @MockitoBean
    private CallHistoryQueryService callHistoryQueryService;

    @MockitoBean
    private CallUsageService callUsageService;

    @MockitoBean
    private CallBonusService callBonusService;

    @MockitoBean
    private CallLimitService callLimitService;

    @MockitoBean
    private OnboardingSubmissionQueryService onboardingSubmissionQueryService;

    @MockitoBean
    private BugReportQueryService bugReportQueryService;

    @MockitoBean
    private FeedbackQueryService feedbackQueryService;

    @Test
    void overview_rendersMemberIdOnlyInOverview() throws Exception {
        givenMember();

        String html = mockMvc.perform(get(PATH, MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/member-overview"))
            .andExpect(content().string(containsString("foo@example.com")))
            .andExpect(content().string(containsString("테스터")))
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            // 회원 ID는 기본 정보의 dd 하나에만 보인다
            .andExpect(content().string(matchesPattern(
                "(?s).*<dd class=\"mono\">" + MEMBER_ID + "</dd>.*")))
            .andReturn().getResponse().getContentAsString();

        // 링크 경로를 제외하면 회원 ID 텍스트는 기본 정보의 dd 한 곳에만 남는다
        String textOnly = html.replace(MEMBER_PATH, "");
        assertThat(textOnly.split(MEMBER_ID.toString(), -1).length - 1).isEqualTo(1);
    }

    @Test
    void overview_rendersTabNavigationWithSevenTabs() throws Exception {
        givenMember();

        mockMvc.perform(get(PATH, MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("href=\"" + MEMBER_PATH + "\"")))
            .andExpect(content().string(containsString("href=\"" + MEMBER_PATH + "/calls\"")))
            .andExpect(content().string(containsString("href=\"" + MEMBER_PATH + "/call-usages\"")))
            .andExpect(content().string(containsString("href=\"" + MEMBER_PATH + "/call-bonuses\"")))
            .andExpect(content().string(containsString("href=\"" + MEMBER_PATH + "/onboarding-submissions\"")))
            .andExpect(content().string(containsString("href=\"" + MEMBER_PATH + "/bug-reports\"")))
            .andExpect(content().string(containsString("href=\"" + MEMBER_PATH + "/feedbacks\"")))
            .andExpect(content().string(matchesPattern(
                "(?s).*class=\"tab tab-active\" href=\"" + MEMBER_PATH + "\" aria-current=\"page\".*")))
            // 위치 경로
            .andExpect(content().string(containsString("href=\"/admin/members\"")))
            .andExpect(content().string(containsString("회원 관리")));
    }

    @Test
    void overview_rendersRecentFiveCallsWithAllCallsLink() throws Exception {
        givenMember();
        given(callHistoryQueryService.getMemberSummary(MEMBER_ID))
            .willReturn(new MemberCallSummaryResponse(12, 3_400, Instant.parse("2026-10-20T03:00:00Z"), 4));
        given(callHistoryQueryService.search(any(), any())).willReturn(new CallHistoryPageResponse(List.of(
            new CallHistoryItemResponse("session-0001", MEMBER_ID, "테스터", "foo@example.com",
                Instant.parse("2026-10-20T03:00:00Z"), 125, CallStatus.ENDED, EndReason.USER_HANGUP, null)),
            0, 5, 12));

        mockMvc.perform(get(PATH, MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("3,400")))
            .andExpect(content().string(containsString("href=\"/admin/calls/session-0001\"")))
            .andExpect(content().string(containsString("전체 보기")))
            .andExpect(content().string(containsString("href=\"" + MEMBER_PATH + "/calls\"")));

        ArgumentCaptor<CallHistorySearchRequest> request = forClass(CallHistorySearchRequest.class);
        ArgumentCaptor<Pageable> pageable = forClass(Pageable.class);
        verify(callHistoryQueryService).search(request.capture(), pageable.capture());
        assertThat(request.getValue()).isEqualTo(new CallHistorySearchRequest(MEMBER_ID, null, null, null, null, false));
        assertThat(pageable.getValue()).isEqualTo(PageRequest.of(0, 5));
    }

    @Test
    void overview_memberWithoutCalls_rendersEmptyMessage() throws Exception {
        givenMember();

        mockMvc.perform(get(PATH, MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("통화 기록이 없습니다.")))
            .andExpect(content().string(matchesPattern(
                "(?s).*call-summary-last-started\">-</p>.*")));
    }

    @Test
    void overview_unknownMember_returnsNotFoundErrorPage() throws Exception {
        given(memberQueryService.getSummary(MEMBER_ID)).willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(get(PATH, MEMBER_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.MEMBER_NOT_FOUND.message())));
    }

    @Test
    void calls_unknownMember_returnsNotFoundErrorPage() throws Exception {
        given(memberQueryService.getSummary(MEMBER_ID)).willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(get(PATH + "/calls", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void callUsages_unknownMember_returnsNotFoundErrorPage() throws Exception {
        given(memberQueryService.getSummary(MEMBER_ID)).willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(get(PATH + "/call-usages", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void callUsages_withUnitAndRange_roundTripsFiltersAndRendersTotals() throws Exception {
        givenMember();
        LocalDate from = LocalDate.of(2026, 8, 1);
        LocalDate to = LocalDate.of(2026, 10, 31);
        given(callUsageService.getUsages(CallUsageUnit.MONTH, from, to, MEMBER_ID)).willReturn(List.of(
            new CallUsageResponse(LocalDate.of(2026, 8, 1), 1_200, 3),
            new CallUsageResponse(LocalDate.of(2026, 9, 1), 3_400, 5)));

        mockMvc.perform(get(PATH + "/call-usages", MEMBER_ID).with(asAdmin())
                .param("unit", "MONTH")
                .param("from", "2026-08-01")
                .param("to", "2026-10-31"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"2026-08-01\"")))
            .andExpect(content().string(containsString("value=\"2026-10-31\"")))
            .andExpect(content().string(matchesPattern("(?s).*<option value=\"MONTH\" selected.*")))
            .andExpect(content().string(stringContainsInOrder(
                "call-usage-total-row", "합계", "<th class=\"numeric-cell\">4,600</th>",
                "<th class=\"numeric-cell\">8</th>")));

        verify(callUsageService).getUsages(CallUsageUnit.MONTH, from, to, MEMBER_ID);
    }

    @Test
    void overview_withMalformedMemberId_showsErrorScreen() throws Exception {
        mockMvc.perform(get(PATH, "abc").with(asAdmin()))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void overview_showsDeleteFormOnlyForSuperAdmin() throws Exception {
        givenMember();

        mockMvc.perform(get(PATH, MEMBER_ID).with(asSuperAdmin()))
            .andExpect(status().isOk())
            // 전용 dialog 대신 공통 확인 모달 계약을 쓴다
            .andExpect(content().string(not(containsString("member-delete-dialog"))))
            .andExpect(content().string(containsString("data-confirm-title=\"회원을 삭제할까요?\"")))
            .andExpect(content().string(containsString("data-confirm-subject=\"테스터\"")))
            .andExpect(content().string(containsString("data-confirm-message=\"삭제하면 이 회원의 통화 기록")))
            .andExpect(content().string(containsString(DELETE_FORM_ACTION)));
        mockMvc.perform(get(PATH, MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("회원을 삭제할까요?"))))
            .andExpect(content().string(not(containsString("/delete"))));
    }

    @Test
    void calls_filtersByMemberAndKeepsPageLinksInTab() throws Exception {
        givenMember();
        given(callHistoryQueryService.search(any(), any())).willReturn(new CallHistoryPageResponse(List.of(
            new CallHistoryItemResponse("session-0001", MEMBER_ID, "테스터", "foo@example.com",
                Instant.parse("2026-10-20T03:00:00Z"), 125, CallStatus.ENDED, EndReason.USER_HANGUP, null)),
            0, 20, 45));

        mockMvc.perform(get(PATH + "/calls", MEMBER_ID).with(asAdmin())
                .param("from", "2026-10-01")
                .param("to", "2026-10-31")
                .param("status", "ENDED")
                .param("abnormalOnly", "true")
                .param("memberId", "0198a1b2-0000-7000-8000-000000000000"))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/member-calls"))
            .andExpect(content().string(containsString("action=\"" + MEMBER_PATH + "/calls\"")))
            .andExpect(content().string(containsString("href=\"" + MEMBER_PATH
                + "/calls?from=2026-10-01&amp;to=2026-10-31&amp;status=ENDED&amp;abnormalOnly=true&amp;page=1\"")))
            .andExpect(content().string(containsString("href=\"/admin/calls/session-0001\"")));

        ArgumentCaptor<CallHistorySearchRequest> request = forClass(CallHistorySearchRequest.class);
        ArgumentCaptor<Pageable> pageable = forClass(Pageable.class);
        verify(callHistoryQueryService).search(request.capture(), pageable.capture());
        // 쿼리의 memberId는 무시하고 경로 회원만 쓴다
        assertThat(request.getValue()).isEqualTo(new CallHistorySearchRequest(MEMBER_ID, null,
            LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31), CallStatus.ENDED, true));
        assertThat(pageable.getValue()).isEqualTo(PageRequest.of(0, 20));
    }

    @Test
    void calls_rendersHubHeaderWithCallsTabActive() throws Exception {
        givenMember();

        mockMvc.perform(get(PATH + "/calls", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(matchesPattern(
                "(?s).*class=\"tab tab-active\" href=\"" + MEMBER_PATH + "/calls\" aria-current=\"page\".*")))
            .andExpect(content().string(containsString("통화 기록이 없습니다.")));
    }

    @Test
    void callUsages_defaultsToLastSevenDaysForMember() throws Exception {
        givenMember();
        LocalDate to = LocalDate.of(2026, 10, 20);
        given(callUsageService.getUsages(CallUsageUnit.DAY, to.minusDays(6), to, MEMBER_ID))
            .willReturn(List.of(new CallUsageResponse(to, 3_400, 5)));

        mockMvc.perform(get(PATH + "/call-usages", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/member-call-usages"))
            .andExpect(content().string(containsString("3,400")))
            .andExpect(content().string(containsString("action=\"" + MEMBER_PATH + "/call-usages\"")))
            .andExpect(content().string(matchesPattern(
                "(?s).*class=\"tab tab-active\" href=\"" + MEMBER_PATH + "/call-usages\" aria-current=\"page\".*")));

        verify(callUsageService).getUsages(CallUsageUnit.DAY, to.minusDays(6), to, MEMBER_ID);
    }

    @Test
    void callUsages_rendersNoMemberIdInput() throws Exception {
        givenMember();

        mockMvc.perform(get(PATH + "/call-usages", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("name=\"memberId\""))));
    }

    @Test
    void callBonuses_rendersFourTodayTilesWithoutHighlight() throws Exception {
        givenMemberWithBonuses();

        mockMvc.perform(get(PATH + "/call-bonuses", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/member-call-bonuses"))
            .andExpect(content().string(containsString("하루 기본 한도")))
            .andExpect(content().string(containsString("오늘 유효 보너스")))
            .andExpect(content().string(containsString("오늘 사용")))
            .andExpect(content().string(containsString("남은 통화 시간")))
            .andExpect(content().string(containsString("1,800초")))
            .andExpect(content().string(containsString("1,700초")))
            .andExpect(content().string(not(containsString("dashboard-kpi-card-highlight"))))
            .andExpect(content().string(matchesPattern(
                "(?s).*class=\"tab tab-active\" href=\"" + BONUS_PATH + "\" aria-current=\"page\".*")));
    }

    @Test
    void callBonuses_rendersActiveAndCanceledRowsWithFormActions() throws Exception {
        givenMemberWithBonuses();

        mockMvc.perform(get(PATH + "/call-bonuses", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("서비스 장애 보상")))
            .andExpect(content().string(containsString("중복 부여")))
            .andExpect(content().string(containsString("action=\"" + BONUS_PATH + "/grant\"")))
            .andExpect(content().string(containsString("action=\"" + BONUS_PATH + "/" + ACTIVE_BONUS_ID
                + "/cancel\"")))
            // 취소된 행은 취소 폼 없이 취소됨 표시와 취소한 관리자를 보인다
            .andExpect(content().string(not(containsString(BONUS_PATH + "/" + CANCELED_BONUS_ID + "/cancel"))))
            .andExpect(content().string(containsString("취소됨")))
            .andExpect(content().string(containsString(CANCELING_ADMIN_ID.toString())));
    }

    @Test
    void callBonuses_rendersConfirmAttributesForGrantAndCancel() throws Exception {
        givenMemberWithBonuses();

        mockMvc.perform(get(PATH + "/call-bonuses", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("data-confirm-title=\"추가 통화 시간을 부여할까요?\"")))
            .andExpect(content().string(containsString("data-confirm-subject=\"테스터\"")))
            .andExpect(content().string(containsString("data-confirm-label=\"추가 시간(초)\"")))
            .andExpect(content().string(containsString("data-confirm-label=\"유효 날짜\"")))
            .andExpect(content().string(containsString("data-confirm-label=\"사유\"")))
            .andExpect(content().string(containsString(
                "data-confirm-title=\"부여를 취소할까요?\" data-confirm-subject=\"테스터\"")))
            .andExpect(content().string(containsString(
                "data-confirm-message=\"유효 날짜 2026-10-21, 추가 시간 600초\"")))
            // ADMIN 화면에도 SUPER_ADMIN 전용 삭제 버튼은 없다
            .andExpect(content().string(not(containsString("회원을 삭제할까요?"))));
    }

    @Test
    void callBonuses_unknownMember_returnsNotFoundErrorPage() throws Exception {
        given(memberQueryService.getSummary(MEMBER_ID)).willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(get(PATH + "/call-bonuses", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void grant_valid_redirectsToBonusTab() throws Exception {
        mockMvc.perform(post(PATH + "/call-bonuses/grant", MEMBER_ID)
                .with(asAdmin()).with(csrf())
                .param("seconds", "600").param("bonusDate", "2026-10-21").param("reason", "서비스 장애 보상"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", BONUS_PATH));

        ArgumentCaptor<CallBonusGrantRequest> request = forClass(CallBonusGrantRequest.class);
        verify(callBonusService).grant(eq(ADMIN_ID), eq(MEMBER_ID), request.capture());
        assertThat(request.getValue())
            .isEqualTo(new CallBonusGrantRequest(600, LocalDate.of(2026, 10, 21), "서비스 장애 보상"));
    }

    @Test
    void grant_withoutBonusDate_passesNullDate() throws Exception {
        mockMvc.perform(post(PATH + "/call-bonuses/grant", MEMBER_ID)
                .with(asAdmin()).with(csrf())
                .param("seconds", "60").param("bonusDate", "").param("reason", "테스트"))
            .andExpect(status().isFound());

        verify(callBonusService).grant(ADMIN_ID, MEMBER_ID, new CallBonusGrantRequest(60, null, "테스트"));
    }

    @Test
    void grant_invalidInput_rerendersTabWith422AndKeepsInput() throws Exception {
        givenMemberWithBonuses();

        for (String invalidSeconds : List.of("0", "3601")) {
            mockMvc.perform(post(PATH + "/call-bonuses/grant", MEMBER_ID)
                    .with(asAdmin()).with(csrf())
                    .param("seconds", invalidSeconds).param("reason", "사유"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(view().name("admin/member-call-bonuses"))
                .andExpect(content().string(containsString("추가 통화 시간은")))
                .andExpect(content().string(containsString("value=\"" + invalidSeconds + "\"")))
                .andExpect(content().string(containsString("value=\"사유\"")))
                .andExpect(content().string(containsString("foo@example.com")))
                .andExpect(content().string(containsString("하루 기본 한도")));
        }

        verify(callBonusService, never()).grant(any(), any(), any());
    }

    @Test
    void grant_blankReasonAndMissingSeconds_showsBothMessages() throws Exception {
        givenMemberWithBonuses();

        mockMvc.perform(post(PATH + "/call-bonuses/grant", MEMBER_ID)
                .with(asAdmin()).with(csrf())
                .param("reason", "  "))
            .andExpect(status().isUnprocessableContent())
            .andExpect(content().string(containsString("추가 통화 시간을 입력해 주세요.")))
            .andExpect(content().string(containsString("부여 사유를 입력해 주세요.")));
    }

    @Test
    void grant_whenServiceRejects_showsErrorScreen() throws Exception {
        given(callBonusService.grant(eq(ADMIN_ID), eq(MEMBER_ID), any()))
            .willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(post(PATH + "/call-bonuses/grant", MEMBER_ID)
                .with(asAdmin()).with(csrf())
                .param("seconds", "60").param("reason", "사유"))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void cancel_redirectsToBonusTab() throws Exception {
        mockMvc.perform(post(PATH + "/call-bonuses/{callBonusId}/cancel", MEMBER_ID, ACTIVE_BONUS_ID)
                .with(asAdmin()).with(csrf()))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", BONUS_PATH));

        verify(callBonusService).cancel(ADMIN_ID, MEMBER_ID, ACTIVE_BONUS_ID);
    }

    @Test
    void cancel_whenBonusNotFound_showsErrorScreen() throws Exception {
        doThrow(new CustomException(ErrorCode.CALL_BONUS_NOT_FOUND))
            .when(callBonusService).cancel(ADMIN_ID, MEMBER_ID, ACTIVE_BONUS_ID);

        mockMvc.perform(post(PATH + "/call-bonuses/{callBonusId}/cancel", MEMBER_ID, ACTIVE_BONUS_ID)
                .with(asAdmin()).with(csrf()))
            .andExpect(status().isNotFound())
            .andExpect(content().string(containsString(ErrorCode.CALL_BONUS_NOT_FOUND.message())));
    }

    @Test
    void grantAndCancel_withWrongCsrfToken_areForbidden() throws Exception {
        mockMvc.perform(post(PATH + "/call-bonuses/grant", MEMBER_ID)
                .with(asAdmin()).with(csrf().useInvalidToken())
                .param("seconds", "60").param("reason", "사유"))
            .andExpect(status().isForbidden());
        mockMvc.perform(post(PATH + "/call-bonuses/{callBonusId}/cancel", MEMBER_ID, ACTIVE_BONUS_ID)
                .with(asAdmin()).with(csrf().useInvalidToken()))
            .andExpect(status().isForbidden());

        verify(callBonusService, never()).grant(any(), any(), any());
        verify(callBonusService, never()).cancel(any(), any(), any());
    }

    @Test
    void cancel_withMalformedCallBonusId_showsErrorScreen() throws Exception {
        mockMvc.perform(post(PATH + "/call-bonuses/{callBonusId}/cancel", MEMBER_ID, "abc")
                .with(asAdmin()).with(csrf()))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));

        verify(callBonusService, never()).cancel(any(), any(), any());
    }

    private void givenMemberWithBonuses() {
        givenMember();
        given(callBonusService.getAll(MEMBER_ID)).willReturn(List.of(activeBonus(), canceledBonus()));
        given(callLimitService.getTodayLimit(MEMBER_ID))
            .willReturn(new MemberTodayCallLimitResponse(1_800, 600, 700, 1_700));
    }

    private CallBonusResponse activeBonus() {
        return new CallBonusResponse(ACTIVE_BONUS_ID, MEMBER_ID, LocalDate.of(2026, 10, 21), 600, "서비스 장애 보상",
            ADMIN_ID, false, null, null, Instant.parse("2026-10-20T01:00:00Z"));
    }

    private CallBonusResponse canceledBonus() {
        return new CallBonusResponse(CANCELED_BONUS_ID, MEMBER_ID, LocalDate.of(2026, 10, 20), 300, "중복 부여",
            ADMIN_ID, true, Instant.parse("2026-10-20T03:00:00Z"), CANCELING_ADMIN_ID,
            Instant.parse("2026-10-19T01:00:00Z"));
    }

    private OnboardingSubmissionResponse onboardingSubmission() {
        return new OnboardingSubmissionResponse(UUID.fromString("0199cccc-0000-7000-8000-000000000001"), MEMBER_ID, 2,
            Instant.parse("2026-10-17T03:00:00Z"), true,
            new SubmissionCharacterResponse(CharacterType.CHARACTER_3, "persona-1", List.of("다정함")),
            List.of(new OnboardingAnswerGroupResponse(OnboardingQuestion.RELATIONSHIP,
                List.of(OnboardingOption.RELATIONSHIP_CLOSE_FRIEND))));
    }

    private BugReportSummaryResponse bugReportSummary() {
        return new BugReportSummaryResponse(UUID.fromString("0199dddd-0000-7000-8000-000000000001"), "앱이 멈춰요",
            BugReportStatus.RECEIVED, BugReportSource.USER, MEMBER_ID, "foo@example.com", false,
            Instant.parse("2026-10-22T03:00:00Z"));
    }

    private FeedbackListItemResponse feedbackItem() {
        return new FeedbackListItemResponse("session-0001", MEMBER_ID, "테스터", "foo@example.com",
            Instant.parse("2026-10-20T03:00:00Z"), 5, RevisitIntention.NO, false);
    }

    @Test
    void memberOnboardingSubmissions_pinsMemberId() throws Exception {
        givenMember();
        UUID otherMemberId = UUID.fromString("0198ffff-0000-7000-8000-000000000009");
        given(onboardingSubmissionQueryService.search(any(), any()))
            .willReturn(new OnboardingSubmissionPageResponse(List.of(onboardingSubmission()), 0, 20, 1));

        mockMvc.perform(get(PATH + "/onboarding-submissions", MEMBER_ID).with(asAdmin())
                .param("memberId", otherMemberId.toString()).param("active", "true"))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/member-onboarding-submissions"))
            .andExpect(content().string(containsString("RELATIONSHIP_CLOSE_FRIEND")))
            .andExpect(content().string(not(containsString("회원 ID"))))
            .andExpect(content().string(matchesPattern(
                "(?s).*class=\"tab tab-active\" href=\"" + MEMBER_PATH
                    + "/onboarding-submissions\" aria-current=\"page\".*")));

        ArgumentCaptor<OnboardingSubmissionSearchRequest> request =
            forClass(OnboardingSubmissionSearchRequest.class);
        verify(onboardingSubmissionQueryService).search(request.capture(), any());
        assertThat(request.getValue())
            .isEqualTo(new OnboardingSubmissionSearchRequest(MEMBER_ID, null, null, null, true));
    }

    @Test
    void memberOnboardingSubmissions_pageLinksStayInTab() throws Exception {
        givenMember();
        given(onboardingSubmissionQueryService.search(any(), any()))
            .willReturn(new OnboardingSubmissionPageResponse(List.of(onboardingSubmission()), 1, 20, 41));

        mockMvc.perform(get(PATH + "/onboarding-submissions", MEMBER_ID).with(asAdmin())
                .param("page", "1").param("active", "true"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString(
                "href=\"" + MEMBER_PATH + "/onboarding-submissions?active=true&amp;page=0\"")))
            .andExpect(content().string(containsString(
                "href=\"" + MEMBER_PATH + "/onboarding-submissions?active=true&amp;page=2\"")));
    }

    @Test
    void memberOnboardingSubmissions_unknownMember_returnsNotFoundErrorPage() throws Exception {
        given(memberQueryService.getSummary(MEMBER_ID)).willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(get(PATH + "/onboarding-submissions", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void memberBugReports_filtersByMemberAndHidesMemberColumn() throws Exception {
        givenMember();
        given(bugReportQueryService.search(any(), any(), any(), any()))
            .willReturn(new BugReportPageResponse(List.of(bugReportSummary()), 0, 20, 1));

        mockMvc.perform(get(PATH + "/bug-reports", MEMBER_ID).with(asAdmin()).param("status", "RECEIVED"))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/member-bug-reports"))
            .andExpect(content().string(containsString("앱이 멈춰요")))
            .andExpect(content().string(not(containsString("<th>회원</th>"))))
            .andExpect(content().string(matchesPattern(
                "(?s).*class=\"tab tab-active\" href=\"" + MEMBER_PATH
                    + "/bug-reports\" aria-current=\"page\".*")));

        verify(bugReportQueryService).search(eq(BugReportStatus.RECEIVED), eq(null), eq(MEMBER_ID), any());
    }

    @Test
    void memberBugReports_pageLinksStayInTab() throws Exception {
        givenMember();
        given(bugReportQueryService.search(any(), any(), any(), any()))
            .willReturn(new BugReportPageResponse(List.of(bugReportSummary()), 1, 20, 41));

        mockMvc.perform(get(PATH + "/bug-reports", MEMBER_ID).with(asAdmin())
                .param("status", "RECEIVED").param("source", "USER").param("page", "1"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString(
                "href=\"" + MEMBER_PATH + "/bug-reports?status=RECEIVED&amp;source=USER&amp;page=0\"")))
            .andExpect(content().string(containsString(
                "href=\"" + MEMBER_PATH + "/bug-reports?status=RECEIVED&amp;source=USER&amp;page=2\"")));
    }

    @Test
    void memberBugReports_unknownMember_returnsNotFoundErrorPage() throws Exception {
        given(memberQueryService.getSummary(MEMBER_ID)).willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(get(PATH + "/bug-reports", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void memberFeedbacks_pinsMemberId() throws Exception {
        givenMember();
        UUID otherMemberId = UUID.fromString("0198ffff-0000-7000-8000-000000000009");
        given(feedbackQueryService.search(any(), any()))
            .willReturn(new FeedbackPageResponse(List.of(feedbackItem()), 0, 20, 1));

        mockMvc.perform(get(PATH + "/feedbacks", MEMBER_ID).with(asAdmin())
                .param("memberId", otherMemberId.toString()).param("rating", "5"))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/member-feedbacks"))
            .andExpect(content().string(containsString("href=\"/admin/calls/session-0001\"")))
            .andExpect(content().string(containsString("이용하고 싶지 않음")))
            .andExpect(content().string(not(containsString("<th>회원</th>"))))
            .andExpect(content().string(containsString("action=\"" + MEMBER_PATH + "/feedbacks\"")))
            .andExpect(content().string(matchesPattern(
                "(?s).*class=\"tab tab-active\" href=\"" + MEMBER_PATH + "/feedbacks\" aria-current=\"page\".*")));

        ArgumentCaptor<FeedbackSearchRequest> request = forClass(FeedbackSearchRequest.class);
        ArgumentCaptor<Pageable> pageable = forClass(Pageable.class);
        verify(feedbackQueryService).search(request.capture(), pageable.capture());
        assertThat(request.getValue()).isEqualTo(new FeedbackSearchRequest(MEMBER_ID, null, null, 5, false));
        assertThat(pageable.getValue()).isEqualTo(PageRequest.of(0, 20));
    }

    @Test
    void memberFeedbacks_pageLinksStayInTab() throws Exception {
        givenMember();
        given(feedbackQueryService.search(any(), any()))
            .willReturn(new FeedbackPageResponse(List.of(feedbackItem()), 1, 20, 41));

        mockMvc.perform(get(PATH + "/feedbacks", MEMBER_ID).with(asAdmin())
                .param("from", "2026-10-01").param("detailedOnly", "true").param("page", "1"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString(
                "href=\"" + MEMBER_PATH + "/feedbacks?from=2026-10-01&amp;detailedOnly=true&amp;page=0\"")))
            .andExpect(content().string(containsString(
                "href=\"" + MEMBER_PATH + "/feedbacks?from=2026-10-01&amp;detailedOnly=true&amp;page=2\"")));
    }

    @Test
    void memberFeedbacks_unknownMember_returnsNotFoundErrorPage() throws Exception {
        given(memberQueryService.getSummary(MEMBER_ID)).willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(get(PATH + "/feedbacks", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"));

        verify(feedbackQueryService, never()).search(any(), any());
    }

    @Test
    void sidebar_hasFeedbackLinkAfterCalls() throws Exception {
        givenMember();

        mockMvc.perform(get(PATH, MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(stringContainsInOrder(
                "href=\"/admin/calls\"", "href=\"/admin/feedbacks\">피드백</a>",
                "href=\"/admin/onboarding-submissions\"")));
    }

    private void givenMember() {
        given(memberQueryService.getSummary(MEMBER_ID)).willReturn(new MemberSummaryResponse(MEMBER_ID, "테스터",
            "foo@example.com", LoginType.GOOGLE, Instant.parse("2026-10-20T03:00:00Z")));
        given(callHistoryQueryService.getMemberSummary(MEMBER_ID))
            .willReturn(new MemberCallSummaryResponse(0, 0, null, 0));
        given(callHistoryQueryService.search(any(), any())).willReturn(new CallHistoryPageResponse(List.of(), 0, 5, 0));
    }

}
