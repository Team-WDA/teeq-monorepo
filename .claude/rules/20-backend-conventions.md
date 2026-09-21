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
- Enum: `@Enumerated(EnumType.STRING)`만 사용한다.
- Lombok: 엔티티에만 `@Getter`, `@NoArgsConstructor(access = AccessLevel.PROTECTED)`, `@Builder`를 허용한다. `@Data`, `@Setter`는 금지한다.
- State change: 상태 변경은 의도가 드러나는 도메인 메서드로 표현한다.
- Location: 엔티티는 `core`에 둔다.

## DTO and mapping

- DTO: Java `record`. `application/dto/request`, `application/dto/response`에 둔다.
- Exposure: 엔티티를 API 응답으로 직접 노출하지 않는다.
- Mapping: 수동 매핑(`XxxResponse.from(entity)`)을 쓴다. MapStruct는 도입하지 않으며, 도입하더라도 생성 코드를 커밋하지 않는다.
- Lombok: DTO에는 Lombok을 쓰지 않는다(record 사용).

## Repository and service

- Repository: 리포지토리 인터페이스(`JpaRepository`)는 `core`에 둔다. QueryDSL 등 구현체는 `infrastructure`에 둔다.
- Service: 서비스는 `application/service`에 두고 트랜잭션 경계를 가진다. 인터페이스를 미리 분리하지 않는다.

## Error handling

- ErrorCode: 도메인별 enum(`XxxErrorCode`)이 `common.core.exception.ErrorCode`를 구현한다. 하나의 거대한 enum을 만들지 않는다.
- Exception: 비즈니스 오류는 `BusinessException(ErrorCode)`로 던진다.
- Response: `GlobalExceptionHandler`가 `ProblemDetail`(RFC 9457)로 변환한다. 성공 응답은 DTO를 그대로 반환한다(envelope 없음).
- Never: 예외를 조용히 삼키지 않는다. 사용자에게 내부 정보(스택, SQL)를 노출하지 않는다.

## Time

- Clock: 현재 시각은 `Clock` 빈을 주입해서 사용한다(`Instant.now(clock)`). `Instant.now()`, `LocalDateTime.now()`, `System.currentTimeMillis()` 직접 호출은 금지한다.
- Storage: 저장은 `Instant` + PostgreSQL `timestamptz`.
- API: ISO-8601 UTC(`...Z`)로 직렬화한다. 한국 시간 변환은 클라이언트가 한다.
- Local rules: 야간 판정처럼 한국 시간 규칙이 필요하면 `ZoneId` 빈(`Asia/Seoul`)을 사용한다.

## Database and Flyway

- Naming: snake_case, 단수 테이블, PK 컬럼 `id`(uuid), 시각 컬럼 `created_at`/`updated_at`(`timestamptz`).
- Constraints: FK 제약과 인덱스는 마이그레이션 SQL에 명시한다.
- Schema: `spring.jpa.hibernate.ddl-auto`는 `validate`(dev/prod 모두). 스키마는 Flyway로만 바꾼다.
- File name: `src/main/resources/db/migration/V{yyyyMMdd}_{HHmmss}__{snake_case_설명}.sql` (예: `V20260921_103000__create_member_table.sql`).
- Rules: 적용된 마이그레이션은 수정하지 않는다. `out-of-order`를 켜지 않는다. 늦게 머지되는 브랜치는 rebase 후 파일명의 타임스탬프를 갱신한다.
- Check: `scripts/sql/check_flyway_filenames.sh`로 파일명 규칙을 검증한다.

## Configuration

- `application.yml`: git 추적, 공통 설정만 둔다. 시크릿 값은 넣지 않는다.
- `application-dev.yml`, `application-prod.yml`: gitignore. 로컬/운영 실제 값이다. `.env`는 쓰지 않는다.
- Properties: `@ConfigurationProperties` 클래스는 각 도메인 `infrastructure/properties`에 둔다.
- Keys: 새 설정 키를 추가하면 `application.yml` 주석과 `70-secrets-and-env.md`의 키 목록을 함께 갱신한다.

## Spring Boot 4 notes

- Web starter는 `spring-boot-starter-webmvc`이다(`-web` 아님).
- Flyway는 `spring-boot-starter-flyway` + `flyway-database-postgresql`을 쓴다(`flyway-core` 단독은 자동 설정되지 않는다).
- JSON은 Jackson 3(`tools.jackson`)이다. 패키지 이름이 이전 버전과 다르다.
- Testcontainers 2 모듈명은 `testcontainers-postgresql`, `testcontainers-junit-jupiter`이다.
- 가상 스레드는 `spring.threads.virtual.enabled: true`로 켠다.
