# CI/CD

`project-auto-wizard`(v0.9.1, npm CLI)로 생성한 GitHub Actions 워크플로우를 `teeq` 구조에 맞게 최소 수정해서 쓴다. 원본은 삭제하지 않고 죽은 단계만 `# [teeq: ...]` 표시로 주석 처리했다. 이 문서는 실제로 무엇이 켜져 있고 무엇이 아직 비어 있는지의 기준이다.

## 설치된 워크플로우

| 파일 | 트리거 | 상태 |
| --- | --- | --- |
| `PROJECT-COMMON-RELEASE-PUBLISH.yaml` | push(`backend/**`,`frontend/**`), workflow_dispatch | 사용 |
| `PROJECT-COMMON-README-VERSION-UPDATE.yaml` | 위와 동일 | 사용(릴리스보다 먼저 끝나 한 버전 뒤처질 수 있음) |
| `PROJECT-COMMON-AI-PR-SUMMARY.yaml` | pull_request(main) | 사용(wizard 기본값, fork PR 게이트 이미 있음) |
| `PROJECT-COMMON-ISSUE-HELPER.yaml` | issues(opened/edited) | 사용(wizard 기본값, 브랜치 자동 생성 켜짐) |
| `PROJECT-SPRING-SIMPLE-CICD.yaml` | push(`backend/**`), workflow_dispatch | 사용. `backend/Dockerfile` 작성 완료(`eclipse-temurin:21-jre-alpine`, `/actuator/health` 헬스체크) |
| `PROJECT-SPRING-PR-PREVIEW.yaml` | — | **삭제됨**(public 저장소에서 댓글 작성자 검증 없이 시크릿을 쓰는 job이 실행되는 문제. 필요해지면 첫 커밋 `chore: project-auto-wizard 산출물 추가`에서 복구) |
| `PROJECT-FLUTTER-CI.yaml` | push/pull_request(`frontend/**`) | 사용. Android debug 빌드까지, iOS 빌드 포함(macOS 비용) |
| `PROJECT-FLUTTER-ANDROID-TEST-APK.yaml` | workflow_dispatch, repository_dispatch | 사용(수동/SUH-LAB 트리거) |
| `PROJECT-FLUTTER-ANDROID-FIREBASE-CICD.yaml` | push(`frontend/**`) | 켜져 있지만 **Firebase 프로젝트 미준비로 매 실행 실패**(placeholder 가드) |
| `PROJECT-FLUTTER-ANDROID-PLAYSTORE-CICD.yaml` | push(`frontend/**`) | 켜져 있지만 **Play Console/시크릿 미준비로 매 실행 실패** |
| `PROJECT-FLUTTER-ANDROID-SELFHOSTED-CICD.yaml` | push(`frontend/**`) | 켜져 있지만 **SMB 서버/시크릿 미준비로 매 실행 실패** |
| `PROJECT-FLUTTER-IOS-TESTFLIGHT.yaml` | push(`frontend/**`) | 켜져 있지만 **Apple 시크릿 미준비로 매 실행 실패** |
| `PROJECT-FLUTTER-IOS-TEST-TESTFLIGHT.yaml` | workflow_dispatch, repository_dispatch | 사용(수동/SUH-LAB 트리거), 위와 동일하게 Apple 시크릿 필요 |
| `PROJECT-FLUTTER-SUH-LAB-APP-BUILD-TRIGGER.yaml` | issue_comment | 사용. `author_association`(OWNER/MEMBER/COLLABORATOR) 게이트 추가함 |

FIREBASE/PLAYSTORE/SELFHOSTED/IOS-TESTFLIGHT는 의도적으로 `push` 트리거를 켜 둔 상태다(비활성화하지 않기로 결정). 시크릿이 준비되기 전까지는 `frontend/**` 변경마다 실패 알림이 온다.

## GitHub Secrets

