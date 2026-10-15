# Secrets And Env

## Principle

- `.env`를 쓰지 않는다. `.env.example`을 포함한 example/템플릿 파일도 만들지 않는다.
- Backend는 `application.yml`(공통, 추적)과 `application-{dev,prod}.yml`(실제 값, gitignore)로 관리한다.
- Frontend는 `frontend/config/{dev,prod}.json`(gitignore)을 `--dart-define-from-file`로 주입한다.
- 필요한 키의 목록은 example 파일이 아니라 코드/주석에 둔다: 백엔드는 `application.yml` 주석, 프론트는 `AppConfig`.

## Files

| 파일 | Git | 내용 |
| --- | --- | --- |
| `backend/src/main/resources/application.yml` | 추적 | 공통 설정. 시크릿 값 없음 |
| `backend/src/main/resources/application-dev.yml` | 무시 | 로컬 접속 정보(datasource 등). 사용자가 직접 채운다 |
| `backend/src/main/resources/application-prod.yml` | 무시 | 운영 값. wizard 워크플로우가 secret `APPLICATION_PROD_YML`로 생성한다 |
| `frontend/config/dev.json`, `prod.json` | 무시 | 클라이언트 빌드 값(API base URL, 공개 클라이언트 ID) |
| `*.jks`, `*.keystore`, `key.properties` | 무시 | Android 서명 |
| `*.p8`, `*.p12`, `*.pem` | 무시 | Apple/서버 키·인증서 |
| `google-services.json`, `GoogleService-Info.plist` | 무시 | Firebase 클라이언트 설정 |

## Key list

- Backend keys: `spring.datasource.{url,username,password}`와 `jwt.{secret-key,access-exp-millis,refresh-exp-millis,issuer}`이다(`21-backend-auth.md`). 값은 사용자가 `application-{dev,prod}.yml`에 채운다.
- Frontend keys: 현재 `API_BASE_URL` 하나다(`AppConfig` 참고).
- 키를 추가할 때는 이 문서, `application.yml` 주석 또는 `AppConfig`, README 안내를 함께 갱신한다.
- CI에서 쓰는 GitHub Secrets(배포용) 전체 목록은 `.claude/rules/80-ci-cd.md`를 본다. `frontend/config/prod.json`은 로컬에서는 직접 만들고, CI에서는 Secret `FRONTEND_CONFIG_JSON`(JSON 문자열)으로부터 생성한다.

## Handling rules

- Claude는 시크릿 파일을 읽을 수 있지만 값을 커밋, 로그, PR, 대화에 노출하지 않는다.
- 시크릿 파일을 `git add -f`로 추적시키지 않는다.
- 값이 필요한 작업은 키 이름과 위치만 만들고 값은 사용자가 채우게 한다.
- 실수로 시크릿이 커밋되었다면 즉시 사용자에게 알리고 해당 값을 폐기(rotate)한다.

## CI에서의 환경값 주입 (해결됨)

- wizard의 Flutter 워크플로우가 원래 전제하던 `ENV_FILE`, `SECRETS_XCCONFIG`, `GOOGLE_SERVICES_JSON` secret은 이 앱이 읽지 않으므로 모두 죽은 단계로 주석 처리했다.
- 대신 각 Flutter 빌드 job에 "Create config/prod.json" 스텝을 추가해, Secret `FRONTEND_CONFIG_JSON`(JSON 문자열 전체)을 `frontend/config/prod.json`에 쓰고 `--dart-define-from-file=config/prod.json`으로 빌드한다. 배포용 job(FIREBASE/PLAYSTORE/SELFHOSTED/TF/IT)은 이 secret이 비어 있으면 즉시 실패하고, CI/TEST-APK는 포크 PR을 고려해 `{}`로 대체하고 경고만 남긴다.
- `IOS_PROVISIONING_PROFILE_NAME` secret은 "Generate ExportOptions.plist" 스텝(teeq가 추가)이 소비해서 `frontend/ios/ExportOptions.plist`를 CI에서 직접 생성한다. 자세한 내용은 `.claude/rules/80-ci-cd.md`를 본다.
