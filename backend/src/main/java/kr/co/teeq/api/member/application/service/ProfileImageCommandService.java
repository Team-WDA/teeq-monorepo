package kr.co.teeq.api.member.application.service;

import java.time.Clock;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.entity.ProfileImage;
import kr.co.teeq.api.member.core.repository.ProfileImageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 프로필 사진 행의 교체와 삭제를 한 트랜잭션으로 처리한다. 파일 입출력은 이 트랜잭션 밖({@link ProfileImageService})에서 한다.
 */
@Service
@RequiredArgsConstructor
public class ProfileImageCommandService {

    // 마이그레이션의 partial unique index 이름과 같아야 한다. 동시 교체로 인덱스가 먼저 걸린 경우에만 409로 바꾼다
    private static final String MEMBER_ACTIVE_INDEX_NAME = "uq_profile_image_member_active";

    private final ProfileImageRepository profileImageRepository;
    private final Clock clock;

    // 활성 행 unique 인덱스 때문에 이전 행의 soft delete를 먼저 반영(flush)한 뒤 새 행을 저장한다
    @Transactional
    public void replace(Member member, String storageKey, String contentType, long fileSize) {
        profileImageRepository.findByMemberIdAndDeletedFalse(member.getId()).ifPresent(previous -> {
            previous.delete(clock);
            profileImageRepository.saveAndFlush(previous);
        });
        try {
            profileImageRepository.saveAndFlush(ProfileImage.of(member, storageKey, contentType, fileSize));
        } catch (DataIntegrityViolationException exception) {
            String message = String.valueOf(exception.getMostSpecificCause().getMessage());
            if (message.contains(MEMBER_ACTIVE_INDEX_NAME)) {
                throw new CustomException(ErrorCode.STATE_CONFLICT, exception);
            }
            throw exception;
        }
    }

    // 활성 사진이 없으면 아무것도 하지 않는다. 파일은 삭제하지 않는다
    @Transactional
    public void delete(Member member) {
        profileImageRepository.findByMemberIdAndDeletedFalse(member.getId())
            .ifPresent(image -> image.delete(clock));
    }

}
