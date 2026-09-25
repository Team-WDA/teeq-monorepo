---
paths:
  - "frontend/**"
---

# Flutter Architecture

## Scope

- Platforms: android, ios만 지원한다. Web 타깃은 만들지 않는다.
- Package: Dart 패키지명은 `teeq`이다.
- App id: Android `applicationId`/`namespace`와 iOS bundle id는 모두 `kr.teeq.app`으로 통일한다(iOS는 `_`를 쓸 수 없어 `flutter create` 기본값이 플랫폼마다 달랐다). 스토어 배포 후에는 바꾸기 어렵다.
- App name: 사용자에게 보이는 이름은 `TeeQ`이다. 바꿀 때는 Android `android:label`, iOS `CFBundleDisplayName`/`CFBundleName`, `MaterialApp.title`을 함께 바꾼다.
- SDK: Flutter 3.47.x / Dart 3.13 이상. `pubspec.yaml`의 SDK 제약으로 명시한다(FVM은 쓰지 않는다).

## Structure

- Feature-first: `lib/features/<feature>/{data,domain,presentation}`
- Shared: `lib/core/{config,router,network}`
- Example: `lib/features/home/presentation/home_screen.dart`, `lib/core/config/app_config.dart`
- 실제 기능(통화, 캐릭터, 귀갓길 등)은 해당 기능을 만들 때 `features/` 아래에 추가한다.

## State management

- Riverpod: `flutter_riverpod` + `riverpod_annotation` / `riverpod_generator`(`@riverpod`)를 사용한다.
- Server vs client state: 서버 상태는 provider(AsyncNotifier)로 다루고, 서버 데이터를 별도 클라이언트 스토어에 복제하지 않는다.
- Derived values: 파생 값은 저장하지 않고 provider에서 계산한다.

## Routing

- go_router를 사용한다. 라우트 정의는 `lib/core/router`에 둔다.
- 공유 가능한 화면 상태(예: 탭, 필터)는 URL에 반영한다.

## Network

- dio 인스턴스는 `lib/core/network`의 provider 하나로 만들고, base URL은 `AppConfig`에서 가져온다.
- API 경로는 백엔드의 `/api/v1/...`와 일치시킨다.
- 에러 응답은 `ProblemDetail`(RFC 9457) 형식이다. `dio` 예외를 도메인 오류로 변환해서 presentation에 전달한다.

## Layer rules

- presentation → domain, data → domain 방향만 허용한다. domain은 Flutter/dio에 의존하지 않는다.
- 위젯에는 비즈니스 로직을 두지 않는다. 로직은 provider/도메인에 둔다.
- 앞으로 통화 화면은 사용자가 화면을 계속 보지 않는 음성 중심 UX이므로, 화면 요소를 최소화한다.
