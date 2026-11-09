package kr.co.teeq.api.admin.application.view;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDateGroup;
import kr.co.teeq.api.admin.application.dto.response.AdminCallRowView;
import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;

/**
 * 통화 목록을 시작 시각의 날짜(zoneId 기준)별로 묶는다.
 */
public final class CallDateGrouper {

    private CallDateGrouper() {
    }

    // 입력 순서를 유지하며 날짜가 바뀔 때마다 새 그룹을 만든다
    public static List<AdminCallDateGroup> group(List<CallHistoryItemResponse> items, ZoneId zoneId) {
        List<AdminCallDateGroup> groups = new ArrayList<>();
        LocalDate currentDate = null;
        List<AdminCallRowView> currentRows = null;
        for (CallHistoryItemResponse item : items) {
            LocalDate date = item.startedAt().atZone(zoneId).toLocalDate();
            if (!date.equals(currentDate)) {
                currentDate = date;
                currentRows = new ArrayList<>();
                groups.add(new AdminCallDateGroup(date, currentRows));
            }
            currentRows.add(new AdminCallRowView(item, CallDisplayLabel.status(item.status()),
                CallDisplayLabel.endReason(item.endReason())));
        }
        return groups;
    }

}
