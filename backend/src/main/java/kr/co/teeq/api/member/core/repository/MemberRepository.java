package kr.co.teeq.api.member.core.repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface MemberRepository extends JpaRepository<Member, UUID>, JpaSpecificationExecutor<Member> {

    Optional<Member> findByIdAndDeletedFalse(UUID id);

    Optional<Member> findByEmailAndDeletedFalse(String email);

    Optional<Member> findByLoginTypeAndSocialUserIdAndDeletedFalse(LoginType loginType, String socialUserId);

    boolean existsByEmailAndDeletedFalse(String email);

    Optional<Member> findByNicknameIgnoreCaseAndDeletedFalse(String nickname);

    // 활성(deleted = false) 회원 수. 가입 완료(닉네임) 여부는 묻지 않는다(관리자 홈용)
    long countByDeletedFalse();

    // 생성 시각이 createdAtFrom 이상인 활성(deleted = false) 회원 수(관리자 홈의 오늘 가입)
    long countByCreatedAtGreaterThanEqualAndDeletedFalse(Instant createdAtFrom);

    // 닉네임이 있는(가입 완료) 활성(deleted = false) 회원 수(관리자 홈의 온보딩 완료율 분모)
    long countByNicknameIsNotNullAndDeletedFalse();

    // 생성 시각 내림차순 최근 활성(deleted = false) 회원 5명(관리자 홈의 최근 가입)
    List<Member> findTop5ByDeletedFalseOrderByCreatedAtDesc();

}
