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
- 인증: 이메일과 비밀번호로 로그인하고 Access Token(1일), Refresh Token(30일)을 받는다. 요청은 `Authorization: Bearer` 헤더로 보낸다. 재발급할 때마다 Refresh Token이 새로 오며 이전 것은 무효가 된다. 다기기 로그인은 고려하지 않는다.
- 통화: 음성은 FE가 AI 서버에 직접 연결한다. 통화 시작 전에 BE에 시작을 요청해 사용 토큰(분 단위 한도) 잔여를 확인하고, 종료와 사용량은 AI 서버가 BE에 보고한다. 연결 실패와 재연결, 시간 경고 화면은 FE와 AI 서버 사이의 일이다.
- 온보딩: 질문과 선택지 문구는 FE가 하드코딩하고, 서버 enum 코드로 한 번에 제출한다. 캐릭터 번호는 BE가 AI 서버에서 받아 저장해 응답한다.
- API 경로는 백엔드의 `/api/<복수형-kebab-case>`와 일치시킨다(버전 접두사 없음, 예: `/api/call-sessions/{call-session-id}`).
- 에러 응답은 `{ "errorCode": "<ErrorCode enum 이름>", "errorMessage": "<한국어 메시지>" }` 두 필드다. HTTP 상태는 응답 상태 줄로만 온다. `dio` 예외를 `errorCode` 기준의 도메인 오류로 변환해서 presentation에 전달하고, 분기는 `errorMessage`가 아니라 `errorCode`로 한다.
- 알려진 `errorCode`: `INVALID_REQUEST`(400), `MALFORMED_REQUEST_BODY`(400), `RESOURCE_NOT_FOUND`(404), `METHOD_NOT_ALLOWED`(405), `UNSUPPORTED_MEDIA_TYPE`(415), `STATE_CONFLICT`(409), `INTERNAL_SERVER_ERROR`(500). 백엔드가 `ErrorCode`에 도메인 코드를 추가하면 클라이언트도 함께 반영한다. 모르는 코드는 `INTERNAL_SERVER_ERROR`와 같은 일반 오류로 처리한다.
- 성공 응답은 envelope 없이 DTO를 그대로 받는다. 목록은 `Page<Dto>`이며, 실제 JSON 구조는 첫 목록 API가 생길 때 확인해 이 문서에 기록한다.
- 시각: 응답의 시각은 ISO-8601 UTC(`...Z`)이다. 파싱은 `DateTime.parse`로 UTC로 받고, 화면에 보일 때만 로컬 시간으로 변환한다. 요청에 보내는 시각도 UTC로 보낸다.
- ID: 모든 엔티티 ID는 UUID(v7) 문자열이다. 순번 ID로 가정하지 않는다.
- 삭제: 백엔드는 soft delete이며 `deleted`, `deletedAt`은 API로 노출하지 않는 것을 기본으로 한다. 삭제된 데이터는 조회 응답에 오지 않는다고 가정한다.

## Layer rules

- presentation → domain, data → domain 방향만 허용한다. domain은 Flutter/dio에 의존하지 않는다.
- 위젯에는 비즈니스 로직을 두지 않는다. 로직은 provider/도메인에 둔다.
- 앞으로 통화 화면은 사용자가 화면을 계속 보지 않는 음성 중심 UX이므로, 화면 요소를 최소화한다.
