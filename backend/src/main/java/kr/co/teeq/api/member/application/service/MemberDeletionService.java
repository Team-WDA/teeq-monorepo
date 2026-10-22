package kr.co.teeq.api.member.application.service;

import java.time.Clock;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MemberDeletionService {

    private final MemberRepository memberRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final Clock clock;

    // 회원을 soft delete 하고 삭제 이벤트를 발행한다. 핸들러가 같은 트랜잭션에서 실행되어 예외 시 전체가 롤백된다
    @Transactional
    public void delete(UUID memberId) {
        Member member = memberRepository.findByIdAndDeletedFalse(memberId)
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));
        member.delete(clock);
        eventPublisher.publishEvent(new MemberDeletedEvent(memberId));
    }

}
