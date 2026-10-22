package kr.co.teeq.api.member.core.event;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 삭제 핸들러가 정리하는 엔티티를 선언한다. 누락 검증 테스트가 이 값을 읽어, 회원을 참조하는 엔티티가
 * 어느 핸들러에도 선언되지 않으면 빌드를 실패시킨다.
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface HandlesMemberDeletion {

    Class<?>[] entities();

}
