package kr.co.teeq.api.admin.application.view;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDateGroup;
import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.EndReason;
import org.junit.jupiter.api.Test;

class CallDateGrouperTest {

    private static final ZoneId KOREA = ZoneId.of("Asia/Seoul");

    private CallHistoryItemResponse item(String startedAt) {
        return new CallHistoryItemResponse("session", UUID.randomUUID(), "소연", "soyeon@teeq.com",
            Instant.parse(startedAt), 60, CallStatus.ENDED, EndReason.USER_HANGUP, "model");
    }

    @Test
    void group_splitsAtKoreaMidnight() {
        List<AdminCallDateGroup> groups = CallDateGrouper.group(
            List.of(item("2026-10-20T15:00:00Z"), item("2026-10-20T14:59:59Z")), KOREA);

        assertThat(groups).hasSize(2);
        assertThat(groups.get(0).date()).isEqualTo(LocalDate.of(2026, 10, 21));
        assertThat(groups.get(1).date()).isEqualTo(LocalDate.of(2026, 10, 20));
    }

    @Test
    void group_keepsSameDayItemsTogetherInOrder() {
        CallHistoryItemResponse first = item("2026-10-20T05:00:00Z");
        CallHistoryItemResponse second = item("2026-10-20T01:00:00Z");

        List<AdminCallDateGroup> groups = CallDateGrouper.group(List.of(first, second), KOREA);

        assertThat(groups).hasSize(1);
        assertThat(groups.get(0).rows()).extracting(row -> row.call()).containsExactly(first, second);
        assertThat(groups.get(0).rows().get(0).statusLabel()).isEqualTo("종료");
        assertThat(groups.get(0).rows().get(0).endReasonLabel()).isEqualTo("사용자 종료");
    }

    @Test
    void group_emptyList_returnsEmptyList() {
        assertThat(CallDateGrouper.group(List.of(), KOREA)).isEmpty();
    }

}
