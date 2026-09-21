---
paths:
  - "backend/**"
---

# Backend Architecture

## High-level architecture

- Module: 단일 Gradle 모듈(`backend/`)이다. 멀티모듈로 분리하지 않는다.
- Package root: `com.chuseok22.aifriend`
- Structure: 도메인 우선 `<domain>/{core,application,infrastructure}`. 공통 코드는 `common/{core,application,infrastructure}`이다. 별도의 `domain` 바깥 패키지는 두지 않는다.
- Example: `com.chuseok22.aifriend.character.core.entity.Character`

## Layers

- core: JPA 엔티티, VO, enum, 도메인 이벤트, 리포지토리 인터페이스(Spring Data), 외부 연동 port 인터페이스. JPA/Spring Data 어노테이션 외의 프레임워크 의존은 두지 않는다.
- application: 유스케이스 서비스, DTO(`dto/{request,response}`), mapper, 컨트롤러(`controller/`), `XxxControllerDocs` 인터페이스.
- infrastructure: port의 adapter 구현(STT/LLM/TTS 등 외부 AI, Redis, 스토리지), `@Configuration`, `@ConfigurationProperties`(`properties/`), QueryDSL 구현체.

## Dependency direction

- Allowed: `application → core`, `infrastructure → core`, `core → common.core`
- 금지: core가 application 또는 infrastructure를 참조하는 것, application이 infrastructure를 직접 import하는 것(외부 연동은 core의 port 인터페이스를 통한다), 도메인 간 순환 의존.
- Enforcement: `LayerDependencyTest`(ArchUnit)가 위 규칙을 검증한다. 규칙 위반 시 테스트를 완화하지 말고 코드 구조를 고친다.

## Ports and adapters

- 교체·확장 가능성이 있는 외부 연동(STT, LLM, TTS 등 AI 제공자)만 core에 port 인터페이스를, infrastructure에 adapter를 둔다.
- 그 외 구성요소에는 인터페이스를 미리 만들지 않는다(구현체가 하나뿐인 서비스에 인터페이스 금지).

## Controller

- Path: `/api/v1/<resource>` (`@RestController`, `@RequestMapping`)
- Return: `ResponseEntity<Dto>` 또는 `Page<Dto>` 직접 반환. 응답 envelope은 쓰지 않는다.
- Docs: Swagger 어노테이션은 컨트롤러가 구현하는 `XxxControllerDocs` 인터페이스에 분리한다(springdoc 도입 이후 적용).
- Location: 컨트롤러는 각 도메인의 `application/controller`에 둔다.

## Common package

- `common/core`: `ErrorCode`, `BusinessException`, `BaseEntity` 등 도메인 공통 타입
- `common/application`: `GlobalExceptionHandler` 등 웹 공통 처리
- `common/infrastructure`: `ClockConfig`, `JpaAuditingConfig` 등 공통 설정
- 도메인 코드는 `common`에 의존할 수 있지만 `common`은 도메인에 의존하지 않는다.
