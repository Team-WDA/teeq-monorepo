---
paths:
  - "backend/**"
---

# Backend Architecture

## High-level architecture

- Module: 단일 Gradle 모듈(`backend/`)이다. 멀티모듈로 분리하지 않는다.
- Package root: `kr.teeq.api`
- Structure: 도메인 우선 `<domain>/{core,application,infrastructure}`. 공통 코드는 `common/{core,application,infrastructure}`이다. 별도의 `domain` 바깥 패키지는 두지 않는다.
- Example: `kr.teeq.api.character.core.entity.Character`

## Layers

- core: JPA 엔티티, VO, enum, 도메인 이벤트, 리포지토리 인터페이스(Spring Data), 외부 연동 port 인터페이스. JPA/Spring Data 어노테이션 외의 프레임워크 의존은 두지 않는다.
- 도메인 구성과 소유 테이블은 `22-backend-domains.md`를 따른다.
- application: 유스케이스 서비스, DTO(`dto/{request,response}`), mapper, 컨트롤러(`controller/`), `XxxControllerDocs` 인터페이스.
- infrastructure: port의 adapter 구현(AI 서버 등 외부 연동), `@Configuration`, `@ConfigurationProperties`(`properties/`), QueryDSL 구현체, 보안 설정과 필터.

## Dependency direction

- Allowed: `application → core`, `infrastructure → core`, `core → common.core`, `infrastructure → common.application`(예: 보안 처리기가 `ErrorResponse`를 쓴다)
- 금지: core가 application 또는 infrastructure를 참조하는 것, application이 infrastructure를 직접 import하는 것(외부 연동은 core의 port 인터페이스를 통한다), 도메인 간 순환 의존.
- Enforcement: `LayerDependencyTest`(ArchUnit)가 위 규칙을 검증한다. 규칙 위반 시 테스트를 완화하지 말고 코드 구조를 고친다.

## Ports and adapters

- 교체·확장 가능성이 있는 외부 연동(AI 서버 등)만 core에 port 인터페이스를, infrastructure에 adapter를 둔다. STT/LLM/TTS는 AI 서버 안의 일이며 BE가 직접 호출하지 않는다.
- 그 외 구성요소에는 인터페이스를 미리 만들지 않는다(구현체가 하나뿐인 서비스에 인터페이스 금지).
- 예외: 토큰 발급과 검증(`TokenProvider`)은 구현체가 하나뿐이지만 `application`이 `infrastructure`를 import할 수 없어 port를 둔다(`21-backend-auth.md`).

## Controller

- Path: `/api/<복수형-kebab-case>` (`@RestController`, `@RequestMapping`). 버전 접두사(`/v1`)는 쓰지 않는다. 경로 변수도 kebab-case다(예: `/api/call-sessions/{call-session-id}`).
- Return: `ResponseEntity<Dto>` 또는 `Page<Dto>` 직접 반환. 응답 envelope은 쓰지 않는다.
- Call: 컨트롤러는 서비스만 호출한다. 리포지토리를 직접 호출하지 않는다.
- Docs: Swagger 어노테이션은 컨트롤러가 구현하는 `XxxControllerDocs` 인터페이스에 분리한다(springdoc 도입 이후 적용).
- Location: 컨트롤러는 각 도메인의 `application/controller`에 둔다.

## Common package

- `common/core`: `ErrorCode`(중앙 enum 하나), `CustomException`, `BaseEntity` 등 도메인 공통 타입
- `common/application`: `GlobalExceptionHandler`, `ErrorResponse`(`application/exception`) 등 웹 공통 처리
- Naming: 패키지·디렉터리 이름이 `.gitignore` 패턴과 겹치면 그 아래 소스가 추적에서 빠진다. 새 패키지명을 정할 때 `.gitignore`와 겹치는지 확인한다.
- `common/infrastructure`: `ClockConfig`, `JpaAuditingConfig` 등 공통 설정
- 도메인 코드는 `common`에 의존할 수 있지만 `common`은 도메인에 의존하지 않는다.
