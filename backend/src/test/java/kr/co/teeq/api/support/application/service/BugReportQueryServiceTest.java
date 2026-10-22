package kr.co.teeq.api.support.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Path;
import jakarta.persistence.criteria.Root;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.application.service.MediaService;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.support.application.dto.request.BugReportErrorLogRequest;
import kr.co.teeq.api.support.application.dto.request.BugReportNetworkLogRequest;
import kr.co.teeq.api.support.application.dto.response.BugReportDetailResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportPageResponse;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import kr.co.teeq.api.support.core.entity.BugReport;
import kr.co.teeq.api.support.core.entity.BugReportImage;
import kr.co.teeq.api.support.core.model.BugReportEnvironment;
import kr.co.teeq.api.support.core.repository.BugReportImageRepository;
import kr.co.teeq.api.support.core.repository.BugReportRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.test.util.ReflectionTestUtils;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

@ExtendWith(MockitoExtension.class)
class BugReportQueryServiceTest {

    private static final UUID BUG_REPORT_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c");
    private static final Instant LOGGED_AT = Instant.parse("2026-10-22T00:00:00Z");
    private static final BugReportEnvironment ENVIRONMENT =
        new BugReportEnvironment("1.2.3", BugReportPlatform.ANDROID, "Android 15", "Pixel 9");

    @Mock
    private BugReportRepository bugReportRepository;
    @Mock
    private BugReportImageRepository bugReportImageRepository;
    @Mock
    private MediaService mediaService;

    private final ObjectMapper objectMapper = JsonMapper.builder().build();
    private final Member member = Member.builder().email("a@teeq.com").password("x").nickname("소연").build();

