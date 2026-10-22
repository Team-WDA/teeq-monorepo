package kr.co.teeq.api.common.core.version;

import java.util.regex.Pattern;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;

/**
 * 앱 버전(SemVer {@code x.y.z}) 값 객체. 빌드 번호와 사전 릴리스 표기는 받지 않는다.
 */
public record AppVersion(int major, int minor, int patch) implements Comparable<AppVersion> {

    // 앞자리 0과 int 오버플로(최대 9자리)를 함께 막는다
    private static final Pattern FORMAT =
        Pattern.compile("^(0|[1-9]\\d{0,8})\\.(0|[1-9]\\d{0,8})\\.(0|[1-9]\\d{0,8})$");

    /**
     * {@code x.y.z} 문자열을 파싱한다. 형식이 맞지 않으면 {@code INVALID_REQUEST}.
     */
    public static AppVersion parse(String raw) {
        if (raw == null) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
        var matcher = FORMAT.matcher(raw);
        if (!matcher.matches()) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
        return new AppVersion(
            Integer.parseInt(matcher.group(1)),
            Integer.parseInt(matcher.group(2)),
            Integer.parseInt(matcher.group(3)));
    }

    @Override
    public int compareTo(AppVersion other) {
        int majorComparison = Integer.compare(major, other.major);
        if (majorComparison != 0) {
            return majorComparison;
        }
        int minorComparison = Integer.compare(minor, other.minor);
        if (minorComparison != 0) {
            return minorComparison;
        }
        return Integer.compare(patch, other.patch);
    }

    @Override
    public String toString() {
        return major + "." + minor + "." + patch;
    }

}
