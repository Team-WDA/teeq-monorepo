package kr.co.teeq.api.call.application.service;

import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.request.CallBonusGrantRequest;
import kr.co.teeq.api.call.application.dto.response.CallBonusResponse;
import kr.co.teeq.api.call.core.entity.CallBonus;
import kr.co.teeq.api.call.core.repository.CallBonusRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Admin;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CallBonusService {

    private final CallBonusRepository callBonusRepository;
    private final MemberRepository memberRepository;
    private final AdminRepository adminRepository;
    private final Clock clock;
    private final ZoneId koreaZoneId;

    @Transactional
    public CallBonusResponse grant(UUID adminId, UUID memberId, CallBonusGrantRequest request) {
        Admin grantedBy = findAdmin(adminId);
        Member member = memberRepository.findByIdAndDeletedFalse(memberId)
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        // 추가 시간은 해당 날짜(KST)에만 유효하므로 이미 지난 날짜에는 부여할 수 없다
        LocalDate today = clock.instant().atZone(koreaZoneId).toLocalDate();
        LocalDate bonusDate = request.bonusDate() == null ? today : request.bonusDate();
        if (bonusDate.isBefore(today)) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }

        CallBonus callBonus = CallBonus.grant(member, bonusDate, request.seconds(), request.reason(),
            grantedBy);
        return CallBonusResponse.from(callBonusRepository.save(callBonus));
    }

    // 취소된 행도 포함해 부여 이력을 최신순으로 돌려준다
    @Transactional(readOnly = true)
    public List<CallBonusResponse> getAll(UUID memberId) {
        return callBonusRepository.findByMemberIdOrderByCreatedAtDesc(memberId).stream()
            .map(CallBonusResponse::from)
            .toList();
    }

    @Transactional
    public void cancel(UUID adminId, UUID memberId, UUID callBonusId) {
        Admin canceledBy = findAdmin(adminId);
        CallBonus callBonus = callBonusRepository.findByIdAndMemberIdAndDeletedFalse(callBonusId, memberId)
            .orElseThrow(() -> new CustomException(ErrorCode.CALL_BONUS_NOT_FOUND));
        callBonus.cancel(canceledBy, clock);
    }

    // 세션의 관리자는 분리 상태이므로 id로 다시 조회한다
    private Admin findAdmin(UUID adminId) {
        return adminRepository.findByIdAndDeletedFalse(adminId)
            .orElseThrow(() -> new CustomException(ErrorCode.ADMIN_NOT_FOUND));
    }

}