| Secret | 용도 | 사용 워크플로우 | 출처 |
| --- | --- | --- | --- |
| `APPLICATION_PROD_YML` | `backend/src/main/resources/application-prod.yml` 생성 | SIMPLE-CICD | wizard |
| `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` | Docker Hub 로그인/푸시 | SIMPLE-CICD | wizard |
| `SERVER_HOST`, `SERVER_USER`, `SERVER_PASSWORD` | 배포 서버 SSH(비밀번호 인증) | SIMPLE-CICD, SELFHOSTED(SMB) | wizard |
| `SSH_KEY` | 선언되어 있으나 미사용(비밀번호 인증 선택) | SIMPLE-CICD | wizard |
| `FRONTEND_CONFIG_JSON` | `frontend/config/prod.json` 생성(`API_BASE_URL` 등) | CI, FIREBASE, PLAYSTORE, SELFHOSTED, TEST-APK, IOS-TESTFLIGHT, IOS-TEST-TESTFLIGHT | **teeq 신규**(wizard 원본에 없음) |
| `RELEASE_KEYSTORE_BASE64`, `RELEASE_KEYSTORE_PASSWORD`, `RELEASE_KEY_ALIAS`, `RELEASE_KEY_PASSWORD` | Android release 서명(`key.properties`) | FIREBASE, PLAYSTORE, TEST-APK(선택) | wizard |
| `DEBUG_KEYSTORE` | SELFHOSTED 전용 서명(선택, 없으면 Gradle 기본 debug 키 사용) | SELFHOSTED | wizard |
| `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` | Firebase App Distribution 업로드 | FIREBASE, TEST-APK(선택) | wizard |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_BASE64` | Play Console 업로드 | PLAYSTORE | wizard |
| `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD` | iOS 배포 인증서(p12) | IOS-TESTFLIGHT, IOS-TEST-TESTFLIGHT | wizard |
| `APPLE_PROVISIONING_PROFILE_BASE64` | iOS 프로비저닝 프로필 | IOS-TESTFLIGHT, IOS-TEST-TESTFLIGHT | wizard |
| `IOS_PROVISIONING_PROFILE_NAME` | Xcode 서명 지정 + `ExportOptions.plist` 생성(teeq가 추가한 스텝) | IOS-TESTFLIGHT, IOS-TEST-TESTFLIGHT | wizard |
| `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64` | App Store Connect API 키 | IOS-TESTFLIGHT, IOS-TEST-TESTFLIGHT | wizard |
| `IOS_BUNDLE_ID`(secret 또는 repo variable) | Fastfile `APP_IDENTIFIER`. 비어 있으면 `kr.teeq.app`으로 자동 폴백(선택) | IOS-TESTFLIGHT | wizard |
| `AI_API_KEY`(선택) + vars `AI_API_BASE_URL`, `AI_MODEL` | 릴리스 노트 AI 요약(없으면 GitHub Models → 규칙 기반 폴백) | RELEASE-PUBLISH, AI-PR-SUMMARY | wizard |
| `WORKFLOW_PAT`(선택) | 릴리스 automerge 가속(없어도 `GITHUB_TOKEN`으로 동작) | RELEASE-PUBLISH | wizard |

값은 사용자가 GitHub 저장소 Settings → Secrets에 직접 등록한다. 이 문서에는 이름과 용도만 적고 값은 적지 않는다.

## 채널별 재활성화 전 필요한 것

| 채널 | 시크릿 외 추가로 필요한 것 |
| --- | --- |
| Firebase App Distribution | Firebase 프로젝트 생성, `PROJECT-FLUTTER-ANDROID-FIREBASE-CICD.yaml`의 `FIREBASE_APP_ID`(현재 `your-firebase-app-id` placeholder, 가드가 막고 있음)와 `FIREBASE_TESTER_GROUP`을 실제 값으로 교체 |
| Google Play 내부 테스트 | Play Console 앱 등록(`kr.teeq.app`), 최초 AAB 수동 업로드 1회, `ko-KR` 리스팅 언어 활성화(변경 로그 업로드용) |
| 자체 서버(SMB) 배포 | SMB 서버 준비, `SMB_PORT`(`44445`)·`SMB_SHARE`(`web`) 값이 실제 서버와 맞는지 확인 |
| TestFlight / App Store | Apple Developer 계정, `kr.teeq.app` 배포 인증서·프로비저닝 프로필 발급, App Store Connect API 키 발급 |

## 릴리스와 버전 규칙

- 커밋 제목으로 버전을 판정한다(`.github/scripts/changelog_manager.py`): `feat: ...` → minor, `type!:`(예: `feat!:`) → **major**(0.x에서도 `1.0.0`으로 올라감, 1.0 전에는 쓰지 않는다), 그 외(`fix`/`docs`/`chore`/`refactor`/`test`/`perf`/`ci`) → patch. 한국어만 있는 제목은 patch이거나 AI가 minor로 올릴 수 있어 결과가 불안정하다.
- 커밋 컨벤션은 wizard 템플릿(`제목 : feat : 설명`)이 아니라 우리 `type: 한국어 설명`을 그대로 쓴다. 두 형식 모두 스크립트가 인식한다.
- 버전은 BE/FE가 하나(`version.yml`)를 공유한다. `backend/build.gradle`의 `version`과 `frontend/pubspec.yaml`의 `version`(버전 이름)은 항상 같다. FE에만 빌드 번호(`+N`, `version_code`)가 추가로 붙으며, 릴리스마다 1씩 증가한다. 즉 BE만 바뀐 릴리스에도 FE 빌드 번호가 올라간다(정상 동작).
- 최초 릴리스는 태그가 없어 전체 커밋 이력을 분류하므로 `0.0.1`이 아니라 `0.1.0`(또는 그 이상)이 될 수 있다.
- **알려진 제약**: `RELEASE-PUBLISH`(버전 bump)와 배포 워크플로우(FIREBASE/PLAYSTORE/IOS-TESTFLIGHT 등)가 같은 `push`에서 동시에 실행되고 서로 다른 시점에 `main`을 `checkout`+`pull`한다. 배포 job이 bump 이전 버전을 패키징할 수 있다. 최소 수정 원칙에 따라 `workflow_run` 체이닝 같은 구조적 수정은 하지 않았다. 버전 코드/빌드 번호 충돌(Play·App Store가 "이미 사용된 버전"으로 거부)이 실제로 발생하면 해당 배포를 수동으로 재실행(`workflow_dispatch`)해서 대응한다.

## wizard 재실행 시 주의

- 워크플로우 파일을 직접 고쳤으므로(`localOnly` 상태), 일반적인 재실행에서는 우리 수정이 유지된다. 단 재실행 중 파일별로 `skip`/`backup`/`template`을 선택하는 화면이 뜨면 **항상 `skip`을 고른다.** `backup`/`template`을 고르면 원본이 되살아나 우리가 고친 내용(경로, 버전, 보안 게이트, config/prod.json 주입 등)이 사라진다.
- `PROJECT-SPRING-PR-PREVIEW.yaml`은 삭제했으므로, 재설치 시 "파일이 없어졌다"고 물어볼 수 있다. 복구하지 않는다(삭제 이유는 위 표 참고).
- **`version.yml`의 `deploy:` 블록은 워크플로우 파일과 다르게 재실행마다 통째로 다시 만들어진다.** `teeq`로 바꾼 `PROJECT_NAME`/`VOLUME_CONTAINER_PATH`/`APP_ARTIFACT_NAME` 값이 재실행 후 `teeq-monorepo`로 되돌아갈 수 있다. 재실행 후에는 `git diff version.yml`로 확인하고 필요하면 다시 고친다.
- 재실행 후에는 이 문서의 "잔존 문자열 검색"(`.claude/rules`의 검증 절차 참고: `teeq-monorepo`, `3.35.5`, `./Dockerfile` 검색)을 다시 돌려본다.
