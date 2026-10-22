package kr.co.teeq.api.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static org.assertj.core.api.Assertions.assertThat;

import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import jakarta.persistence.Entity;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import kr.co.teeq.api.member.core.event.HandlesMemberDeletion;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * 회원 삭제 핸들러 누락을 막는다. {@code Member}를 직접 참조하는 엔티티만 검사한다.
 * 피드백처럼 다른 엔티티({@code CallHistory})를 통해서만 닿는 엔티티는 범위 밖이며 해당 핸들러가 직접 선언한다.
 */
@AnalyzeClasses(packages = "kr.co.teeq.api", importOptions = ImportOption.DoNotIncludeTests.class)
class MemberDeletionHandlerCoverageTest {

    private static final String MEMBER_ENTITY_NAME = "kr.co.teeq.api.member.core.entity.Member";

    // 의도적으로 삭제 핸들러를 두지 않는 엔티티의 전체 이름. 항목을 넣을 때는 반드시 이유를 주석으로 적는다
    private static final Set<String> EXCLUDED_ENTITIES = Set.of(
        // 탈퇴한 회원이 남긴 제보도 원인 수정에 필요해 보존한다
        "kr.co.teeq.api.support.core.entity.BugReport");

    @ArchTest
    static void everyEntityReferencingMemberMustBeHandled(JavaClasses classes) {
        Set<String> handledEntities = classes.stream()
            .filter(javaClass -> javaClass.isAnnotatedWith(HandlesMemberDeletion.class))
            .flatMap(javaClass -> declaredEntities(javaClass).stream())
            .collect(Collectors.toSet());

        List<String> unhandledEntities = classes.stream()
            .filter(javaClass -> javaClass.isAnnotatedWith(Entity.class))
            .filter(javaClass -> !javaClass.getFullName().equals(MEMBER_ENTITY_NAME))
            .filter(javaClass -> javaClass.getFields().stream()
                .anyMatch(field -> field.getRawType().getFullName().equals(MEMBER_ENTITY_NAME)))
            .map(JavaClass::getFullName)
            .filter(entityName -> !handledEntities.contains(entityName))
            .filter(entityName -> !EXCLUDED_ENTITIES.contains(entityName))
            .sorted()
            .toList();

        assertThat(unhandledEntities)
            .as("Member를 참조하는데 @HandlesMemberDeletion에 선언되지 않은 엔티티")
            .isEmpty();
    }

    @ArchTest
    static void deletionHandlersMustResideInApplicationPackage(JavaClasses classes) {
        classes().that().areAnnotatedWith(HandlesMemberDeletion.class)
            .should().resideInAPackage("..application..")
            .allowEmptyShould(true)
            .check(classes);
    }

    // 핸들러가 삭제 이벤트를 동기로 받아야 삭제 트랜잭션과 함께 롤백된다
    @ArchTest
    static void deletionHandlersMustListenToMemberDeletedEvent(JavaClasses classes) {
        List<String> invalidHandlers = classes.stream()
            .filter(javaClass -> javaClass.isAnnotatedWith(HandlesMemberDeletion.class))
            .filter(javaClass -> javaClass.getMethods().stream().noneMatch(method ->
                method.isAnnotatedWith(EventListener.class)
                    && method.getRawParameterTypes().size() == 1
                    && method.getRawParameterTypes().get(0).isEquivalentTo(MemberDeletedEvent.class)))
            .map(JavaClass::getFullName)
            .sorted()
            .toList();

        assertThat(invalidHandlers)
            .as("MemberDeletedEvent를 받는 @EventListener 메서드가 없는 삭제 핸들러")
            .isEmpty();
    }

    @ArchTest
    static void deletionHandlersMustNotBeAsynchronous(JavaClasses classes) {
        List<String> asynchronousHandlers = classes.stream()
            .filter(javaClass -> javaClass.isAnnotatedWith(HandlesMemberDeletion.class))
            .filter(javaClass -> javaClass.isAnnotatedWith(TransactionalEventListener.class)
                || javaClass.isAnnotatedWith(Async.class)
                || javaClass.getMethods().stream().anyMatch(method ->
                    method.isAnnotatedWith(TransactionalEventListener.class) || method.isAnnotatedWith(Async.class)))
            .map(JavaClass::getFullName)
            .sorted()
            .toList();

        assertThat(asynchronousHandlers)
            .as("@TransactionalEventListener 또는 @Async를 쓰는 삭제 핸들러(롤백 보장이 깨진다)")
            .isEmpty();
    }

    private static Set<String> declaredEntities(JavaClass handlerClass) {
        JavaClass[] entities = (JavaClass[]) handlerClass.getAnnotationOfType(HandlesMemberDeletion.class.getName())
            .get("entities")
            .orElseThrow();
        return Arrays.stream(entities).map(JavaClass::getFullName).collect(Collectors.toSet());
    }

}
