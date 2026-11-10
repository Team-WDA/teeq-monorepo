package kr.co.teeq.api.admin.application.view;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import kr.co.teeq.api.feedback.application.dto.request.FeedbackSearchRequest;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackPageResponse;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;
import org.springframework.ui.Model;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * 피드백 목록 영역(필터 폼, 표, 페이지 이동)이 읽는 모델 변수를 채운다.
 * 전체 피드백 화면과 회원 허브의 피드백 탭이 같은 fragment를 쓰므로 변수 이름과 채우는 규칙을 한 곳에 둔다.
 */
public final class AdminFeedbackListModel {

    private static final int MIN_RATING = 1;
    private static final int MAX_RATING = 5;
    private static final List<Integer> RATING_OPTIONS =
        IntStream.rangeClosed(MIN_RATING, MAX_RATING).boxed().toList();
    // 표에서 enum 이름 대신 한국어 라벨을 보이도록 이름 → 라벨로 넘긴다
    private static final Map<String, String> REVISIT_INTENTION_LABELS = Arrays.stream(RevisitIntention.values())
        .collect(Collectors.toUnmodifiableMap(Enum::name, FeedbackDisplayLabel::revisitIntention));

    private AdminFeedbackListModel() {
    }

    public static void populate(Model model, FeedbackSearchRequest request, FeedbackPageResponse result,
        String basePath, boolean memberColumnVisible) {
        long totalPages = (result.totalElements() + result.size() - 1) / result.size();
        model.addAttribute("feedbackBasePath", basePath);
        model.addAttribute("feedbackMemberColumnVisible", memberColumnVisible);
        model.addAttribute("feedbackFrom", request.from());
        model.addAttribute("feedbackTo", request.to());
        model.addAttribute("feedbackRating", request.rating());
        model.addAttribute("feedbackDetailedOnly", request.detailedOnly());
        model.addAttribute("feedbackRatingOptions", RATING_OPTIONS);
        model.addAttribute("feedbackRevisitIntentionLabels", REVISIT_INTENTION_LABELS);
        model.addAttribute("feedbackResult", result);
        model.addAttribute("feedbackCurrentPageNumber", result.page() + 1);
        model.addAttribute("feedbackTotalPages", Math.max(totalPages, 1));
        if (result.page() > 0) {
            model.addAttribute("feedbackPreviousPageUrl", pageUrl(basePath, request, result.page() - 1));
        }
        if (result.page() + 1 < totalPages) {
            model.addAttribute("feedbackNextPageUrl", pageUrl(basePath, request, result.page() + 1));
        }
    }

    // 이전/다음 링크: 값이 있는 필터만 그대로 싣고 페이지 크기는 싣지 않는다
    private static String pageUrl(String basePath, FeedbackSearchRequest request, int page) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromPath(basePath);
        if (request.from() != null) {
            builder.queryParam("from", request.from());
        }
        if (request.to() != null) {
            builder.queryParam("to", request.to());
        }
        if (request.rating() != null) {
            builder.queryParam("rating", request.rating());
        }
        if (request.detailedOnly()) {
            builder.queryParam("detailedOnly", true);
        }
        return builder.queryParam("page", page).build().encode().toUriString();
    }

}
