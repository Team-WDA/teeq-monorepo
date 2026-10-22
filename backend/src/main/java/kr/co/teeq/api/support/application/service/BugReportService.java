package kr.co.teeq.api.support.application.service;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.application.service.MediaService;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.media.core.model.StoredMedia;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.support.application.dto.request.BugReportCreateRequest;
import kr.co.teeq.api.support.application.dto.response.BugReportCreateResponse;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.port.BugReportNotification;
import kr.co.teeq.api.support.core.port.BugReportNotificationPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import tools.jackson.databind.ObjectMapper;

/**
 * 버그 제보 접수 흐름. 파일 쓰기와 알림은 DB 트랜잭션 밖에서 하고 DB 저장만 {@link BugReportCommandService}에 맡긴다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BugReportService {

    private static final int MAXIMUM_IMAGE_COUNT = 5;
    private static final int MAXIMUM_LOG_ENTRY_COUNT = 100;
    private static final int MAXIMUM_LOG_BYTES = 5 * 1024 * 1024;

    private final MediaService mediaService;
    private final BugReportCommandService bugReportCommandService;
    private final BugReportNotificationPort bugReportNotificationPort;
    private final ObjectMapper objectMapper;

    public BugReportCreateResponse create(Member member, BugReportCreateRequest request, List<MultipartFile> images) {
        List<MultipartFile> files = images == null ? List.of() : images;
        if (files.size() > MAXIMUM_IMAGE_COUNT) {
            throw new CustomException(ErrorCode.BUG_REPORT_IMAGE_TOO_MANY);
        }
        validateLogEntryCount(request);
        // 받은 원문이 아니라 바인딩된 레코드를 다시 직렬화해 저장하므로 크기도 그 결과로 잰다
        String errorLogsJson = serialize(request.errorLogs());
        String networkLogsJson = serialize(request.networkLogs());
        validateLogSize(errorLogsJson, networkLogsJson);

        List<StoredMedia> storedImages = mediaService.storeImages(MediaCategory.BUG_REPORT_IMAGE, files);
        UUID bugReportId = saveOrCleanUp(member, request, errorLogsJson, networkLogsJson, storedImages);

        notifyQuietly(new BugReportNotification(bugReportId, request.source(), request.content(),
            request.environment().appVersion(), request.environment().platform()));
        return new BugReportCreateResponse(bugReportId);
    }

    private void validateLogEntryCount(BugReportCreateRequest request) {
        boolean hasLogs = isNotEmpty(request.errorLogs()) || isNotEmpty(request.networkLogs());
        if (hasLogs && request.source() == BugReportSource.USER) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
        if (sizeOf(request.errorLogs()) > MAXIMUM_LOG_ENTRY_COUNT
            || sizeOf(request.networkLogs()) > MAXIMUM_LOG_ENTRY_COUNT) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
    }

    private void validateLogSize(String errorLogsJson, String networkLogsJson) {
        long totalBytes = byteLength(errorLogsJson) + byteLength(networkLogsJson);
        if (totalBytes > MAXIMUM_LOG_BYTES) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
    }

    private UUID saveOrCleanUp(
        Member member,
        BugReportCreateRequest request,
        String errorLogsJson,
        String networkLogsJson,
        List<StoredMedia> storedImages
    ) {
        try {
            return bugReportCommandService.save(member, request, errorLogsJson, networkLogsJson, storedImages);
        } catch (RuntimeException exception) {
            // DB에 반영되지 않은 파일이 남지 않게 정리한다
            mediaService.deleteAll(MediaCategory.BUG_REPORT_IMAGE, storedImages.stream().map(StoredMedia::key).toList());
            throw exception;
        }
    }

    // 알림 실패가 접수 결과를 바꾸지 않게 한다. 예외 메시지에 외부 주소가 섞일 수 있어 클래스명만 남긴다
    private void notifyQuietly(BugReportNotification notification) {
        try {
            bugReportNotificationPort.notify(notification);
        } catch (RuntimeException exception) {
            log.warn("버그 제보 알림 전송 실패. bugReportId={}, exception={}",
                notification.bugReportId(), exception.getClass().getSimpleName());
        }
    }

    private String serialize(List<?> logs) {
        return logs == null ? null : objectMapper.writeValueAsString(logs);
    }

    private long byteLength(String json) {
        return json == null ? 0 : json.getBytes(StandardCharsets.UTF_8).length;
    }

    private boolean isNotEmpty(List<?> logs) {
        return logs != null && !logs.isEmpty();
    }

    private int sizeOf(List<?> logs) {
        return logs == null ? 0 : logs.size();
    }

}
