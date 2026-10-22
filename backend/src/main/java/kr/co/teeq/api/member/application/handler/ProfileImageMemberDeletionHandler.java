package kr.co.teeq.api.member.application.handler;

import java.time.Clock;
import kr.co.teeq.api.member.core.entity.ProfileImage;
import kr.co.teeq.api.member.core.event.HandlesMemberDeletion;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import kr.co.teeq.api.member.core.repository.ProfileImageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 회원 삭제 시 프로필 이미지 행을 soft delete 한다. 저장소의 파일은 지우지 않는다.
 */
@Component
@RequiredArgsConstructor
@HandlesMemberDeletion(entities = ProfileImage.class)
public class ProfileImageMemberDeletionHandler {

    private final ProfileImageRepository profileImageRepository;
    private final Clock clock;

    @EventListener
    public void handle(MemberDeletedEvent event) {
        profileImageRepository.findByMemberIdAndDeletedFalse(event.memberId())
            .ifPresent(profileImage -> profileImage.delete(clock));
    }

}
