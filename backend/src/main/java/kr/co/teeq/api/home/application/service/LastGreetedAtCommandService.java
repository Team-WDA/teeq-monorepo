package kr.co.teeq.api.home.application.service;

import java.time.Clock;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 회원의 마지막 홈 한마디 시각만 짧은 트랜잭션으로 기록한다. AI 서버 호출은 이 트랜잭션 밖({@link GreetingService})에서 한다.
 */
@Service
@RequiredArgsConstructor
public class LastGreetedAtCommandService {

    private final MemberRepository memberRepository;
    private final Clock clock;

    // 컨트롤러가 넘긴 회원은 분리 상태라 id로 다시 조회한 엔티티를 수정한다
    @Transactional
    public void record(UUID memberId) {
        memberRepository.findByIdAndDeletedFalse(memberId)
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND))
            .markGreeted(clock.instant());
    }

}
