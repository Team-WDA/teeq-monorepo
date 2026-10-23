package kr.co.teeq.api.auth.application.handler;

import kr.co.teeq.api.auth.core.port.FirebaseUserDeletionPort;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * 회원 삭제 트랜잭션이 커밋된 뒤 Firebase 사용자를 지운다. 외부 호출이라 롤백 보장 대상이 아니므로
 * {@code @HandlesMemberDeletion} 핸들러가 아니다(해당 핸들러는 트랜잭션 리스너와 비동기를 쓸 수 없다).
 * 요청 스레드에서 동기로 실행하며, 실패해도 탈퇴는 이미 끝났으므로 예외를 삼키고 ERROR 로그만 남긴다(재시도 없음).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class FirebaseUserDeletionListener {

    private final MemberRepository memberRepository;
    private final FirebaseUserDeletionPort firebaseUserDeletionPort;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handle(MemberDeletedEvent event) {
        String firebaseUid = null;
        try {
            // soft delete된 행도 id로 읽힌다(조회 필터는 리포지토리 메서드에서만 건다)
            Member member = memberRepository.findById(event.memberId()).orElse(null);
            if (member == null) {
                log.error("Firebase 사용자 삭제 대상 회원을 찾을 수 없음: memberId={}", event.memberId());
                return;
            }
            firebaseUid = member.getFirebaseUid();
            firebaseUserDeletionPort.delete(firebaseUid);
        } catch (Exception exception) {
            log.error("Firebase 사용자 삭제 실패: memberId={}, firebaseUid={}", event.memberId(), firebaseUid, exception);
        }
    }

}
