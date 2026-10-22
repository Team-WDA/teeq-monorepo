package kr.co.teeq.api.support.application.service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.application.service.MediaService;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.support.application.dto.response.BugReportDetailResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportErrorLogResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportImageResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportNetworkLogResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportPageResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportSummaryResponse;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import kr.co.teeq.api.support.core.entity.BugReport;
import kr.co.teeq.api.support.core.model.BugReportEnvironment;
import kr.co.teeq.api.support.core.repository.BugReportImageRepository;
import kr.co.teeq.api.support.core.repository.BugReportRepository;
import kr.co.teeq.api.support.core.repository.BugReportSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

/**
 * 관리자용 버그 제보 조회. 탈퇴한 회원의 제보도 조회하므로 회원의 삭제 여부로 거르지 않는다.
 */
@Service
@RequiredArgsConstructor
public class BugReportQueryService {

    // 요청의 정렬은 무시하고 항상 최신 제보가 먼저 오게 한다
    private static final Sort BUG_REPORT_SORT = Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"));
    private static final int CONTENT_PREVIEW_LENGTH = 80;
    private static final String PREVIEW_ELLIPSIS = "…";

    private final BugReportRepository bugReportRepository;
    private final BugReportImageRepository bugReportImageRepository;
    private final MediaService mediaService;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public BugReportPageResponse search(BugReportStatus status, BugReportSource source, Pageable pageable) {
        Pageable fixedSortPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), BUG_REPORT_SORT);
        Page<BugReport> page = bugReportRepository.findAll(toSpecification(status, source), fixedSortPageable);
        List<BugReportSummaryResponse> items = page.getContent().stream().map(this::toSummary).toList();
        return new BugReportPageResponse(items, page.getNumber(), page.getSize(), page.getTotalElements());
    }

    @Transactional(readOnly = true)
    public BugReportDetailResponse getDetail(UUID bugReportId) {
        BugReport bugReport = bugReportRepository.findDetailByIdAndDeletedFalse(bugReportId)
            .orElseThrow(() -> new CustomException(ErrorCode.BUG_REPORT_NOT_FOUND));
        List<BugReportImageResponse> images = bugReportImageRepository
            .findAllByBugReportIdAndDeletedFalseOrderBySortOrderAsc(bugReportId).stream()
            .map(image -> new BugReportImageResponse(
                mediaService.urlFor(MediaCategory.BUG_REPORT_IMAGE, image.getStorageKey())))
            .toList();
        Member member = bugReport.getMember();
        BugReportEnvironment environment = bugReport.getEnvironment();
        return new BugReportDetailResponse(bugReport.getId(), bugReport.getContent(), bugReport.getStatus(),
            bugReport.getSource(), bugReport.getCreatedAt(), environment.appVersion(), environment.platform(),
            environment.osVersion(), environment.deviceModel(), member.getId(), member.getEmail(),
            member.getNickname(), member.isDeleted(), images,
            parseLogs(bugReport.getErrorLogsJson(), BugReportErrorLogResponse.class),
            parseLogs(bugReport.getNetworkLogsJson(), BugReportNetworkLogResponse.class),
            bugReport.getOmittedErrorLogCount(), bugReport.getOmittedNetworkLogCount());
    }

    // null이 아닌 조건만 합친다. 회원의 삭제 여부는 조건에 넣지 않는다
    private Specification<BugReport> toSpecification(BugReportStatus status, BugReportSource source) {
        List<Specification<BugReport>> specifications = new ArrayList<>();
        specifications.add(BugReportSpecifications.notDeleted());
        if (status != null) {
            specifications.add(BugReportSpecifications.ofStatus(status));
        }
        if (source != null) {
            specifications.add(BugReportSpecifications.ofSource(source));
        }
        return Specification.allOf(specifications);
    }

    private BugReportSummaryResponse toSummary(BugReport bugReport) {
        Member member = bugReport.getMember();
        return new BugReportSummaryResponse(bugReport.getId(), preview(bugReport.getContent()), bugReport.getStatus(),
            bugReport.getSource(), member.getEmail(), member.isDeleted(), bugReport.getCreatedAt());
    }

    private String preview(String content) {
        if (content.length() <= CONTENT_PREVIEW_LENGTH) {
            return content;
        }
        return content.substring(0, CONTENT_PREVIEW_LENGTH) + PREVIEW_ELLIPSIS;
    }

    private <T> List<T> parseLogs(String logsJson, Class<T> logType) {
        if (logsJson == null) {
            return List.of();
        }
        return objectMapper.readValue(logsJson,
            objectMapper.getTypeFactory().constructCollectionType(List.class, logType));
    }

}
