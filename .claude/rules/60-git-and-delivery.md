# Git And Delivery

## Branch

- Strategy: `main` 단일 브랜치를 쓴다. `develop`은 없다.
- Work location: 이슈 브랜치, 수동 브랜치, `main` 직접 작업 중 **어디서 할지는 매번 사용자 지시를 따른다.** 지시가 없으면 현재 체크아웃된 브랜치에서 작업한다. 브랜치를 새로 만들 때 이름은 wizard 이슈 헬퍼 방식(`YYYYMMDD_#이슈번호_제목`)을 써도 되고 `<type>/<설명>`을 써도 된다 — 강제하지 않는다.
- `main` push: **사용자가 명시적으로 지시했을 때만** `main`에 푸시한다(직접 푸시든 PR 병합이든). 지시 없이 임의로 푸시하지 않는다. 예외: `RELEASE-PUBLISH`·`README-VERSION-UPDATE` 워크플로우 봇이 `[skip ci]` 커밋으로 자동으로 하는 푸시는 이 규칙과 무관하다(CI 안에서 실행되는 것이며 Claude의 행동이 아니다).
- Warning: wizard 적용 후에는 `main` 푸시(PR 병합 포함)가 곧 서버·앱 배포를 일으킨다(`80-ci-cd.md` 참고). 그래서 `main` 푸시는 더더욱 사용자 지시가 있을 때만 한다.

## Commit

- Format: `<type>: <한국어 설명>` (필요하면 본문 추가)
- Types: feat, fix, refactor, docs, test, chore, perf, ci
- Staging: 스테이징은 경로를 지정한다(`git add <경로>`). `git add -A`/`git add .`를 쓰지 않는다.
- Authority: Claude는 하위 브랜치에서 commit, push, PR 생성을 요청 없이도 할 수 있다. `main`에는 사용자가 명시적으로 지시했을 때만 push한다. 단 아래 금지 사항을 지킨다.

## Forbidden

- Force: `push --force`/`-f`/`--force-with-lease`, `git add -f`(`.gitignore` 우회 포함), `checkout -f`, `clean -f`, `branch -D`, `reset --hard`, 공유 이력의 `commit --amend`, `--no-verify`, `--no-gpg-sign`은 사용자가 그 순간 정확히 그 작업을 요청한 경우가 아니면 쓰지 않는다. 서브에이전트에도 동일하게 적용한다.
- Ignored files: `.gitignore`로 제외된 파일은 제외된 상태를 유지한다. 추적이 필요해 보이면 사용자에게 먼저 확인한다.
- `main` push: 사용자가 그 순간 명시적으로 지시하지 않았다면 하지 않는다(위 Branch 절 참고).

## Pull request

- Title: `<type>: <한국어 설명>`
- Body: 변경 요약, 테스트/검증 결과, 확인이 필요한 사항.
- Before PR: 로컬에서 `cd backend && ./gradlew build`, `cd frontend && flutter analyze && flutter test`(해당 변경 범위)를 통과시킨다.

## CI/CD

- Tool: `project-auto-wizard`(npm CLI)로 GitHub Actions와 버전 관리를 구성했다. 이미 적용되어 있다. 재실행은 사용자가 직접 한다(`--dry-run`으로 먼저 확인). Claude가 임의로 실행하지 않는다.
- 설치된 워크플로우 목록, 상태, GitHub Secrets, 채널별 재활성화 조건, 릴리스·버전 판정 규칙, wizard 재실행 시 주의는 `.claude/rules/80-ci-cd.md`를 본다.
- Dockerfile은 사용자가 `backend/Dockerfile`에 직접 작성한다(SIMPLE-CICD가 이를 전제로 한다).
