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

---

<!-- AUTO-VERSION-SECTION: DO NOT EDIT MANUALLY -->
## 최신 버전 : v0.18.0 (2026-10-20)

[전체 버전 기록 보기](CHANGELOG.md)
