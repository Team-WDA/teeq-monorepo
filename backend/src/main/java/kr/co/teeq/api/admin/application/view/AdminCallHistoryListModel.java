package kr.co.teeq.api.admin.application.view;

import java.time.ZoneId;
import java.util.Arrays;
import java.util.List;
import kr.co.teeq.api.admin.application.dto.response.AdminCallStatusOption;
import kr.co.teeq.api.call.application.dto.request.CallHistorySearchRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryPageResponse;
import kr.co.teeq.api.call.core.constant.CallStatus;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.ui.Model;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * 통화 목록 영역(필터 폼, 날짜 묶음 표, 페이지 이동)이 읽는 모델 변수를 채운다.
 * 전체 통화 화면과 회원 상세가 같은 fragment를 쓰므로 변수 이름과 채우는 규칙을 한 곳에 둔다.
 */
public final class AdminCallHistoryListModel {

    public static final int PAGE_SIZE = 20;

    private static final List<AdminCallStatusOption> STATUS_OPTIONS = Arrays.stream(CallStatus.values())
        .map(status -> new AdminCallStatusOption(status.name(), CallDisplayLabel.status(status)))
        .toList();

    private AdminCallHistoryListModel() {
    }

    // page * size가 int 범위를 넘으면 조회 오프셋이 넘쳐 500이 되므로, 음수는 0으로, 큰 값은 넘치지 않는 쪽으로 줄인다
    public static Pageable pageable(int page) {
        return PageRequest.of(Math.min(Math.max(page, 0), Integer.MAX_VALUE / PAGE_SIZE), PAGE_SIZE);
    }

    // 필터 폼의 공백 키워드는 조건 없음으로 본다
    public static String normalizeKeyword(String keyword) {
        return keyword == null || keyword.isBlank() ? null : keyword.strip();
    }

    public static void populate(Model model, CallHistorySearchRequest request, CallHistoryPageResponse result,
        String basePath, boolean memberColumnVisible, ZoneId zoneId) {
        long totalPages = (result.totalElements() + result.size() - 1) / result.size();
        model.addAttribute("callBasePath", basePath);
        model.addAttribute("callMemberColumnVisible", memberColumnVisible);
        model.addAttribute("callKeyword", request.keyword());
        model.addAttribute("callFrom", request.from());
        model.addAttribute("callTo", request.to());
        model.addAttribute("callStatusName", request.status() == null ? null : request.status().name());
        model.addAttribute("callAbnormalOnly", request.abnormalOnly());
        model.addAttribute("callStatusOptions", STATUS_OPTIONS);
        model.addAttribute("callResult", result);
        model.addAttribute("callGroups", CallDateGrouper.group(result.content(), zoneId));
        model.addAttribute("callCurrentPageNumber", result.page() + 1);
        model.addAttribute("callTotalPages", Math.max(totalPages, 1));
        if (result.page() > 0) {
            model.addAttribute("callPreviousPageUrl", pageUrl(basePath, request, result.page() - 1));
        }
        if (result.page() + 1 < totalPages) {
            model.addAttribute("callNextPageUrl", pageUrl(basePath, request, result.page() + 1));
        }
    }

    // 이전/다음 링크: 값이 있는 필터만 그대로 싣고 페이지 크기는 싣지 않는다
    private static String pageUrl(String basePath, CallHistorySearchRequest request, int page) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromPath(basePath);
        if (request.keyword() != null) {
            builder.queryParam("keyword", "{keyword}");
        }
        if (request.from() != null) {
            builder.queryParam("from", request.from());
        }
        if (request.to() != null) {
            builder.queryParam("to", request.to());
        }
        if (request.status() != null) {
            builder.queryParam("status", request.status().name());
        }
        if (request.abnormalOnly()) {
            builder.queryParam("abnormalOnly", true);
        }
        builder.queryParam("page", page);
        // 키워드의 +, &, =가 쿼리 구분자로 남지 않도록 URI 변수 값으로 엄격하게 인코딩한다
        return request.keyword() == null
            ? builder.build().encode().toUriString()
            : builder.encode().buildAndExpand(request.keyword()).toUriString();
    }

}
