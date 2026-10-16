# CLAUDE.md

이 파일은 진입점이며, 상세 규칙은 `.claude/rules/*.md`에 있습니다. 작업 시작 전 아래 파일들을 읽고 진행하세요.

- `.claude/rules/00-project-overview.md`: 제품 요약, 스택, 주요 명령, 프로젝트 제약, 변경 정책
- `.claude/rules/10-architecture-and-boundaries.md`: 구조, 계층 경계, AI 서버 연동 경계, 폴더 규칙
- `.claude/rules/20-team-conventions.md`: 네이밍, 코드 스타일, 책임 분리, 시크릿, 리뷰 기준
- `.claude/rules/30-testing-and-verification.md`: 테스트 정책(전역 80% 규칙을 대체), 검증 명령, 증거
- `.claude/rules/40-delivery-and-review.md`: 보고서 형식, 브랜치·커밋·PR, force 금지, 배포·CI/CD 주의

## 문서 운영

- 규칙 문서는 변하지 않는 공통 원칙만 둔다. 도메인 상세(엔드포인트, 필드, 에러 코드, 상태, 정책 값)는 적지 않고, 각 이슈 구현 전 브레인스토밍에서 결정한다.
- 도메인 상세의 원천은 코드이고 결정 이력은 vault(second-brain) 기록이다. 문서와 코드가 어긋나면 코드가 맞다.
- 이슈 본문은 브레인스토밍을 시작할 때 맥락으로 한 번 가볍게 읽는 용도다. 이슈를 갱신하거나 근거 문서로 쓰지 않는다.

## 절대 금지

- force 계열 git 명령(`--force`, `git add -f` 등)
- 사용자가 그 순간 명시적으로 지시하지 않은 `main` 푸시(직접 푸시·PR 병합 모두). `main` 푸시는 곧 배포다
- `application-dev.yml`, `application-prod.yml`, `frontend/config/*.json`, 키/인증서 커밋
- `.env`, `*.example` 파일 추가
- 클라이언트(Flutter)에 서버 시크릿 포함
- 약어 사용(`id`, `url`, `dto` 제외)
