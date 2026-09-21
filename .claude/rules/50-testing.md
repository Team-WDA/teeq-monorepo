# Testing

## Policy override

- 전역 규칙("TDD 필수, 커버리지 80%")은 이 프로젝트에서 적용하지 않고 이 문서를 따른다.
- Reason: MVP는 반복 통화 행동 검증이 목적이라 속도가 중요하지만, 상태 전이 같은 핵심 로직의 회귀는 비싸다.

## What to test first (TDD)

- 대상: 핵심 도메인 로직만 테스트를 먼저 작성한다(RED → GREEN → REFACTOR).
  - Memory 생성/사용, Call Session 상태 전이, Journey 공유/도착/도움 요청 상태 전이, Context 판정, 비용 집계
- 비대상: 단순 CRUD, 단순 매핑, 설정 클래스는 테스트 작성이 의무가 아니다.
- Coverage: 커버리지 게이트는 두지 않는다.

## Backend

- Framework: JUnit 6(Spring Boot 4 기본), Mockito를 쓴다.
- Integration: Testcontainers `postgres:17`과 `@ServiceConnection`을 쓴다. H2를 쓰지 않는다(Flyway와 운영 DB와 동일한 환경에서 검증한다).
- Architecture: `LayerDependencyTest`(ArchUnit)를 완화하거나 삭제하지 않는다.
- Time: 시간이 결과에 영향을 주면 고정된 `Clock`을 주입한다.
- Requirement: 통합 테스트는 Docker 데몬이 필요하다.

## Frontend

- Unit: 도메인 로직과 provider를 테스트한다.
- Widget: 핵심 화면만 위젯 테스트를 작성한다.
- Analyze: `flutter analyze`는 항상 통과해야 한다.

## Commands

- Backend: `cd backend && ./gradlew build`
- Frontend: `cd frontend && dart run build_runner build && flutter analyze && flutter test`

## Evidence

- 작업을 완료했다고 보고할 때는 실행한 명령과 실제 결과를 함께 적는다. 실행하지 못한 검증은 못 했다고 명시한다.
- 테스트가 실패하면 구현을 고친다. 테스트가 틀린 경우에만 테스트를 바꾼다.
