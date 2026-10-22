package kr.co.teeq.api.support.application.service;

import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.core.model.StoredMedia;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.support.application.dto.request.BugReportCreateRequest;
import kr.co.teeq.api.support.application.dto.request.BugReportEnvironmentRequest;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import kr.co.teeq.api.support.core.entity.BugReport;
import kr.co.teeq.api.support.core.entity.BugReportImage;
import kr.co.teeq.api.support.core.model.BugReportEnvironment;
import kr.co.teeq.api.support.core.repository.BugReportImageRepository;
import kr.co.teeq.api.support.core.repository.BugReportRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 제보와 이미지 행의 저장을 한 트랜잭션으로 처리한다. 파일 입출력과 알림은 이 트랜잭션 밖({@link BugReportService})에서 한다.
 */
@Service
@RequiredArgsConstructor
public class BugReportCommandService {

    private final BugReportRepository bugReportRepository;
    private final BugReportImageRepository bugReportImageRepository;

    @Transactional
    public UUID save(
        Member member,
        BugReportCreateRequest request,
        String errorLogsJson,
        String networkLogsJson,
        List<StoredMedia> images
    ) {
        BugReportEnvironmentRequest environmentRequest = request.environment();
        BugReportEnvironment environment = new BugReportEnvironment(
            environmentRequest.appVersion(),
            environmentRequest.platform(),
            environmentRequest.osVersion(),
            environmentRequest.deviceModel());
        BugReport bugReport = bugReportRepository.save(BugReport.of(
            member, request.source(), request.content(), environment, errorLogsJson, networkLogsJson,
            request.omittedErrorLogCount(), request.omittedNetworkLogCount()));

        List<BugReportImage> bugReportImages = IntStream.range(0, images.size())
            .mapToObj(index -> {
                StoredMedia image = images.get(index);
                return BugReportImage.of(bugReport, image.key(), image.contentType(), image.sizeBytes(), index);
            })
            .toList();
        bugReportImageRepository.saveAll(bugReportImages);
        return bugReport.getId();
    }

    /**
     * 처리 상태를 바꾼다. 같은 상태로 바꾸면 {@code STATE_CONFLICT}이다.
     */
    @Transactional
    public BugReportStatus changeStatus(UUID bugReportId, BugReportStatus target) {
        BugReport bugReport = bugReportRepository.findDetailByIdAndDeletedFalse(bugReportId)
            .orElseThrow(() -> new CustomException(ErrorCode.BUG_REPORT_NOT_FOUND));
        bugReport.changeStatus(target);
        return bugReport.getStatus();
    }

}
