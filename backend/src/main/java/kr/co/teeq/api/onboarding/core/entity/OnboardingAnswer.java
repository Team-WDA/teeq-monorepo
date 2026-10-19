package kr.co.teeq.api.onboarding.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 온보딩 답변 1건. 선택지 하나당 한 행이며, 다시 설정할 때는 회원의 기존 행을 지우고 새로 넣는다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "onboarding_answer")
public class OnboardingAnswer extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Enumerated(EnumType.STRING)
    @Column(name = "question_code", nullable = false, length = 50)
    private OnboardingQuestion question;

    @Enumerated(EnumType.STRING)
    @Column(name = "option_code", nullable = false, length = 50)
    private OnboardingOption option;

    private OnboardingAnswer(Member member, OnboardingQuestion question, OnboardingOption option) {
        this.member = member;
        this.question = question;
        this.option = option;
    }

    public static OnboardingAnswer of(Member member, OnboardingQuestion question, OnboardingOption option) {
        return new OnboardingAnswer(member, question, option);
    }

}
