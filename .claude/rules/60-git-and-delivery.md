# Git And Delivery

## Branch

- Strategy: `main` 단일 브랜치를 쓴다. `develop`은 없다.
- Work: 모든 작업은 `<type>/<설명>` 하위 브랜치에서 진행한다(예: `feat/character-selection`, `fix/call-session-timeout`).
- Merge: 하위 브랜치에서 PR을 만들어 `main`에 병합한다. `main`에 직접 푸시하지 않는다.
- Warning: wizard 적용 후에는 `main` 푸시(PR 병합 포함)가 곧 서버 배포를 일으킨다(SIMPLE-CICD 기준).

## Commit

- Format: `<type>: <한국어 설명>` (필요하면 본문 추가)
- Types: feat, fix, refactor, docs, test, chore, perf, ci
- Staging: 스테이징은 경로를 지정한다(`git add <경로>`). `git add -A`/`git add .`를 쓰지 않는다.
- Authority: Claude는 하위 브랜치에서 commit, push, PR 생성을 요청 없이도 할 수 있다. 단 아래 금지 사항을 지킨다.

## Forbidden

- Force: `push --force`/`-f`/`--force-with-lease`, `git add -f`(`.gitignore` 우회 포함), `checkout -f`, `clean -f`, `branch -D`, `reset --hard`, 공유 이력의 `commit --amend`, `--no-verify`, `--no-gpg-sign`은 사용자가 그 순간 정확히 그 작업을 요청한 경우가 아니면 쓰지 않는다. 서브에이전트에도 동일하게 적용한다.
- Ignored files: `.gitignore`로 제외된 파일은 제외된 상태를 유지한다. 추적이 필요해 보이면 사용자에게 먼저 확인한다.
- Direct main push: 금지.

## Pull request

- Title: `<type>: <한국어 설명>`
- Body: 변경 요약, 테스트/검증 결과, 확인이 필요한 사항.
- Before PR: 로컬에서 `cd backend && ./gradlew build`, `cd frontend && flutter analyze && flutter test`(해당 변경 범위)를 통과시킨다.

## CI/CD

- Tool: `project-auto-wizard`(npm CLI)로 GitHub Actions와 버전 관리를 구성한다. 사용자가 직접 실행한다. Claude가 임의로 실행하지 않는다.
- Command: `npx project-auto-wizard --dry-run`으로 먼저 확인한다. 모노레포 옵션은 `--paths "spring=backend,flutter=frontend"`, 브랜치는 `main` 단일(trunk-based)이다.
- Prerequisites: Spring 배포 워크플로우는 저장소 루트의 `./gradlew`와 `./Dockerfile`을 전제로 한다. 우리는 `backend/`에 두므로 적용 후 `working-directory`, `DOCKERFILE_PATH` 등을 수정한다. Dockerfile은 사용자가 작성한다.
- Secrets: Spring 배포는 secret `APPLICATION_PROD_YML`로 `application-prod.yml`을 만든다(`70-secrets-and-env.md` 참고).
- Re-run: wizard가 만든 워크플로우를 수정했다면 wizard 재실행 시 덮어써질 수 있으니 `--dry-run`으로 먼저 확인한다.
