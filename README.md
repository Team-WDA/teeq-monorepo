# TeeQ

AI 캐릭터에게 실제 전화하듯 전화를 걸고, 대화를 거듭하며 관계를 쌓는 AI 페르소나 기반 실시간 음성 동행 서비스입니다.
평소에는 재미로 통화하고, 늦은 귀갓길에는 원할 때 지인에게 위치와 상태를 공유할 수 있습니다.

## IDE 열기

저장소 루트에서 실행합니다.

```bash
# Xcode (iOS)
open frontend/ios/Runner.xcworkspace

# Android Studio (Android)
open -a "Android Studio" frontend
```

## 관리자 계정 설정

- 설정 키: `admin.accounts[].{username,password,name}`
- 값은 `application-{dev,prod}.yml`에 직접 채운다.
- 서버 기동 시 계정을 만들며, 이미 있는 username은 건너뛴다.

## AI 서버 임시 캐릭터 설정

- 설정 키: `ai-server.stub-character-enabled` (선택, 기본값 `false`)
- AI 서버가 캐릭터 결정 API를 제공하기 전까지만 `application-{dev,prod}.yml`(운영은 시크릿 `APPLICATION_PROD_YML`)에 `true`로 둔다.
- 켜면 AI 서버를 호출하지 않고 온보딩 답변과 무관하게 항상 같은 캐릭터를 돌려준다. 통화 시작과 홈 한마디는 영향이 없다.
- `ai-server.{base-url,auth-header-name,auth-header-value}`는 통화와 홈 한마디가 계속 쓰므로 그대로 필요하다.
- 이 기간에 가입한 회원의 `personaId`는 `stub-persona`로 저장되어 통화 요청과 통화 기록에도 그대로 남는다. 내부 테스트 후 DB를 초기화한다.
- `true`나 `false`가 아닌 값을 넣으면 기동에 실패한다. AI 서버가 완성되면 이 설정과 임시 구현을 삭제한다.

---

<!-- AUTO-VERSION-SECTION: DO NOT EDIT MANUALLY -->
## 최신 버전 : v0.26.1 (2026-10-22)

[전체 버전 기록 보기](CHANGELOG.md)
