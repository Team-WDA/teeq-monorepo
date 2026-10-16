# Team Conventions

## Naming

- 약어를 쓰지 않는다(`id`, `url`, `dto` 제외). 이름은 의도를 드러내는 영어로 짓는다.
- 클래스는 PascalCase, DTO는 record, 테이블은 snake_case 단수형, FE 모델 필드는 BE 응답 필드(camelCase)와 맞춘다.
- 주석과 Javadoc은 한국어, 식별자는 영어.

## Code style

- BE: 들여쓰기 4칸, 줄 길이 120. 생성자 주입(`@RequiredArgsConstructor`)만 쓰고 필드 주입은 쓰지 않는다. `@Data` 금지. `@Transactional`은 메서드 단위로 붙이고 조회는 `readOnly = true`.
- 엔티티: `BaseEntity` 상속(UUID v7 PK, `createdAt`/`updatedAt`, soft delete `deleted`/`deletedAt`), `@Table` 명시, enum은 `EnumType.STRING`, 연관은 `@ManyToOne(LAZY)`만 쓰고 `@OneToMany`와 cascade는 금지, 상태 변경은 도메인 메서드로 하며 허용 전이는 상태 enum의 `canTransitionTo`에 둔다(위반 시 `STATE_CONFLICT`).
- soft delete 조회 필터(`deleted = false`)는 리포지토리 메서드에서 명시한다(`@SQLRestriction` 금지). UNIQUE는 활성 행에만 걸리게 partial unique index로 만든다.
- 시간: `Clock` 주입 + `Instant`(저장은 `timestamptz`, API는 ISO-8601 UTC). `Instant.now()`, `LocalDateTime.now()` 직접 호출 금지. 한국 시간 규칙은 `ZoneId`(`Asia/Seoul`) 빈을 쓴다.
- 에러: 중앙 `ErrorCode` enum + `CustomException`, 응답은 `{ "errorCode", "errorMessage" }` 두 필드. 도메인별 예외 클래스를 만들지 않는다. 예외를 삼키지 않고 내부 정보(스택, SQL)를 노출하지 않는다.
- 로그: `@Slf4j`. 예상된 4xx는 WARN(스택 없음), 5xx는 ERROR와 스택. `System.out`·`printStackTrace`·시크릿 값 로깅 금지.
- DB: 스키마는 Flyway로만 바꾼다(`ddl-auto: validate`). 파일명 `V{yyyyMMdd}_{HHmmss}__{snake_case}.sql`, 적용된 마이그레이션은 수정하지 않는다.
- 설정: `@Value`가 아니라 `@ConfigurationProperties`(도메인 `infrastructure/properties`)로 바인딩하고 필수 값이 비면 기동 시 실패시킨다. `application.yml`은 공통 설정만(값 없음), 실제 값은 `application-{dev,prod}.yml`(gitignore).
- FE: `flutter_lints`와 `dart format`, `print` 금지, 모델은 freezed + json_serializable(생성 코드 `*.g.dart`·`*.freezed.dart`는 커밋하지 않음), 환경값은 `--dart-define-from-file`로 주입하고 키 정의는 `AppConfig` 한 곳에 둔다.
- Spring Boot 4 주의: Web starter는 `spring-boot-starter-webmvc`, Flyway는 `spring-boot-starter-flyway`, JSON은 Jackson 3(`tools.jackson`).

## Responsibility separation

- controller는 요청·응답 변환과 서비스 호출만, 비즈니스 로직은 service·도메인 메서드에 둔다. 서비스는 도메인당 하나를 기본으로 하고 비대해지면 Query/Command로 나눈다.
- FE 위젯에는 비즈니스 로직을 두지 않고 provider·도메인에 둔다. 서버 상태는 Riverpod provider로 다루고 별도 스토어에 복제하지 않는다.

## Secrets

- 클라이언트에 넣은 값은 추출할 수 있다고 가정한다. `config/*.json`에는 API base URL과 공개 클라이언트 ID만 둔다. LLM/STT/TTS 키 같은 서버 시크릿은 클라이언트에 넣지 않는다.
- 시크릿 파일은 읽을 수 있어도 값을 커밋·로그·PR·대화에 노출하지 않는다. 값이 필요한 작업은 키 이름과 위치만 만들고 값은 사용자가 채운다. 노출되면 즉시 알리고 폐기(rotate)한다.
- 새 설정 키를 추가하면 `application.yml` 주석 또는 `AppConfig`와 README 안내를 함께 갱신한다.

## Review expectations

- 확인 항목: 계층·의존 방향, 트랜잭션 경계, 동시성(unique 위반·잠금), 시크릿 노출, 에러 코드와 Docs 일치, 테스트가 핵심 도메인 로직을 덮는지.
- block 기준: 시크릿 노출, force git, `LayerDependencyTest` 완화, 적용된 마이그레이션 수정, 보안 경로 누락.
