package kr.co.teeq.api.admin.application.view;

import kr.co.teeq.api.feedback.core.constant.AwkwardMoment;
import kr.co.teeq.api.feedback.core.constant.PreviousCallRecall;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;
import kr.co.teeq.api.feedback.core.constant.StartReason;

/**
 * 관리자 화면에 보여 주는 피드백 선택지의 한국어 라벨. 앱 화면 문구를 관리자용 평서형으로 옮겼다.
 * switch 식으로 enum 전수를 처리해 값이 추가되면 컴파일 오류가 나게 한다.
 */
public final class FeedbackDisplayLabel {

    private FeedbackDisplayLabel() {
    }

    public static String revisitIntention(RevisitIntention revisitIntention) {
        return switch (revisitIntention) {
            case YES -> "다시 이용하고 싶음";
            case NEUTRAL -> "잘 모르겠음";
            case NO -> "이용하고 싶지 않음";
        };
    }

    public static String previousCallRecall(PreviousCallRecall previousCallRecall) {
        return switch (previousCallRecall) {
            case REMEMBERED -> "기억함";
            case UNSURE -> "잘 모르겠음";
            case NO -> "기억하지 못함";
        };
    }

    public static String awkwardMoment(AwkwardMoment awkwardMoment) {
        return switch (awkwardMoment) {
            case CUT -> "말이 끊김";
            case SLOW -> "답이 늦음";
            case CONTEXT -> "맥락이 안 맞음";
            case REPEAT -> "같은 말 반복";
            case NONE -> "없음";
        };
    }

    // 앱은 캐릭터 이름을 넣어 보여 주지만 관리자 화면은 이름 없이 "캐릭터"로 쓴다
    public static String startReason(StartReason startReason) {
        return switch (startReason) {
            case NEED_TO_TALK -> "누군가와 이야기하고 싶어서";
            case WANT_TO_CONFIDE -> "고민을 털어놓고 싶어서";
            case BORED_OR_LONELY -> "심심하거나 외로워서";
            case CURIOUS_ABOUT_CHARACTER -> "캐릭터가 궁금해서";
            case TESTING_SERVICE -> "서비스를 테스트하려고";
            case OTHER -> "기타";
        };
    }

}
