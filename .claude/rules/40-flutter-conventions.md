---
paths:
  - "frontend/**"
---

# Flutter Conventions

## Code style

- Format: `dart format` 기본값(2칸)을 따른다.
- Lint: `flutter_lints`. `flutter analyze`가 경고 없이 통과해야 한다.
- Naming: 약어를 쓰지 않는다. `print`를 남기지 않는다(`avoid_print`).
- Comments: 주석은 한국어, 식별자는 영어.

## Models and generated code

- Models: `freezed`(불변)와 `json_serializable`을 사용한다.
- Generated files: `*.g.dart`, `*.freezed.dart`는 gitignore이며 커밋하지 않는다.
- Generate: `cd frontend && dart run build_runner build --delete-conflicting-outputs`. 클론 직후와 어노테이션을 바꾼 뒤에 실행한다.

## Environment values

- Injection: 환경값은 `--dart-define-from-file=config/dev.json` 또는 `config/prod.json`으로 주입한다. `.env`와 `flutter_dotenv`는 쓰지 않는다.
- Files: `frontend/config/*.json`은 gitignore이다. example 파일을 만들지 않는다.
- Single source: 키 정의는 `lib/core/config/app_config.dart`의 `AppConfig` 한 곳에서만 한다(`String.fromEnvironment`). 이 파일이 필요한 키 목록의 유일한 문서이다.
- Fail fast: 필수 키가 비어 있으면 앱 시작 시 `AppConfig.validate()`가 즉시 실패시킨다.
- New key: 키를 추가할 때는 `AppConfig`, `70-secrets-and-env.md`의 키 목록, README 안내를 함께 갱신한다.
- Flavor: Android productFlavors / iOS scheme은 쓰지 않는다. dev/prod 앱을 한 기기에 동시 설치해야 할 때 도입을 다시 결정한다.
- Run: `.vscode/launch.json`에 `--dart-define-from-file=config/dev.json`이 설정되어 있다.

## Client secrets

- 클라이언트에 넣은 값은 앱에서 추출할 수 있다고 가정한다.
- `config/*.json`에는 API base URL, 공개 클라이언트 ID(카카오 네이티브 앱 키, Google client id 등)만 둔다.
- LLM/STT/TTS 키 같은 서버 시크릿은 절대 클라이언트에 넣지 않는다. 백엔드 `application-*.yml`에만 둔다.

## Dependencies

- 새 패키지는 그 기능을 만들 때 추가한다. 마이크, 위치, 푸시, 권한 관련 패키지는 아직 도입하지 않았다.
- 패키지를 추가하면 Android/iOS 권한 설정(`AndroidManifest.xml`, `Info.plist`)을 함께 검토한다.
