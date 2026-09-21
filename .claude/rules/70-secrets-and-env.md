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

- Backend keys: 현재 `spring.datasource.{url,username,password}`만 정의되어 있다. 값은 비어 있으며 사용자가 채운다.
- Frontend keys: 현재 `API_BASE_URL` 하나다(`AppConfig` 참고).
- 키를 추가할 때는 이 문서, `application.yml` 주석 또는 `AppConfig`, README 안내를 함께 갱신한다.

## Handling rules

- Claude는 시크릿 파일을 읽을 수 있지만 값을 커밋, 로그, PR, 대화에 노출하지 않는다.
- 시크릿 파일을 `git add -f`로 추적시키지 않는다.
- 값이 필요한 작업은 키 이름과 위치만 만들고 값은 사용자가 채우게 한다.
- 실수로 시크릿이 커밋되었다면 즉시 사용자에게 알리고 해당 값을 폐기(rotate)한다.

## Known mismatch with wizard

- wizard의 Flutter 워크플로우는 `ENV_FILE`, `SECRETS_XCCONFIG`, `GOOGLE_SERVICES_JSON` 등의 secret을 전제로 한다. 적용 후 `frontend/config/prod.json`을 secret에서 생성하고 `--dart-define-from-file`을 사용하도록 워크플로우를 수정해야 한다.
