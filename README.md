# ai-friend

AI 캐릭터에게 실제 전화하듯 전화를 걸고, 대화를 거듭하며 관계를 쌓는 AI 페르소나 기반 실시간 음성 동행 서비스입니다.
평소에는 재미로 통화하고, 늦은 귀갓길에는 원할 때 지인에게 위치와 상태를 공유할 수 있습니다.

## 구조

```
ai-friend-monorepo/
├── backend/     Spring Boot 4 (Java 21, Gradle), PostgreSQL, Flyway
├── frontend/    Flutter (android / ios)
├── scripts/sql/ Flyway 파일명 검증 스크립트
└── .claude/rules/  프로젝트 규칙 (CLAUDE.md에서 링크)
```

## 필요한 도구

- JDK 21, Docker(Testcontainers 테스트), PostgreSQL 17
- Flutter 3.47.x (Dart 3.13), iOS는 Xcode, Android는 Android Studio

## 백엔드 실행

1. `backend/src/main/resources/application-dev.yml`의 `spring.datasource.url/username/password`를 채웁니다. (gitignore 파일이며 example은 없습니다.)
2. `cd backend && ./gradlew bootRun`
3. 빌드와 테스트: `cd backend && ./gradlew build`

## 프론트엔드 실행

1. `frontend/config/dev.json`을 직접 만듭니다. 필요한 키는 `frontend/lib/core/config/app_config.dart`의 `AppConfig`를 참고하세요. (gitignore 파일이며 example은 없습니다.)
2. `cd frontend && flutter pub get && dart run build_runner build --delete-conflicting-outputs`
3. `flutter run --dart-define-from-file=config/dev.json`

생성 코드(`*.g.dart`, `*.freezed.dart`)는 커밋하지 않으므로 클론 직후 `build_runner`를 한 번 실행해야 합니다.

## 문서

프로젝트 규칙과 결정 사항은 [`CLAUDE.md`](CLAUDE.md)와 `.claude/rules/`를 참고하세요.
