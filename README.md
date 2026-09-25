# TeeQ

AI 캐릭터에게 실제 전화하듯 전화를 걸고, 대화를 거듭하며 관계를 쌓는 AI 페르소나 기반 실시간 음성 동행 서비스입니다.
평소에는 재미로 통화하고, 늦은 귀갓길에는 원할 때 지인에게 위치와 상태를 공유할 수 있습니다.

## 구조

```
teeq-monorepo/
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
2. `cd frontend && flutter pub get && dart run build_runner build`
3. `flutter run --dart-define-from-file=config/dev.json`

생성 코드(`*.g.dart`, `*.freezed.dart`)는 커밋하지 않으므로 클론 직후 `build_runner`를 한 번 실행해야 합니다.

## 에뮬레이터/시뮬레이터에서 실행하기

`config/dev.json`을 만든 뒤(위 "프론트엔드 실행" 1번) 진행합니다.

1. 사용 가능한 기기 확인
   ```bash
   cd frontend
   flutter emulators   # 설치된 에뮬레이터/시뮬레이터 목록 (예: apple_ios_simulator, Medium_Phone)
   flutter devices     # 현재 연결/실행 중인 기기 목록
   ```
2. 기기 실행
   ```bash
   # Android 에뮬레이터
   flutter emulators --launch <emulator id>   # 예: flutter emulators --launch Medium_Phone

   # iOS 시뮬레이터 (Xcode 26 이하는 Simulator, Xcode 27+는 Device Hub)
   open -a Simulator
   # 또는
   open -a DeviceHub
   ```
   Android Studio의 Device Manager나 Xcode의 Devices and Simulators 창에서 직접 실행해도 됩니다.
3. 앱 실행
   ```bash
   flutter run --dart-define-from-file=config/dev.json          # 연결된 기기가 하나면 자동 선택
   flutter run -d <device id> --dart-define-from-file=config/dev.json   # 여러 개면 flutter devices의 id로 지정
   ```
   VS Code를 쓴다면 `.vscode/launch.json`에 이미 설정된 **"teeq (dev)"** 구성으로 F5 실행하면 위 플래그가 자동으로 붙습니다.

## 빌드

```bash
cd frontend

# Android
flutter build apk --debug --dart-define-from-file=config/dev.json      # 디버그 APK, 서명 불필요
flutter build apk --release --dart-define-from-file=config/prod.json   # 릴리스 APK. key.properties가 없으면 debug 키로 자동 서명(스토어 제출 불가, 로컬 테스트용)
flutter build appbundle --release --dart-define-from-file=config/prod.json   # Play Store 제출용 AAB

# iOS (실기기/스토어 배포는 Xcode 서명이 필요해 로컬에서는 --no-codesign까지만 확인)
flutter build ios --release --no-codesign --dart-define-from-file=config/prod.json
```

실제 서명·스토어 업로드(Android release/Play, iOS TestFlight)는 로컬이 아니라 CI(GitHub Actions)에서 시크릿을 사용해 처리합니다. 어떤 시크릿이 필요한지는 `.claude/rules/80-ci-cd.md`를 참고하세요.

## 문서

프로젝트 규칙과 결정 사항은 [`CLAUDE.md`](CLAUDE.md)와 `.claude/rules/`를 참고하세요.

---

<!-- AUTO-VERSION-SECTION: DO NOT EDIT MANUALLY -->
## 최신 버전 : v0.0.1

[전체 버전 기록 보기](CHANGELOG.md)
