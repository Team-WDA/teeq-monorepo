package kr.co.teeq.api.member.core.repository;

import java.util.Locale;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import org.springframework.data.jpa.domain.Specification;

/**
 * 관리자 회원 목록 조회에 쓰는 검색 조건.
 */
public final class MemberSpecifications {

    private static final char LIKE_ESCAPE_CHARACTER = '\\';

    private MemberSpecifications() {
    }

    public static Specification<Member> notDeleted() {
        return (root, query, builder) -> builder.isFalse(root.<Boolean>get("deleted"));
    }

    // 이메일 또는 닉네임에 키워드가 포함된 회원(대소문자 무시).
    public static Specification<Member> emailOrNicknameContaining(String keyword) {
        return (root, query, builder) -> {
            String pattern = toLikePattern(keyword);
            return builder.or(
                builder.like(builder.lower(root.<String>get("email")), pattern, LIKE_ESCAPE_CHARACTER),
                builder.like(builder.lower(root.<String>get("nickname")), pattern, LIKE_ESCAPE_CHARACTER));
        };
    }

    public static Specification<Member> ofLoginType(LoginType loginType) {
        return (root, query, builder) -> builder.equal(root.get("loginType"), loginType);
    }

    // 키워드를 공백 제거 후 소문자로 바꾸고 이스케이프해 부분 일치용 LIKE 패턴(%키워드%)으로 만든다
    public static String toLikePattern(String keyword) {
        return "%" + escapeLikePattern(keyword.trim().toLowerCase(Locale.ROOT)) + "%";
    }

    // LIKE 패턴의 특수 문자(\, %, _)를 리터럴로 취급하도록 이스케이프한다
    public static String escapeLikePattern(String keyword) {
        return keyword
            .replace("\\", "\\\\")
            .replace("%", "\\%")
            .replace("_", "\\_");
    }

}
