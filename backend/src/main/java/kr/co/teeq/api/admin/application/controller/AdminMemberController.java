package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import java.util.UUID;
import kr.co.teeq.api.member.application.dto.request.MemberSearchRequest;
import kr.co.teeq.api.member.application.dto.response.MemberPageResponse;
import kr.co.teeq.api.member.application.service.MemberDeletionService;
import kr.co.teeq.api.member.application.service.MemberQueryService;
import kr.co.teeq.api.member.core.constant.LoginType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * 회원 관리 화면. 목록(검색·필터·페이지 이동)과 회원 삭제를 다룬다. 회원 상세와 통화 보너스는 AdminMemberDetailController가 맡는다.
 * 삭제는 SUPER_ADMIN만 호출할 수 있고(보안 설정에서 막는다), 성공하면 목록으로 돌아가 안내를 보인다(PRG).
 */
@Hidden
@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/members")
public class AdminMemberController {

    private static final String MEMBERS_PATH = "/admin/members";
    private static final String MEMBERS_VIEW = "admin/members";

    private final MemberQueryService memberQueryService;
    private final MemberDeletionService memberDeletionService;

    @LogMonitoring
    @GetMapping
    public String members(
        @RequestParam(required = false) String keyword,
        @RequestParam(required = false) LoginType loginType,
        @RequestParam(required = false) Boolean deleted,
        Pageable pageable,
        Model model) {
        MemberSearchRequest request = new MemberSearchRequest(keyword, loginType);
        MemberPageResponse result = memberQueryService.search(request, clampPage(pageable));

        long totalPages = (result.totalElements() + result.size() - 1) / result.size();
        model.addAttribute("keyword", keyword);
        model.addAttribute("loginType", loginType);
        model.addAttribute("loginTypes", LoginType.values());
        model.addAttribute("deletedNotice", Boolean.TRUE.equals(deleted));
        model.addAttribute("result", result);
        model.addAttribute("currentPageNumber", result.page() + 1);
        model.addAttribute("totalPages", Math.max(totalPages, 1));
        if (result.page() > 0) {
            model.addAttribute("previousPageUrl", pageUrl(request, result.page() - 1, result.size()));
        }
        if (result.page() + 1 < totalPages) {
            model.addAttribute("nextPageUrl", pageUrl(request, result.page() + 1, result.size()));
        }
        return MEMBERS_VIEW;
    }

    @LogMonitoring
    @PostMapping("/{member-id}/delete")
    public String delete(@PathVariable("member-id") UUID memberId) {
        memberDeletionService.delete(memberId);
        return "redirect:" + MEMBERS_PATH + "?deleted=true";
    }

    // page * size가 int 범위를 넘으면 조회 오프셋이 넘쳐 500이 되므로, 넘치지 않는 마지막 페이지로 줄인다
    private Pageable clampPage(Pageable pageable) {
        int size = pageable.getPageSize();
        return PageRequest.of(Math.min(pageable.getPageNumber(), Integer.MAX_VALUE / size), size);
    }

    // 이전/다음 링크: 값이 있는 필터만 그대로 싣는다
    private String pageUrl(MemberSearchRequest request, int page, int size) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromPath(MEMBERS_PATH);
        if (request.keyword() != null && !request.keyword().isBlank()) {
            builder.queryParam("keyword", request.keyword());
        }
        if (request.loginType() != null) {
            builder.queryParam("loginType", request.loginType().name());
        }
        return builder.queryParam("page", page).queryParam("size", size).build().encode().toUriString();
    }

}
