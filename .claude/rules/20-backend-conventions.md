---
paths:
  - "backend/**"
---

# Backend Conventions

## Naming and style

- Naming: 약어를 쓰지 않는다(`id`, `url`, `dto` 제외). 이름은 의도를 드러내는 영어로 짓는다.
- Style: 들여쓰기 4칸, 줄 길이 120. 포매터 플러그인은 아직 도입하지 않고 IDE 기본을 따른다.
- Comments: 주석과 Javadoc은 한국어, 식별자는 영어.

## Entity

- Base: 모든 엔티티는 `BaseEntity`를 상속한다.
- Table: `@Table(name = "...")`를 반드시 명시한다. 테이블명은 snake_case 단수형이다(`member`, `call_session`).
- Primary key: `@Id @GeneratedValue @UuidGenerator(style = UuidGenerator.Style.VERSION_7) UUID id`는 `BaseEntity`에 정의한다. 순번 ID를 쓰지 않는다(공유 링크 노출 대비).
- Enum: `@Enumerated(EnumType.STRING)`만 사용한다. `ORDINAL`은 쓰지 않는다.
- Lombok: 엔티티에 `@Getter`, `@Setter`, `@NoArgsConstructor(access = AccessLevel.PROTECTED)`, `@Builder`를 허용한다. `@Data`는 금지한다.
- State change: 상태 변경은 의도가 드러나는 도메인 메서드로 표현한다. `@Setter`가 허용되어도 상태 필드는 setter로 바꾸지 않는다.
- State transition: 허용되는 전이 규칙은 상태 enum의 메서드(`canTransitionTo` 등)에 둔다. 서비스가 검증한 뒤 엔티티 메서드로 적용하고, 허용되지 않은 전이는 `CustomException(ErrorCode.STATE_CONFLICT)`로 거부한다. 전이 이력 테이블은 두지 않는다.
- Association: `@ManyToOne(fetch = LAZY)`만 쓴다. `@OneToMany`와 JPA cascade는 금지한다. 자식 목록은 자식 리포지토리에서 부모 기준으로 조회하고, 저장·삭제는 서비스가 명시적으로 호출한다. 마이그레이션 SQL의 DB 수준 `ON DELETE CASCADE`는 허용한다.
- Delete: soft delete를 쓴다. `BaseEntity`의 `deleted`(boolean)와 `deletedAt`(`Instant`)로 표현한다. 아래 "Soft delete"를 따른다.
- Location: 엔티티는 `core`에 둔다.

## Soft delete

- Column: `BaseEntity`에 `deleted boolean not null default false`와 `deleted_at timestamptz`(null이면 삭제되지 않음)를 둔다.
- Management: 삭제는 `BaseEntity`의 도메인 메서드가 `deleted = true`와 `deletedAt`을 함께 기록한다. 시각은 `Clock` 기준이며, `createdAt`/`updatedAt`은 기존대로 JPA Auditing이 채운다.
- Filter: `@SQLRestriction`, `@SQLDelete`, `@Where` 같은 어노테이션 필터는 쓰지 않는다. 조회는 리포지토리 메서드에서 `deleted = false` 조건을 명시한다(예: `findByIdAndDeletedFalse`).
- Unique: UNIQUE 제약은 활성 행에만 걸도록 partial unique index(`create unique index ... where deleted = false`)로 만든다.
- Exception: 로그성·이력성 데이터처럼 soft delete가 맞지 않는 도메인은 해당 도메인에서 따로 정하고 사유를 남긴다.
- Purge: 개인정보 삭제 요구 등 실제 파기가 필요하면 soft delete와 별도 절차로 정한다.

## DTO and mapping

- DTO: Java `record`를 우선한다. `application/dto/request`, `application/dto/response`에 둔다.
- Class DTO: 상속이나 역직렬화 제약처럼 `record`로 어려운 경우에만 `class`를 쓰고, 이때 Lombok을 허용한다(`@Data`는 제외).
- Exposure: 엔티티를 API 응답으로 직접 노출하지 않는다.
- Mapping: 수동 매핑(`XxxResponse.from(entity)`)을 쓴다. MapStruct는 도입하지 않으며, 도입하더라도 생성 코드를 커밋하지 않는다.

## Admin API

- Path: 관리자 전용 엔드포인트는 `/api/admin/<복수형-kebab-case>`에 두고 컨트롤러(또는 메서드)에 `@PreAuthorize("hasRole('ADMIN')")`를 선언한다. 일반 사용자는 403 `ACCESS_DENIED`다.

## Repository and service

- Repository: 리포지토리 인터페이스(`JpaRepository`)는 `core`에 둔다. QueryDSL 등 구현체는 `infrastructure`에 둔다.
- Service: 서비스는 `application/service`에 둔다. 인터페이스를 미리 분리하지 않는다. 도메인당 하나를 기본으로 하고, 비대해지면 `XxxQueryService`와 `XxxCommandService`로 나눈다.
- Transaction: `@Transactional`은 클래스가 아닌 메서드 단위로 붙인다. 조회 메서드는 `readOnly = true`다.
- Injection: 생성자 주입(`@RequiredArgsConstructor`)만 쓴다. 필드 주입은 쓰지 않는다.

