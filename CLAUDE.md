# CLAUDE.md

이 파일은 진입점이며, 상세 규칙은 `.claude/rules/*.md`에 있습니다. 작업 시작 전 반드시 아래 파일들을 읽고 이해한 뒤 진행하세요.

- `.claude/rules/00-project-overview.md`: 제품 요약, MVP 범위, 용어집, 스택, 주요 명령
- `.claude/rules/10-backend-architecture.md`: 백엔드 패키지 구조, 레이어 역할, 의존 방향
- `.claude/rules/20-backend-conventions.md`: 엔티티·DTO·예외·시간·DB·Flyway·설정 규칙
- `.claude/rules/21-backend-auth.md`: 계정, 비밀번호, 닉네임, 약관, 토큰(AT/RT), 보안 설정
- `.claude/rules/22-backend-domains.md`: BE 도메인, 온보딩·캐릭터, AI 서버 연동, 통화 사용 토큰, 피드백, MVP 제외 범위
- `.claude/rules/30-flutter-architecture.md`: Flutter 구조, 상태관리, 라우팅, 네트워크
- `.claude/rules/40-flutter-conventions.md`: 모델, 생성 코드, 환경값(`AppConfig`), 클라이언트 시크릿 원칙
- `.claude/rules/50-testing.md`: 테스트 정책 (전역 80% 규칙을 대체)
- `.claude/rules/60-git-and-delivery.md`: 브랜치, 커밋, PR, force 금지, CI/CD(wizard)
- `.claude/rules/70-secrets-and-env.md`: 파일별 추적/무시 기준, 시크릿 취급
- `.claude/rules/80-ci-cd.md`: 설치된 GitHub Actions 워크플로우 목록, Secrets, 릴리스·버전 규칙

## 핵심 요약 (전체 내용은 위 rules 파일 참고)

- **구조**: 모노레포. `backend/`(Spring Boot 4, Java 21, Gradle Groovy, 단일 모듈), `frontend/`(Flutter android/ios, Web 제외)
- **백엔드 패키지**: `kr.teeq.api.<domain>.{core,application,infrastructure}`. core=엔티티·리포지토리·port, application=서비스·DTO·컨트롤러, infrastructure=adapter·config. 의존 방향은 ArchUnit으로 강제
- **백엔드 규칙**: PK는 UUID v7, 시간은 `Clock` 주입 + `Instant`, soft delete(`deleted`/`deleted_at`, 조회 필터는 명시적), 에러는 중앙 `ErrorCode` enum + `CustomException` + `{errorCode, errorMessage}`, URL `/api/<복수형-kebab>`(버전 접두사 없음), DTO는 record 우선, `@Data` 금지
- **백엔드 MVP 범위**: 이메일 로그인(AT 1일/RT 30일), 온보딩·캐릭터, 홈, 통화 한도 검사(초), 피드백. AI 기능과 음성, 통화 세션·시간 계산은 별도 AI 서버가 맡고 BE는 API 연동과 한도 검사만 한다. 기억 열람, Analytics, Cost Tracking, Safety, 다기기 로그인은 제외
- **프론트 규칙**: Riverpod + go_router + feature-first, 환경값은 `frontend/config/*.json`(`--dart-define-from-file`), 생성 코드는 커밋하지 않음
- **테스트**: 꼭 필요한 부분만(핵심 도메인 로직 TDD), Testcontainers/H2/DB 통합 테스트 없음, 커버리지 게이트 없음
- **Git**: `main` 단일 + `<type>/<설명>` 브랜치 PR, 커밋은 `type: 한국어 설명`
- **절대 금지**:
  - force 계열 git 명령(`--force`, `git add -f` 등)
  - 사용자가 그 순간 명시적으로 지시하지 않은 `main` 푸시(직접 푸시·PR 병합 모두) — wizard 적용 후 `main` 푸시는 곧 배포다
  - `application-dev.yml`, `application-prod.yml`, `frontend/config/*.json`, 키/인증서 커밋
  - `.env`, `*.example` 파일 추가
  - 클라이언트(Flutter)에 서버 시크릿 포함
  - 약어 사용(`id`, `url`, `dto` 제외)
