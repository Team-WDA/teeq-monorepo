package kr.co.teeq.api.admin.application.view;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

/**
 * 관리자 화면별 탭 줄 구성(AdminTab 목록)을 만드는 정적 팩토리 모음.
 * 화면마다 탭 목록을 돌려주는 메서드를 해당 화면을 조립할 때 추가한다.
 */
public final class AdminTabs {

    public static final String MEMBER_OVERVIEW_KEY = "overview";
    public static final String MEMBER_CALLS_KEY = "calls";
    public static final String MEMBER_CALL_USAGES_KEY = "call-usages";
    public static final String MEMBER_CALL_BONUSES_KEY = "call-bonuses";
    public static final String MEMBER_ONBOARDING_SUBMISSIONS_KEY = "onboarding-submissions";
    public static final String MEMBER_BUG_REPORTS_KEY = "bug-reports";
    public static final String MEMBER_FEEDBACKS_KEY = "feedbacks";

    public static final String CALLS_LIST_KEY = "list";
    public static final String CALLS_USAGES_KEY = "usages";

    private static final String SETTINGS_PATH = "/admin/settings/";
    private static final String MEMBERS_PATH = "/admin/members/";

    private AdminTabs() {
    }

    // 회원 허브 탭 줄. 개요가 첫 탭이고 나머지는 회원 경로 아래 하위 경로를 쓴다
    public static List<AdminTab> memberHub(UUID memberId) {
        String memberPath = MEMBERS_PATH + memberId;
        return List.of(
            new AdminTab(MEMBER_OVERVIEW_KEY, "개요", memberPath),
            new AdminTab(MEMBER_CALLS_KEY, "통화 기록", memberPath + "/calls"),
            new AdminTab(MEMBER_CALL_USAGES_KEY, "통화 사용량", memberPath + "/call-usages"),
            new AdminTab(MEMBER_CALL_BONUSES_KEY, "추가 통화 시간", memberPath + "/call-bonuses"),
            new AdminTab(MEMBER_ONBOARDING_SUBMISSIONS_KEY, "온보딩 응답", memberPath + "/onboarding-submissions"),
            new AdminTab(MEMBER_BUG_REPORTS_KEY, "버그 제보", memberPath + "/bug-reports"),
            new AdminTab(MEMBER_FEEDBACKS_KEY, "피드백", memberPath + "/feedbacks"));
    }

    // 통화 기록 탭 줄. 목록과 사용량 집계
    public static List<AdminTab> calls() {
        return List.of(
            new AdminTab(CALLS_LIST_KEY, "목록", "/admin/calls"),
            new AdminTab(CALLS_USAGES_KEY, "사용량 집계", "/admin/calls/usages"));
    }

    // 서비스 설정 탭 줄. 탭 키는 그룹의 경로 조각과 같다
    public static List<AdminTab> settings() {
        return Arrays.stream(SettingGroup.values())
            .map(group -> new AdminTab(group.path(), group.label(), SETTINGS_PATH + group.path()))
            .toList();
    }

}