## Error handling

- ErrorCode: `common.core.exception.ErrorCode`는 중앙 enum 하나다(`httpStatus`, 한국어 `message`). 도메인 코드는 같은 enum에 도메인별 주석 섹션으로 추가한다.
- Exception: 비즈니스 오류는 `CustomException`으로 던진다. 생성자는 `(ErrorCode)`, `(ErrorCode, Throwable)` 두 가지뿐이고 메시지는 `ErrorCode`의 것을 쓴다. 도메인별 예외 클래스를 만들지 않는다.
- Response: `GlobalExceptionHandler`(`@RestControllerAdvice`)가 `ErrorResponse`로 변환한다. 본문은 `{ "errorCode": "<enum 이름>", "errorMessage": "<한국어 메시지>" }` 두 필드뿐이며, HTTP 상태는 응답 상태 줄에만 담는다. `ProblemDetail`은 쓰지 않는다. 성공 응답은 DTO를 그대로 반환한다(envelope 없음).
- ErrorResponse: `common.application.exception`에 둔다(DTO 패키지 규칙의 의도된 예외). Spring의 `org.springframework.web.ErrorResponse`와 이름이 같으므로 import를 혼동하지 않는다.
- Handler: `ResponseEntityExceptionHandler`를 상속하지 않는다(`ProblemDetail` 본문 방지).
- Validation: 검증 어노테이션의 `message`는 한국어로 쓴다.
- Never: 예외를 조용히 삼키지 않는다. 사용자에게 내부 정보(스택, SQL)를 노출하지 않는다.

## Logging

- Logger: `@Slf4j`를 쓴다. `System.out`, `printStackTrace`는 쓰지 않는다.
- Level: 예상된 `CustomException`의 4xx는 WARN(스택 없음), 5xx와 예상 못 한 예외는 ERROR와 스택이다(원인은 서버 로그에만 남긴다).
- Secret: 시크릿 설정값은 로그에 남기지 않는다.

## Time

- Clock: 현재 시각은 `Clock` 빈을 주입해서 사용한다(`Instant.now(clock)`). `Instant.now()`, `LocalDateTime.now()`, `System.currentTimeMillis()` 직접 호출은 금지한다.
- Storage: 저장은 `Instant` + PostgreSQL `timestamptz`.
- API: ISO-8601 UTC(`...Z`)로 직렬화한다. 한국 시간 변환은 클라이언트가 한다.
- Local rules: 야간 판정처럼 한국 시간 규칙이 필요하면 `ZoneId` 빈(`Asia/Seoul`)을 사용한다.

## Database and Flyway

- Naming: snake_case, 단수 테이블, PK 컬럼 `id`(uuid), 시각 컬럼 `created_at`/`updated_at`(`timestamptz`), soft delete 컬럼 `deleted`(boolean)/`deleted_at`(`timestamptz`).
- Constraints: FK 제약과 인덱스는 마이그레이션 SQL에 명시한다.
- Schema: `spring.jpa.hibernate.ddl-auto`는 `validate`(dev/prod 모두). 스키마는 Flyway로만 바꾼다.
- File name: `src/main/resources/db/migration/V{yyyyMMdd}_{HHmmss}__{snake_case_설명}.sql` (예: `V20260921_103000__create_member_table.sql`).
- Rules: 적용된 마이그레이션은 수정하지 않는다. `out-of-order`를 켜지 않는다. 늦게 머지되는 브랜치는 rebase 후 파일명의 타임스탬프를 갱신한다.
- Check: `scripts/sql/check_flyway_filenames.sh`로 파일명 규칙을 검증한다.

## Configuration

- `application.yml`: git 추적, 공통 설정만 둔다. 시크릿 값은 넣지 않는다.
- `application-dev.yml`, `application-prod.yml`: gitignore. 로컬/운영 실제 값이다. `.env`는 쓰지 않는다.
- Properties: 설정값은 `@Value`가 아니라 `@ConfigurationProperties`로 바인딩한다. 클래스는 각 도메인 `infrastructure/properties`에 둔다.
- Keys: 새 설정 키를 추가하면 `application.yml` 주석과 `70-secrets-and-env.md`의 키 목록을 함께 갱신한다.

## Spring Boot 4 notes

- Web starter는 `spring-boot-starter-webmvc`이다(`-web` 아님).
- Flyway는 `spring-boot-starter-flyway` + `flyway-database-postgresql`을 쓴다(`flyway-core` 단독은 자동 설정되지 않는다).
- JSON은 Jackson 3(`tools.jackson`)이다. 패키지 이름이 이전 버전과 다르다.
- 가상 스레드는 `spring.threads.virtual.enabled: true`로 켠다.
