package kr.co.teeq.api.auth.application.handler;

import kr.co.teeq.api.auth.core.entity.RefreshToken;
import kr.co.teeq.api.auth.core.repository.RefreshTokenRepository;
import kr.co.teeq.api.member.core.event.HandlesMemberDeletion;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 회원 삭제 시 리프레시 토큰을 hard delete 한다. 회원당 하나만 두는 일반 unique 제약이 있어 soft delete 행을 남기지 않는다.
 */
@Component
@RequiredArgsConstructor
@HandlesMemberDeletion(entities = RefreshToken.class)
public class RefreshTokenMemberDeletionHandler {

    private final RefreshTokenRepository refreshTokenRepository;

    @EventListener
    public void handle(MemberDeletedEvent event) {
        refreshTokenRepository.deleteByMemberId(event.memberId());
    }

}
