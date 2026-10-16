# Testing And Verification

## Test strategy

- 꼭 필요한 부분만 테스트한다. 핵심 도메인 로직(상태 전이, 한도 계산, 멱등 처리 등)은 테스트를 먼저 쓴다(RED → GREEN → REFACTOR). 단순 CRUD, 매핑, 설정 클래스는 의무가 아니다. 전역 규칙(TDD 필수, 커버리지 80%)은 이 프로젝트에서 적용하지 않고 커버리지 게이트도 두지 않는다.
- BE: JUnit 6, Mockito. 서비스·도메인은 DB 없이 단위 테스트, 웹 계층(예외 처리기, 보안, 직렬화)은 `@WebMvcTest` 슬라이스 또는 `standaloneSetup`. Testcontainers, H2, DB가 필요한 `@SpringBootTest`는 쓰지 않는다.
- Flyway 마이그레이션과 JPA 매핑은 자동 테스트가 없다. 로컬 DB 실기동(`ddl-auto: validate`)으로 확인한다.
- 시간이 결과에 영향을 주면 고정된 `Clock`을 주입한다. `LayerDependencyTest`를 완화하거나 삭제하지 않는다.
- FE: 도메인 로직과 provider를 테스트하고 핵심 화면만 위젯 테스트를 쓴다. `flutter analyze`는 항상 통과해야 한다.

## Commands

- BE: `cd backend && ./gradlew build` (일부만: `./gradlew test --tests '*ClassName'`)
- FE: `cd frontend && dart run build_runner build && flutter analyze && flutter test`
- Flyway 파일명: `scripts/sql/check_flyway_filenames.sh`
- PR 전에 변경 범위에 해당하는 위 명령을 통과시킨다.

## Evidence

- 완료 보고에는 실행한 명령과 실제 결과를 함께 적는다. 실행하지 못한 검증(로컬 DB 실기동, 수동 호출, 동시성 등)은 못 했다고 명시한다.

## Failure handling

- 테스트가 실패하면 구현을 고친다. 테스트가 틀린 경우에만 테스트를 바꾼다.
- Mockito로 확인할 수 없는 동작(잠금, flush 순서, 제약)은 선언 확인 테스트나 실기동으로 보완하고 미검증이면 보고서에 적는다.
