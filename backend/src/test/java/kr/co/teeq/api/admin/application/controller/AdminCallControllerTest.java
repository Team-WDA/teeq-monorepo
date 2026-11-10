package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.matchesPattern;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.stringContainsInOrder;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDetailResponse;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDetailResponse.ConversationState;
import kr.co.teeq.api.admin.application.service.AdminCallDetailService;
import kr.co.teeq.api.admin.application.view.AdminCallUsageModel;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.call.application.dto.request.CallHistorySearchRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;
import kr.co.teeq.api.call.application.dto.response.CallHistoryPageResponse;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.call.application.service.CallHistoryQueryService;
import kr.co.teeq.api.call.application.service.CallUsageService;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.call.core.constant.EndReason;
import kr.co.teeq.api.call.core.port.AiCallDetail;
import kr.co.teeq.api.call.core.port.AiCallQuality;
import kr.co.teeq.api.call.core.port.AiCallTurn;
import kr.co.teeq.api.call.core.port.AiCallTurnRole;
import kr.co.teeq.api.call.core.port.AiCallUsage;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.feedback.application.dto.response.CallFeedbackResponse;
import kr.co.teeq.api.feedback.application.service.FeedbackQueryService;
import kr.co.teeq.api.feedback.core.constant.AwkwardMoment;
import kr.co.teeq.api.feedback.core.constant.PreviousCallRecall;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;
import kr.co.teeq.api.feedback.core.constant.StartReason;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminCallController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminCallController.class,
    AdminCallUsageModel.class
})
class AdminCallControllerTest {

    private static final String PATH = "/admin/calls";
    private static final String SESSION_ID = "session-0001";
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final CallHistorySearchRequest EMPTY_REQUEST =
        new CallHistorySearchRequest(null, null, null, null, null, false);

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private CallHistoryQueryService callHistoryQueryService;

    @MockitoBean
    private AdminCallDetailService adminCallDetailService;

    @MockitoBean
    private CallUsageService callUsageService;

    @MockitoBean
    private FeedbackQueryService feedbackQueryService;