    private BugReportQueryService bugReportQueryService;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        bugReportQueryService = new BugReportQueryService(
            bugReportRepository, bugReportImageRepository, mediaService, objectMapper);
    }

    private BugReport bugReport(String content, String errorLogsJson, String networkLogsJson, int omittedErrorLogCount) {
        BugReport bugReport = BugReport.of(member, BugReportSource.DEVELOPER_CONSOLE, content, ENVIRONMENT,
            errorLogsJson, networkLogsJson, omittedErrorLogCount, 0);
        ReflectionTestUtils.setField(bugReport, "id", BUG_REPORT_ID);
        ReflectionTestUtils.setField(bugReport, "createdAt", LOGGED_AT);
        return bugReport;
    }

    @Test
    @SuppressWarnings("unchecked")
    void search_passesFiltersAndPage() {
        Pageable requested = PageRequest.of(2, 20);
        given(bugReportRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(bugReport("앱이 멈춰요", null, null, 0)), requested, 41));

        BugReportPageResponse response =
            bugReportQueryService.search(BugReportStatus.RECEIVED, BugReportSource.USER, requested);

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(bugReportRepository).findAll(any(Specification.class), pageable.capture());
        assertThat(pageable.getValue().getPageNumber()).isEqualTo(2);
        assertThat(pageable.getValue().getPageSize()).isEqualTo(20);
        assertThat(pageable.getValue().getSort())
            .isEqualTo(Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id")));
        assertThat(response.page()).isEqualTo(2);
        assertThat(response.size()).isEqualTo(20);
        assertThat(response.totalElements()).isEqualTo(41);
        assertThat(response.items()).singleElement().satisfies(item -> {
            assertThat(item.id()).isEqualTo(BUG_REPORT_ID);
            assertThat(item.memberEmail()).isEqualTo("a@teeq.com");
            assertThat(item.contentPreview()).isEqualTo("앱이 멈춰요");
        });
    }

    @Test
    @SuppressWarnings("unchecked")
    void search_withoutFilters_stillQueries() {
        Pageable requested = PageRequest.of(0, 20);
        given(bugReportRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(), requested, 0));

        BugReportPageResponse response = bugReportQueryService.search(null, null, requested);

        assertThat(response.items()).isEmpty();
        assertThat(response.totalElements()).isZero();
    }

    // 넘긴 Specification을 가짜 Root/CriteriaBuilder에 적용해 어떤 조건이 걸렸는지 확인한다
    @SuppressWarnings("unchecked")
    private AppliedConditions searchAndApplySpecification(BugReportStatus status, BugReportSource source) {
        Pageable requested = PageRequest.of(0, 20);
        given(bugReportRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(), requested, 0));
        bugReportQueryService.search(status, source, requested);

        ArgumentCaptor<Specification<BugReport>> captor = ArgumentCaptor.forClass(Specification.class);
        verify(bugReportRepository).findAll(captor.capture(), any(Pageable.class));

        Root<BugReport> root = mock(Root.class);
        CriteriaQuery<?> query = mock(CriteriaQuery.class);
        CriteriaBuilder builder = mock(CriteriaBuilder.class);
        Path<Object> deletedPath = mock(Path.class);
        Path<Object> statusPath = mock(Path.class);
        Path<Object> sourcePath = mock(Path.class);
        given(root.get("deleted")).willReturn(deletedPath);
        // 필터가 없으면 쓰이지 않으므로 느슨하게 둔다
        lenient().when(root.get("status")).thenReturn(statusPath);
        lenient().when(root.get("source")).thenReturn(sourcePath);
        captor.getValue().toPredicate(root, query, builder);
        return new AppliedConditions(builder, deletedPath, statusPath, sourcePath);
    }

    private record AppliedConditions(
        CriteriaBuilder builder, Path<Object> deletedPath, Path<Object> statusPath, Path<Object> sourcePath) {
    }

    @Test
    void search_bothFilters_appliesNotDeletedStatusAndSource() {
        AppliedConditions applied = searchAndApplySpecification(BugReportStatus.IN_PROGRESS, BugReportSource.USER);

        verify(applied.builder()).isFalse(any());
        verify(applied.builder()).equal(applied.statusPath(), BugReportStatus.IN_PROGRESS);
        verify(applied.builder()).equal(applied.sourcePath(), BugReportSource.USER);
    }

    @Test
    void search_statusOnly_doesNotFilterBySource() {
        AppliedConditions applied = searchAndApplySpecification(BugReportStatus.RESOLVED, null);

        verify(applied.builder()).equal(applied.statusPath(), BugReportStatus.RESOLVED);
        verify(applied.builder(), never()).equal(eq(applied.sourcePath()), any());
    }

    @Test
    void search_noFilters_appliesOnlyNotDeleted() {
        AppliedConditions applied = searchAndApplySpecification(null, null);

        verify(applied.builder()).isFalse(any());
        verify(applied.builder(), never()).equal(any(), any(Object.class));
    }

    @Test
    @SuppressWarnings("unchecked")
    void search_longContent_isTruncatedToPreview() {
        Pageable requested = PageRequest.of(0, 20);
        given(bugReportRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(bugReport("가".repeat(500), null, null, 0)), requested, 1));

        BugReportPageResponse response = bugReportQueryService.search(null, null, requested);

        assertThat(response.items().get(0).contentPreview()).hasSizeLessThan(500).endsWith("…");
    }

    @Test
    void getDetail_deletedMember_stillReturnsReportWithDeletedFlag() {
        member.delete(Clock.fixed(LOGGED_AT, ZoneOffset.UTC));
        given(bugReportRepository.findDetailByIdAndDeletedFalse(BUG_REPORT_ID))
            .willReturn(Optional.of(bugReport("앱이 멈춰요", null, null, 0)));
        given(bugReportImageRepository.findAllByBugReportIdAndDeletedFalseOrderBySortOrderAsc(BUG_REPORT_ID))
            .willReturn(List.of());

        BugReportDetailResponse detail = bugReportQueryService.getDetail(BUG_REPORT_ID);

        assertThat(detail.memberDeleted()).isTrue();
        assertThat(detail.memberEmail()).isEqualTo("a@teeq.com");
        assertThat(detail.memberId()).isEqualTo(MEMBER_ID);
        assertThat(detail.errorLogs()).isEmpty();
        assertThat(detail.networkLogs()).isEmpty();
    }

    @Test
    void getDetail_parsesStoredLogsAndBuildsImageUrls() {
        String errorLogsJson = objectMapper.writeValueAsString(List.of(
            new BugReportErrorLogRequest(LOGGED_AT, "SEVERE", "name", "<script>", null, "stack")));
        String networkLogsJson = objectMapper.writeValueAsString(List.of(
            new BugReportNetworkLogRequest(LOGGED_AT, "GET", "https://api.teeq.co.kr/x", Map.of("a", "b"), null,
                false, 500, Map.of(), "body", true, 10, null)));
        given(bugReportRepository.findDetailByIdAndDeletedFalse(BUG_REPORT_ID))
            .willReturn(Optional.of(bugReport("본문", errorLogsJson, networkLogsJson, 3)));
        given(bugReportImageRepository.findAllByBugReportIdAndDeletedFalseOrderBySortOrderAsc(BUG_REPORT_ID))
            .willReturn(List.of(BugReportImage.of(null, "k1.png", "image/png", 10, 0)));
        given(mediaService.urlFor(MediaCategory.BUG_REPORT_IMAGE, "k1.png")).willReturn("https://cdn.example/k1.png");

        BugReportDetailResponse detail = bugReportQueryService.getDetail(BUG_REPORT_ID);

        assertThat(detail.images()).singleElement().satisfies(image ->
            assertThat(image.url()).isEqualTo("https://cdn.example/k1.png"));
        assertThat(detail.errorLogs()).singleElement().satisfies(log -> {
            assertThat(log.timestamp()).isEqualTo(LOGGED_AT);
            assertThat(log.message()).isEqualTo("<script>");
            assertThat(log.stackTraceText()).isEqualTo("stack");
        });
        assertThat(detail.networkLogs()).singleElement().satisfies(log -> {
            assertThat(log.statusCode()).isEqualTo(500);
            assertThat(log.responseBodyTruncated()).isTrue();
            assertThat(log.requestHeaders()).containsEntry("a", "b");
        });
        assertThat(detail.omittedErrorLogCount()).isEqualTo(3);
        assertThat(detail.platform()).isEqualTo(BugReportPlatform.ANDROID);
    }

    @Test
    void getDetail_unknownId_throwsBugReportNotFound() {
        given(bugReportRepository.findDetailByIdAndDeletedFalse(BUG_REPORT_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> bugReportQueryService.getDetail(BUG_REPORT_ID))
            .isInstanceOf(CustomException.class)
            .extracting(exception -> ((CustomException) exception).getErrorCode())
            .isEqualTo(ErrorCode.BUG_REPORT_NOT_FOUND);
    }

}
