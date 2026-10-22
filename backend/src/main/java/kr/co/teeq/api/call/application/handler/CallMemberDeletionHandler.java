package kr.co.teeq.api.call.application.handler;

import java.time.Clock;
import java.time.Instant;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.entity.CallBonus;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.call.core.repository.CallBonusRepository;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.event.HandlesMemberDeletion;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 회원 삭제 시 통화 기록과 통화 보너스를 soft delete 한다. 1회 통화 한도 안에 시작된 진행 중 통화가 있으면 거부한다.
 * 한도를 넘긴 활성 행(앱 비정상 종료로 남은 행)은 상태 전이({@code expire})를 거치지 않고 {@code delete(clock)}로
 * 바로 soft delete 한다(의도). 이후 insert가 없으므로 flush는 필요 없다.
 */
@Component
@RequiredArgsConstructor
@HandlesMemberDeletion(entities = {CallHistory.class, CallBonus.class})
public class CallMemberDeletionHandler {

    private final CallHistoryRepository callHistoryRepository;
    private final CallBonusRepository callBonusRepository;
    private final SettingConfigService settingConfigService;
    private final Clock clock;

    @EventListener
    public void handle(MemberDeletedEvent event) {
        long maxSecondsPerSession = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION);
        Instant activeCutoff = clock.instant().minusSeconds(maxSecondsPerSession);
        if (callHistoryRepository.existsByMemberIdAndStatusInAndStartedAtGreaterThanAndDeletedFalse(
            event.memberId(), CallStatus.ACTIVE_STATUSES, activeCutoff)) {
            throw new CustomException(ErrorCode.MEMBER_HAS_ACTIVE_CALL);
        }
        callHistoryRepository.findByMemberIdAndDeletedFalse(event.memberId())
            .forEach(callHistory -> callHistory.delete(clock));
        callBonusRepository.findByMemberIdAndDeletedFalse(event.memberId())
            .forEach(callBonus -> callBonus.delete(clock));
    }

}