    @Test
    void calls_defaultRequest_passesEmptyRequestAndFirstPageAndRendersRows() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(endedCall(), pendingCall()),
            0, 20, 2));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/calls"))
            // 한국 시간 2026-10-20 12:00 시작, 날짜 구분 헤더와 행
            .andExpect(content().string(containsString("2026-10-20")))
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            .andExpect(content().string(containsString("통화자")))
            .andExpect(content().string(containsString("foo@example.com")))
            .andExpect(content().string(containsString("종료")))
            .andExpect(content().string(containsString("대기 중")))
            .andExpect(content().string(containsString("사용자 종료")))
            // 사이드바의 통화 기록 링크
            .andExpect(content().string(containsString("href=\"/admin/calls\"")));

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(callHistoryQueryService).search(org.mockito.ArgumentMatchers.eq(EMPTY_REQUEST), pageable.capture());
        assertThat(pageable.getValue()).isEqualTo(PageRequest.of(0, 20));
    }

    @Test
    void calls_rowLinksToDetailOnlyWhenCallSessionIdExists() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(pendingCall()), 0, 20, 1));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("대기 중")))
            .andExpect(content().string(not(matchesPattern("(?s).*/admin/calls/(?!usages).*"))));

        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(endedCall()), 0, 20, 1));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("href=\"/admin/calls/" + SESSION_ID + "\"")));
    }

    @Test
    void calls_withFilters_keepsFormValuesAndPassesRequest() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin())
                .param("keyword", "foo").param("from", "2026-10-01").param("to", "2026-10-31")
                .param("status", "ENDED").param("abnormalOnly", "true"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"foo\"")))
            .andExpect(content().string(containsString("value=\"2026-10-01\"")))
            .andExpect(content().string(containsString("value=\"2026-10-31\"")))
            .andExpect(content().string(containsString("checked")))
            .andExpect(content().string(containsString("통화 기록이 없습니다.")));

        verify(callHistoryQueryService).search(
            org.mockito.ArgumentMatchers.eq(new CallHistorySearchRequest(null, "foo", LocalDate.of(2026, 10, 1),
                LocalDate.of(2026, 10, 31), CallStatus.ENDED, true)), any());
    }

    @Test
    void calls_middlePage_paginationLinksCarryOnlyFiltersWithValues() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(endedCall()), 1, 20, 50));

        mockMvc.perform(get(PATH).with(asAdmin()).param("keyword", "foo").param("page", "1").param("size", "1"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("2 / 3")))
            .andExpect(content().string(containsString("/admin/calls?keyword=foo&amp;page=0\"")))
            .andExpect(content().string(containsString("/admin/calls?keyword=foo&amp;page=2\"")))
            .andExpect(content().string(not(containsString("size="))));

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(callHistoryQueryService).search(any(), pageable.capture());
        assertThat(pageable.getValue()).isEqualTo(PageRequest.of(1, 20));
    }

    @Test
    void calls_keywordWithPlus_isEncodedStrictlyInPaginationLink() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(endedCall()), 0, 20, 50));

        mockMvc.perform(get(PATH).with(asAdmin()).param("keyword", "user+tag"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("/admin/calls?keyword=user%2Btag&amp;page=1\"")));
    }

    @Test
    void calls_keywordWithSpaceAmpersandAndEquals_isFullyEncodedInPaginationLink() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(endedCall()), 0, 20, 50));

        mockMvc.perform(get(PATH).with(asAdmin()).param("keyword", "a b&c=d"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("/admin/calls?keyword=a%20b%26c%3Dd&amp;page=1\"")));
    }

    @Test
    void calls_negativeAndHugePage_areClampedWithoutError() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin()).param("page", "-5")).andExpect(status().isOk());
        mockMvc.perform(get(PATH).with(asAdmin()).param("page", "2147483647")).andExpect(status().isOk());

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(callHistoryQueryService, org.mockito.Mockito.times(2)).search(any(), pageable.capture());
        assertThat(pageable.getAllValues().get(0)).isEqualTo(PageRequest.of(0, 20));
        assertThat(pageable.getAllValues().get(1)).isEqualTo(PageRequest.of(Integer.MAX_VALUE / 20, 20));
    }

    @Test
    void calls_malformedParameters_show400ErrorScreenWithoutCallingService() throws Exception {
        mockMvc.perform(get(PATH).with(asAdmin()).param("status", "XYZ"))
            .andExpect(status().isBadRequest()).andExpect(view().name("admin/error"));
        mockMvc.perform(get(PATH).with(asAdmin()).param("from", "2026-13-45"))
            .andExpect(status().isBadRequest()).andExpect(view().name("admin/error"));
        mockMvc.perform(get(PATH).with(asAdmin()).param("page", "abc"))
            .andExpect(status().isBadRequest()).andExpect(view().name("admin/error"));

        verify(callHistoryQueryService, never()).search(any(), any());
    }

    @Test
    void detail_loaded_rendersCallInfoSummaryConversationAndCost() throws Exception {
        AiCallDetail aiDetail = new AiCallDetail(SESSION_ID, null, "오늘 하루를 이야기했다", "gpt-test",
            new BigDecimal("0.0123"), true, List.of(
                new AiCallTurn(0, AiCallTurnRole.USER, "안녕하세요", false, 800, 300, null, null, null),
                new AiCallTurn(1, AiCallTurnRole.ASSISTANT, "반가워요", true, 900, 350, null, null, null)),
            null, null, null, null, List.of());
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.LOADED, aiDetail));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/call-detail"))
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            .andExpect(content().string(containsString("사용자 종료")))
            .andExpect(content().string(containsString("오늘 하루를 이야기했다")))
            .andExpect(content().string(containsString("안녕하세요")))
            .andExpect(content().string(containsString("반가워요")))
            .andExpect(content().string(containsString("끼어듦")))
            .andExpect(content().string(containsString("0.0123")))
            .andExpect(content().string(containsString("gpt-test")))
            .andExpect(content().string(not(containsString("<details"))))
            .andExpect(content().string(containsString("aria-label=\"위치 경로\"")))
            .andExpect(content().string(not(containsString("통화 기록으로"))))
            .andExpect(content().string(not(containsString("대화를 불러오지 못했습니다"))));
    }

    @Test
    void detail_loadedWithNullOptionalFields_showsDash() throws Exception {
        AiCallDetail aiDetail = new AiCallDetail(SESSION_ID, null, null, null, null, null, List.of(
            new AiCallTurn(0, AiCallTurnRole.USER, "안녕하세요", false, null, null, null, null, null)),
            null, null, null, null, List.of());
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.LOADED, aiDetail));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("안녕하세요")))
            .andExpect(content().string(matchesPattern(dashAfterLabel("추정 비용"))))
            .andExpect(content().string(matchesPattern(dashAfterLabel("LLM 모델"))))
            .andExpect(content().string(matchesPattern(dashAfterLabel("기억 주입"))))
            .andExpect(content().string(matchesPattern(
                "(?s).*<td class=\"numeric-cell\">0</td>\\s*<td>사용자</td>"
                    + "\\s*<td class=\"numeric-cell\">-</td>\\s*<td class=\"numeric-cell\">-</td>"
                    + "\\s*<td class=\"numeric-cell\">-</td>.*")));
    }

    private static String numericCells(String... cellTexts) {
        StringBuilder pattern = new StringBuilder();
        for (String cellText : cellTexts) {
            pattern.append("\\s*<td class=\"numeric-cell\">").append(cellText).append("</td>");
        }
        return pattern.toString();
    }

    private static AiCallDetail aiMetricsDetail(
        AiCallQuality quality, Integer firstAiAudioMillis, List<AiCallUsage> usages, List<AiCallTurn> turns) {
        return new AiCallDetail(SESSION_ID, null, null, null, null, null, turns, quality, firstAiAudioMillis,
            "a1b2c3d", 3, usages);
    }

    private void givenDetail(ConversationState state, AiCallDetail aiDetail) {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), state, aiDetail));
    }

    @Test
    void detail_rendersAiMetricsPanelExpanded() throws Exception {
        givenDetail(ConversationState.LOADED, aiMetricsDetail(new AiCallQuality(820, 1740, 2, false), 1250,
            List.of(), List.of()));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("AI 지표")))
            .andExpect(content().string(containsString("p50 지연")))
            .andExpect(content().string(containsString("820ms")))
            .andExpect(content().string(containsString("p95 지연")))
            .andExpect(content().string(containsString("1,740ms")))
            .andExpect(content().string(containsString("1,250ms")))
            .andExpect(content().string(containsString("2회")))
            .andExpect(content().string(containsString("아니요")))
            .andExpect(content().string(containsString("a1b2c3d")))
            .andExpect(content().string(matchesPattern("(?s).*<dt>통화 횟수</dt>\\s*<dd>3번째 통화</dd>.*")))
            .andExpect(content().string(not(containsString("call-conversation-latency"))));
    }

    @Test
    void detail_aiMetricsPanelIsSiblingAfterConversationPanel() throws Exception {
        givenDetail(ConversationState.LOADED, aiMetricsDetail(new AiCallQuality(820, 1740, 2, false), 1250,
            List.of(), List.of()));

        String body = mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        // 대화 패널이 닫힌 뒤에 AI 지표 패널이 따로 시작한다(대화 패널 본문 안에 중첩되지 않는다)
        String betweenPanels = body.substring(body.indexOf("<h2>대화</h2>"), body.indexOf("<h2>AI 지표</h2>"));
        assertThat(betweenPanels).contains("</section>");
        assertThat(body.split("<h2>AI 지표</h2>", -1)).hasSize(2);
    }

    @Test
    void detail_rendersNotMeasuredForNullAiValues() throws Exception {
        // 턴 목록을 비워 턴별 지연 표의 "측정 안 됨"이 섞이지 않게 하고 타일 5개만 센다
        List<AiCallTurn> noTurns = List.of();
        givenDetail(ConversationState.LOADED, aiMetricsDetail(null, null, List.of(), noTurns));

        String body = mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertThat(body.split("측정 안 됨", -1).length - 1).isEqualTo(5);
    }

    @Test
    void detail_rendersNotMeasuredForNullTurnLatenciesPerRole() throws Exception {
        givenDetail(ConversationState.LOADED, aiMetricsDetail(null, null, List.of(), List.of(
            new AiCallTurn(0, AiCallTurnRole.USER, "안녕", false, null, null, null, null, null),
            new AiCallTurn(1, AiCallTurnRole.ASSISTANT, "반가워", false, 900, null, 190, null, null))));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            // 사용자 턴: STT 지연·말끝 감지 지연이 없으면 측정 안 됨
            .andExpect(content().string(matchesPattern("(?s).*<td>사용자</td>"
                + numericCells("-", "-", "-", "측정 안 됨", "측정 안 됨") + ".*")))
            // AI 턴: LLM 첫 토큰이 없으면 측정 안 됨
            .andExpect(content().string(matchesPattern("(?s).*<td>AI</td>"
                + numericCells("900ms", "측정 안 됨", "190ms", "-", "-") + ".*")));
    }

    @Test
    void detail_rendersUsageTableWithKindLabelsAndEmptyMessage() throws Exception {
        List<AiCallUsage> usages = List.of(
            new AiCallUsage("stt", "deepgram", "nova", new BigDecimal("52.4"), null, null, null, null),
            new AiCallUsage("llm", "openai", "gpt-x", null, 2310L, 1000L, 410L, null));
        givenDetail(ConversationState.LOADED, aiMetricsDetail(null, null, usages, List.of()));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString(">STT</td>")))
            .andExpect(content().string(containsString(">LLM</td>")))
            .andExpect(content().string(containsString("2,310")))
            .andExpect(content().string(not(containsString("사용량 기록이 없습니다."))));

        givenDetail(ConversationState.LOADED, aiMetricsDetail(null, null, List.of(), List.of()));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(content().string(containsString("사용량 기록이 없습니다.")));
    }

    @Test
    void detail_rendersTurnLatencyColumnsPerRole() throws Exception {
        givenDetail(ConversationState.LOADED, aiMetricsDetail(null, null, List.of(), List.of(
            new AiCallTurn(0, AiCallTurnRole.USER, "안녕", false, null, null, null, 120, 340),
            new AiCallTurn(1, AiCallTurnRole.ASSISTANT, "반가워", false, 900, 300, 190, null, null),
            new AiCallTurn(2, AiCallTurnRole.ASSISTANT, "또 만나", false, 900, 300, null, null, null))));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("190ms")))
            .andExpect(content().string(containsString("120ms")))
            .andExpect(content().string(containsString("340ms")))
            .andExpect(content().string(matchesPattern("(?s).*<td>사용자</td>"
                + numericCells("-", "-", "-", "120ms", "340ms") + ".*")))
            .andExpect(content().string(matchesPattern("(?s).*<td>AI</td>"
                + numericCells("900ms", "300ms", "190ms", "-", "-") + ".*")))
            .andExpect(content().string(matchesPattern("(?s).*<td>AI</td>"
                + numericCells("900ms", "300ms", "측정 안 됨", "-", "-") + ".*")));
    }

    @Test
    void detail_emptyConversationStillShowsAiMetrics() throws Exception {
        givenDetail(ConversationState.EMPTY, aiMetricsDetail(new AiCallQuality(820, 1740, 2, false), 1250,
            List.of(), List.of()));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("대화 내용이 없습니다.")))
            .andExpect(content().string(containsString("AI 지표")))
            .andExpect(content().string(containsString("820ms")))
            // EMPTY 안내는 원래의 단일 문구이고 대화 패널은 그 문구로 끝난다
            .andExpect(content().string(matchesPattern("(?s).*<p class=\"panel-body muted\">대화 내용이 없습니다\\."
                + " 발화가 없었거나 보관 기간이 지났을 수 있습니다\\.</p>\\s*</section>.*")));
    }

    @Test
    void detail_resultPendingHidesAiMetricsEvenWithAiDetail() throws Exception {
        givenDetail(ConversationState.RESULT_PENDING, aiMetricsDetail(new AiCallQuality(820, 1740, 2, false), 1250,
            List.of(), List.of()));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("AI 지표"))));
    }

    @Test
    void detail_unavailableHidesAiMetrics() throws Exception {
        givenDetail(ConversationState.UNAVAILABLE, null);

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("AI 지표"))));
    }

    @Test
    void detail_formatsUsageAudioSecondsToOneDecimal() throws Exception {
        List<AiCallUsage> usages = List.of(new AiCallUsage("stt", "deepgram", "nova",
            new BigDecimal("52.400001525878906"), null, null, null, null));
        givenDetail(ConversationState.LOADED, aiMetricsDetail(null, null, usages, List.of()));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString(">52.4</td>")))
            .andExpect(content().string(not(containsString("52.4000"))));
    }

    // 라벨 바로 뒤의 dd가 대시인지 확인해 항목별로 자리표시자를 구분한다
    private static String dashAfterLabel(String labelPattern) {
        return "(?s).*<dt>" + labelPattern + "</dt>\\s*<dd[^>]*>-</dd>.*";
    }

    @Test
    void detail_resultPending_showsResultPendingNotice() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.RESULT_PENDING, null));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("통화 결과를 아직 받지 못했습니다.")));
    }

    @Test
    void detail_resultMissing_showsResultMissingNotice() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.RESULT_MISSING, null));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("통화 결과가 수신되지 않았습니다.")));
    }

    @Test
    void detail_empty_showsEmptyNotice() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.EMPTY, null));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("대화 내용이 없습니다. 발화가 없었거나 보관 기간이 지났을 수 있습니다.")));
    }

    @Test
    void detail_notRecorded_showsNotRecordedNotice() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.NOT_RECORDED, null));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("AI 서버에 기록이 없습니다")));
    }

    @Test
    void detail_unavailable_showsCallInfoAndRetryLink() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.UNAVAILABLE, null));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("대화를 불러오지 못했습니다")))
            .andExpect(content().string(containsString("다시 시도")))
            .andExpect(content().string(containsString("href=\"/admin/calls/" + SESSION_ID + "\"")))
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            .andExpect(content().string(containsString("사용자 종료")));
    }

    @Test
    void detail_conversationText_isEscaped() throws Exception {
        AiCallDetail aiDetail = new AiCallDetail(SESSION_ID, null, null, null, null, null, List.of(
            new AiCallTurn(0, AiCallTurnRole.USER, "<script>alert(1)</script>", false, null, null, null, null, null)),
            null, null, null, null, List.of());
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.LOADED, aiDetail));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("&lt;script&gt;alert(1)&lt;/script&gt;")))
            .andExpect(content().string(not(containsString("<script>alert(1)"))));
    }

    @Test
    void detail_unknownSession_shows404ErrorScreen() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willThrow(new CustomException(ErrorCode.CALL_SESSION_NOT_FOUND));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void callDetail_withoutFeedback_rendersEmptyMessage() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.EMPTY, null));
        given(feedbackQueryService.getByCallSessionId(SESSION_ID)).willReturn(Optional.empty());

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("이 통화의 피드백")))
            .andExpect(content().string(containsString("피드백이 없습니다.")))
            .andExpect(content().string(not(containsString("필수 피드백"))));

        // 피드백 조회는 AI 서버를 부르는 상세 서비스 밖에서, 상세 조회 뒤에 따로 한다
        InOrder order = inOrder(adminCallDetailService, feedbackQueryService);
        order.verify(adminCallDetailService).getDetail(SESSION_ID);
        order.verify(feedbackQueryService).getByCallSessionId(SESSION_ID);
    }

    @Test
    void callDetail_withRequiredOnly_rendersRequiredAndNoDetailedNotice() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.EMPTY, null));
        given(feedbackQueryService.getByCallSessionId(SESSION_ID)).willReturn(Optional.of(new CallFeedbackResponse(
            new CallFeedbackResponse.RequiredPart(3, RevisitIntention.NEUTRAL, null,
                List.of(AwkwardMoment.CUT, AwkwardMoment.SLOW)),
            null)));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("필수 피드백")))
            .andExpect(content().string(containsString("3점")))
            .andExpect(content().string(containsString("잘 모르겠음")))
            .andExpect(content().string(stringContainsInOrder("말이 끊김", "답이 늦음")))
            // 첫 통화라 지난 통화 기억 질문이 없었으면 행을 숨긴다
            .andExpect(content().string(not(containsString("지난 통화 기억"))))
            .andExpect(content().string(containsString("상세 피드백은 제출되지 않았습니다.")))
            .andExpect(content().string(not(containsString("피드백이 없습니다."))))
            .andExpect(content().string(not(containsString(">NEUTRAL<"))))
            .andExpect(content().string(not(containsString(">CUT<"))));
    }

    @Test
    void callDetail_withDetailedFeedback_hidesMemoryRowWhenNotApplicable() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.EMPTY, null));
        given(feedbackQueryService.getByCallSessionId(SESSION_ID)).willReturn(Optional.of(new CallFeedbackResponse(
            new CallFeedbackResponse.RequiredPart(5, RevisitIntention.YES, PreviousCallRecall.REMEMBERED, List.of()),
            detailedPart(null, null, true))));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("지난 통화 기억")))
            .andExpect(content().string(containsString("기억함")))
            .andExpect(content().string(containsString("상세 피드백")))
            .andExpect(content().string(stringContainsInOrder("대화 타이밍", "4점", "타이밍이 좋았어")))
            .andExpect(content().string(containsString("성격·말투")))
            .andExpect(content().string(containsString("공감·신뢰")))
            .andExpect(content().string(containsString("개인적인 이야기")))
            .andExpect(content().string(containsString("기억·저장 안심")))
            .andExpect(content().string(not(containsString("대화 기억"))))
            .andExpect(content().string(stringContainsInOrder("누군가와 이야기하고 싶어서", "기타", "산책하다가")))
            .andExpect(content().string(not(containsString("상세 피드백은 제출되지 않았습니다."))))
            .andExpect(content().string(not(containsString(">NEED_TO_TALK<"))));
    }

    @Test
    void callDetail_withMemoryScore_showsMemoryRow() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.EMPTY, null));
        given(feedbackQueryService.getByCallSessionId(SESSION_ID)).willReturn(Optional.of(new CallFeedbackResponse(
            new CallFeedbackResponse.RequiredPart(5, RevisitIntention.YES, null, List.of()),
            detailedPart(2, "지난 이야기를 잊었어", false))));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(stringContainsInOrder("대화 기억", "2점", "지난 이야기를 잊었어")));
    }

    @Test
    void callDetail_freeText_isEscapedAndKeepsLineBreaks() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.EMPTY, null));
        given(feedbackQueryService.getByCallSessionId(SESSION_ID)).willReturn(Optional.of(new CallFeedbackResponse(
            new CallFeedbackResponse.RequiredPart(5, RevisitIntention.YES, null, List.of()),
            detailedPart(null, null, true))));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("class=\"feedback-free-text\"")))
            .andExpect(content().string(containsString("&lt;b&gt;좋았어&lt;/b&gt;")))
            .andExpect(content().string(not(containsString("<b>좋았어"))));
    }

    @Test
    void detail_unknownSession_doesNotLookUpFeedback() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willThrow(new CustomException(ErrorCode.CALL_SESSION_NOT_FOUND));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isNotFound());

        verify(feedbackQueryService, never()).getByCallSessionId(any());
    }

    private CallFeedbackResponse.DetailedPart detailedPart(Integer memoryScore, String memoryReason,
        boolean memoryNotApplicable) {
        return new CallFeedbackResponse.DetailedPart(4, "타이밍이 좋았어", 5, null, memoryScore, memoryReason,
            memoryNotApplicable, 4, null, 3, null, 2, "조금 불안했어", "<b>좋았어</b>\n다음에도",
            List.of(StartReason.NEED_TO_TALK, StartReason.OTHER), "산책하다가");
    }

    @Test
    void calls_rendersTabNavigation() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("<h1>통화 기록</h1>")))
            .andExpect(content().string(containsString("href=\"/admin/calls/usages\"")))
            .andExpect(content().string(containsString("사용량 집계")))
            .andExpect(content().string(matchesPattern(
                "(?s).*class=\"tab tab-active\" href=\"/admin/calls\" aria-current=\"page\".*")))
            .andExpect(content().string(not(containsString("breadcrumb"))));
    }

    @Test
    void usages_rendersAggregateForAllMembers() throws Exception {
        LocalDate from = LocalDate.of(2026, 10, 1);
        LocalDate to = LocalDate.of(2026, 10, 3);
        given(callUsageService.getUsages(CallUsageUnit.DAY, from, to, null)).willReturn(List.of(
            new CallUsageResponse(LocalDate.of(2026, 10, 1), 1_200, 3),
            new CallUsageResponse(LocalDate.of(2026, 10, 2), 0, 0),
            new CallUsageResponse(LocalDate.of(2026, 10, 3), 3_400, 5)));

        mockMvc.perform(get(PATH + "/usages").with(asAdmin())
                .param("unit", "DAY").param("from", "2026-10-01").param("to", "2026-10-03"))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/call-usages"))
            .andExpect(content().string(containsString("<h1>통화 기록</h1>")))
            .andExpect(content().string(containsString("1,200")))
            .andExpect(content().string(containsString("3,400")))
            // 합계 행: 4,600초, 8회
            .andExpect(content().string(containsString("합계")))
            .andExpect(content().string(containsString("4,600")))
            .andExpect(content().string(containsString("value=\"2026-10-01\"")))
            .andExpect(content().string(containsString("value=\"2026-10-03\"")))
            .andExpect(content().string(containsString("action=\"/admin/calls/usages\"")))
            .andExpect(content().string(matchesPattern(
                "(?s).*class=\"tab tab-active\" href=\"/admin/calls/usages\" aria-current=\"page\".*")))
            .andExpect(content().string(not(containsString("name=\"memberId\""))))
            .andExpect(content().string(not(containsString("/admin/members/"))));

        verify(callUsageService).getUsages(CallUsageUnit.DAY, from, to, null);
    }

    @Test
    void usages_withoutParams_usesDefaultLastSevenDays() throws Exception {
        // 고정 Clock 2026-10-20T03:00Z = 한국 시간 2026-10-20 12:00
        LocalDate from = LocalDate.of(2026, 10, 14);
        LocalDate to = LocalDate.of(2026, 10, 20);
        given(callUsageService.getUsages(CallUsageUnit.DAY, from, to, null)).willReturn(List.of());

        mockMvc.perform(get(PATH + "/usages").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"2026-10-14\"")))
            .andExpect(content().string(containsString("value=\"2026-10-20\"")))
            .andExpect(content().string(containsString("조회된 기간이 없습니다")))
            .andExpect(content().string(stringContainsInOrder(
                "call-usage-total-row", "<th class=\"numeric-cell\">0</th>", "<th class=\"numeric-cell\">0</th>")));

        verify(callUsageService).getUsages(CallUsageUnit.DAY, from, to, null);
    }

    @Test
    void usages_withMalformedUnitOrDate_showsErrorMessage() throws Exception {
        mockMvc.perform(get(PATH + "/usages").with(asAdmin()).param("unit", "WEEK"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));

        mockMvc.perform(get(PATH + "/usages").with(asAdmin()).param("from", "2026-13-45"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void usages_withoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get(PATH + "/usages"))
            .andExpect(status().is3xxRedirection())
            .andExpect(header().string("Location", containsString("/admin/login")));
    }

    @Test
    void sidebar_noLongerHasCallUsagesLink() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("/admin/call-usages"))));
    }

    @Test
    void oldCallUsagesPath_returnsNotFound() throws Exception {
        mockMvc.perform(get("/admin/call-usages").with(asAdmin()))
            .andExpect(status().isNotFound());
    }

    @Test
    void withoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get(PATH))
            .andExpect(status().is3xxRedirection())
            .andExpect(header().string("Location", containsString("/admin/login")));
        mockMvc.perform(get(PATH + "/{id}", SESSION_ID))
            .andExpect(status().is3xxRedirection())
            .andExpect(header().string("Location", containsString("/admin/login")));
    }

    private CallHistoryPageResponse pageOf(List<CallHistoryItemResponse> items, int page, int size, long total) {
        return new CallHistoryPageResponse(items, page, size, total);
    }

    private CallHistoryItemResponse endedCall() {
        return new CallHistoryItemResponse(SESSION_ID, MEMBER_ID, "통화자", "foo@example.com",
            Instant.parse("2026-10-20T03:00:00Z"), 125, CallStatus.ENDED, EndReason.USER_HANGUP, "gpt-test");
    }

    private CallHistoryItemResponse pendingCall() {
        return new CallHistoryItemResponse(null, MEMBER_ID, "통화자", "foo@example.com",
            Instant.parse("2026-10-20T04:00:00Z"), 0, CallStatus.PENDING, null, null);
    }

}
