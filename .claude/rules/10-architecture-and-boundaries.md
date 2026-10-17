# Architecture And Boundaries

## High-level architecture

- 모노레포. `backend/`(단일 Gradle 모듈)와 `frontend/`(Flutter).
  - 모노레포로 둔 이유: Claude 에이전트가 FE와 BE의 코드를 서로 쉽게 확인하게 하려는 것이다. FE 작업은 `backend/`의 컨트롤러·DTO·`ErrorCode`를, BE 작업은 `frontend/`의 호출부를 직접 읽어 계약을 확인한다. 계약의 원천은 문서가 아니라 코드이며, 다른 쪽 코드를 고치는 일은 사용자 요청 범위 안에서만 한다.
- BE 패키지: `kr.co.teeq.api.<domain>.{core,application,infrastructure}`, 공통은 `common/{core,application,infrastructure}`.
  - core: 엔티티, enum, 리포지토리 인터페이스, 외부 연동 port
  - application: 서비스, DTO(`dto/{request,response}`), 컨트롤러와 `XxxControllerDocs`
  - infrastructure: adapter, 설정, `@ConfigurationProperties`, 보안 설정·필터
- 외부 연동: AI 서버(별도 서버, 개발자 별도). STT/LLM/TTS, 통화 세션 생성, LiveKit 토큰, 통화 시간 계산, 기억은 AI 서버가 하고 BE는 하지 않는다.

## Module boundaries

- 허용 의존: `application → core`, `infrastructure → core`, `core → common.core`, `infrastructure → common.application`.
- 금지: core가 application·infrastructure를 참조, application이 infrastructure를 직접 import(외부 연동은 core의 port로), 도메인 간 순환 의존. `LayerDependencyTest`(ArchUnit)가 강제하며 완화·삭제하지 않는다.
- port·adapter는 교체·확장 가능성이 있는 외부 연동에만 둔다. 구현체가 하나뿐인 서비스에는 인터페이스를 만들지 않는다(예외: `TokenProvider`는 계층 규칙 때문에 둔다).
- member는 `auth`를 참조하지 않고, auth는 `member.core`를 참조한다.
- common은 도메인에 의존하지 않고, 도메인은 common에 의존할 수 있다.

## Data flow

- 요청: 컨트롤러는 서비스만 호출하고 리포지토리를 직접 호출하지 않는다. 응답은 `ResponseEntity<Dto>`, envelope 없음.
- 데이터 소유: BE DB는 회원·온보딩·캐릭터·통화 기록·피드백·인사말을 소유하고, AI 서버는 대화와 기억을 소유한다. AI 서버는 BE DB를 읽지 않으므로 BE가 필요한 데이터를 요청에 실어 보낸다.
- AI 서버 호출: BE→AI는 동기 호출, 타임아웃은 설정값, 재시도 없음. 호출 중에는 DB 트랜잭션을 열어 두지 않는다. 실패·타임아웃·응답 이상은 502 `AI_SERVER_UNAVAILABLE`로 변환하고 AI의 에러 본문은 BE 로그에만 남긴다. 호출 계약은 BE가 정의하고 AI 개발자가 맞춘다.
- AI→BE 호출: 경로는 모두 `/api/ai-server/**`, 인증은 JWT가 아니라 공유 헤더 하나(전용 `SecurityFilterChain`, 양방향 같은 헤더). 사용자 JWT가 필요한 경로는 이 접두사를 쓰지 않는다.
- 인증: JWT(Bearer), stateless, 컨트롤러는 `@AuthenticationPrincipal AuthenticatedMember`로 받는다. 세션·CORS는 쓰지 않는다(모바일 전용).
- 동적 설정: 운영 중 바꿀 정책 값은 코드 enum `SettingKey` + `setting_config` 테이블, 읽기는 `SettingConfigService`, 수정은 관리자 API(`/api/admin/**`, ADMIN 전용). 새 기능을 구현할 때 설정 후보를 검토해 추천한다.

## File / folder conventions

- 컨트롤러 경로는 `/api/<복수형-kebab-case>`(버전 접두사 없음), 경로 변수도 kebab-case.
- Swagger 어노테이션은 컨트롤러가 구현하는 `XxxControllerDocs` 인터페이스(같은 `controller` 패키지)에 둔다. 에러 코드와 발생 조건을 한국어로 적고, `@Valid` 같은 검증 어노테이션은 컨트롤러와 Docs에 똑같이 선언한다(다르면 HV000151로 500).
- 패키지·디렉터리 이름이 `.gitignore` 패턴과 겹치면 소스가 추적에서 빠진다. 새 패키지명을 정할 때 확인한다.
- 도메인 패키지는 구현할 때 만든다. 빈 패키지를 미리 만들지 않는다.
- FE: `lib/features/<feature>/{data,domain,presentation}`, 공유는 `lib/core/{config,router,network,design,error,ui,auth}`. presentation → domain, data → domain 방향만 허용하고 domain은 Flutter·dio에 의존하지 않는다.

## Extension points

- 새 도메인은 기존 도메인(`auth`, `call`, `setting`)의 구조와 테스트를 먼저 참고한다.
- 외부 연동 추가는 `call`의 port(`core/port`)와 adapter(`infrastructure/adapter`), 공통 `RestClient`·`AiServerProperties`(`common.infrastructure`)를 재사용한다. 런타임에 `RestClient.Builder` 자동 구성 빈이 없으므로 `RestClient.builder()`를 직접 쓴다.
- 보안 경로는 `SecurityPaths`, 서버 간 인증은 `AiServerSecurityConfig`를 참고한다.
