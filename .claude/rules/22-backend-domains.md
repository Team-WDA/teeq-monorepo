---
paths:
  - "backend/**"
---

# Backend Domains and AI Integration

도메인 공통 원칙과 AI 서버 연동 경계만 둔다. 도메인별 기능, 엔드포인트, 필드, 에러 코드, 상태 값, 정책 값은 문서에 적지 않는다. 원천은 코드(`ErrorCode`, `XxxControllerDocs`, `SettingKey`, Flyway 마이그레이션)와 각 이슈의 결정 코멘트이며, 문서와 코드가 어긋나면 코드가 맞다. 구조는 `10-backend-architecture.md`, 계정과 보안은 `21-backend-auth.md`를 따른다.

## Scope

- BE가 맡는 것: 계정, 온보딩, 캐릭터 저장, 홈 조회, 통화 한도 검사와 통화 기록, 피드백, 그리고 AI 서버 호출·수신.
- BE가 맡지 않는 것: AI 기능 전체와 음성 통화. 통화 세션 생성, LiveKit 토큰 발급, 통화 시간 계산, 기억, STT/LLM/TTS는 AI 서버(AI 개발자)가 하고 BE는 API로 호출하거나 호출받는다.
- MVP 제외 범위는 `00-project-overview.md`를 따른다.

## Domain principles

- 도메인 패키지는 구현할 때 만든다. 빈 패키지를 미리 만들지 않는다.
- 도메인 상세는 이슈 구현 시 브레인스토밍으로 확정하고, 결정과 이유는 이슈 코멘트로 남긴다. 확정 전에는 임의로 구현하지 않는다.
- 테이블 이름과 컬럼은 Flyway 마이그레이션이 확정한다.

## AI server integration

- Port: AI 서버 호출은 사용하는 도메인의 `core.port`에 인터페이스를, `infrastructure`에 adapter를 둔다(`10-backend-architecture.md`). `RestClient` 설정과 `ai-server.*` properties는 `common.infrastructure`에 둔다. 런타임 클래스패스에 `RestClient.Builder` 자동 구성 빈이 없으므로 `RestClient.builder()`를 직접 쓴다.
- Contract: BE→AI 호출 계약은 BE가 정의하고 AI 개발자가 맞춘다. AI 서버 명세가 오면 해당 adapter만 고친다.
- Ownership: BE DB는 회원·온보딩·캐릭터·통화 기록·피드백·인사말을 소유하고, AI 서버는 대화와 기억을 소유한다. AI 서버는 BE DB를 직접 읽지 않으므로 BE가 필요한 데이터를 요청 본문에 실어 보낸다. AI→BE 호출은 AI 서버가 알고 있는 결과(예: 통화 종료 보고)에 한정한다.
- Auth: 서버 간 인증은 공유 헤더 하나이며 양방향으로 쓴다(`21-backend-auth.md` Server-to-server). 헤더 이름·값과 URL은 `ai-server.*` 설정에서 읽는다.
- Inbound: AI 서버가 BE를 호출하는 경로는 모두 `/api/ai-server/**` 아래에 둔다.
- Outbound: 동기 호출이며 타임아웃은 `ai-server.timeout-millis`, 재시도는 하지 않는다(세션 생성처럼 멱등이 아닌 호출이 있다). 외부 호출 중에는 DB 트랜잭션을 열어 두지 않는다.
- Errors: 호출 실패·타임아웃·응답 이상은 모두 502 `AI_SERVER_UNAVAILABLE`로 변환한다. AI의 에러 본문(`{code, message}`)은 BE 로그에만 남기고 앱에는 BE의 `{errorCode, errorMessage}`만 내린다.

## Dynamic settings

- 운영 중 바꿀 수 있는 정책 값(한도, 임계값, 기능 on/off, 고정 문구 등)은 코드 enum `SettingKey`가 키를 정의하고 `setting_config` 테이블이 값을 갖는다. 소비처는 `SettingConfigService.getInt/getBoolean/getString`을 쓴다.
- 캐시 없이 읽을 때마다 DB를 조회하고, 행이 없으면 enum 기본값을 쓴다. 시드 값은 마이그레이션에 넣지 않는다.
- 값 수정은 관리자 API(`/api/admin/setting-configs`, ADMIN 전용)로만 한다.
- Candidate review: 새 도메인을 구현할 때 하드코딩하거나 `@ConfigurationProperties`로 둘 값 중 운영 중 바꿀 만한 것이 있는지 검토해 `SettingKey` 후보로 추천한다. 추가는 사용자 확인 후에 한다.
