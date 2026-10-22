package kr.co.teeq.api.media.core.constant;

import kr.co.teeq.api.common.core.exception.ErrorCode;

/**
 * 미디어 종류. 저장 도메인과 디렉터리, 최대 크기, 검증 실패 시 에러 코드를 종류별로 정한다.
 */
public enum MediaCategory {

    PROFILE_IMAGE("member", "profile-images", 5L * 1024 * 1024,
        ErrorCode.PROFILE_IMAGE_TOO_LARGE, ErrorCode.PROFILE_IMAGE_INVALID),
    BUG_REPORT_IMAGE("support", "bug-report-images", 5L * 1024 * 1024,
        ErrorCode.BUG_REPORT_IMAGE_TOO_LARGE, ErrorCode.BUG_REPORT_IMAGE_INVALID);

    private final String domainName;
    private final String directoryName;
    private final long maximumSizeBytes;
    private final ErrorCode tooLargeErrorCode;
    private final ErrorCode invalidErrorCode;

    MediaCategory(String domainName, String directoryName, long maximumSizeBytes, ErrorCode tooLargeErrorCode,
        ErrorCode invalidErrorCode) {
        this.domainName = domainName;
        this.directoryName = directoryName;
        this.maximumSizeBytes = maximumSizeBytes;
        this.tooLargeErrorCode = tooLargeErrorCode;
        this.invalidErrorCode = invalidErrorCode;
    }

    public String domainName() {
        return domainName;
    }

    public String directoryName() {
        return directoryName;
    }

    public long maximumSizeBytes() {
        return maximumSizeBytes;
    }

    public ErrorCode tooLargeErrorCode() {
        return tooLargeErrorCode;
    }

    public ErrorCode invalidErrorCode() {
        return invalidErrorCode;
    }

}
