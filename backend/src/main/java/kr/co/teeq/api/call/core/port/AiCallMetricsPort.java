package kr.co.teeq.api.call.core.port;

import java.time.LocalDate;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;

public interface AiCallMetricsPort {

    // from/to가 null이면 해당 방향은 제한 없음(전체). 실패는 모두 AI_SERVER_UNAVAILABLE이다
    AiCallMetrics find(LocalDate from, LocalDate to, CallUsageUnit unit);

}
