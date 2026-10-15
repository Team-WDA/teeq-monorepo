---
paths:
  - "backend/**"
---

# Backend Auth

계정, 토큰, 보안 설정 규칙이다. 에러 응답 형식은 `20-backend-conventions.md`, 도메인별 규칙은 `22-backend-domains.md`를 따른다.

## Account

- Login: 이메일과 비밀번호만 쓴다. 소셜 로그인, 이메일 인증, 비밀번호 찾기, 다기기 로그인은 MVP 범위 밖이다.
- Signup: API 한 번에 이메일, 비밀번호, 약관 동의, 닉네임을 받는다. 닉네임 중복 확인 API를 별도로 둔다.
- Delete: 계정 삭제 API를 둔다(soft delete, `20-backend-conventions.md`의 Soft delete). 삭제하면 해당 회원의 Refresh Token을 모두 무효화한다.
- Unique: 이메일과 닉네임 UNIQUE는 활성 행에만 걸리도록 partial unique index(`where deleted = false`)로 만든다. 삭제된 회원의 이메일과 닉네임은 다시 쓸 수 있다.

## Password

- Rule: 8자 이상, 영문과 숫자를 포함한다.
- Storage: 평문으로 저장하지 않고 BCrypt로 해시한다.
- Change: 현재 비밀번호를 확인한 뒤 변경한다. 변경하면 해당 회원의 Refresh Token을 모두 무효화한다.

## Nickname

- Rule: 한글, 영문, 숫자만 허용하고 2~10자다. 공백, 특수문자, 이모지는 허용하지 않는다.
- Unique: 활성 회원 안에서 중복을 허용하지 않는다.
- Change: 변경 횟수 제한은 두지 않는다.

## Terms

- Required: 서비스 이용약관, 개인정보 수집·이용 두 가지가 필수 동의다.
- Storage: 동의 이력만 저장한다(약관 종류, 버전, 동의 시각). 약관 본문은 서버가 제공하지 않고 외부 URL이며 클라이언트 설정(`AppConfig`)에 둔다.

## Token

- Type: JWT(jjwt). Access Token 1일, Refresh Token 30일. 전달은 `Authorization: Bearer` 헤더다.
- Rotation: 재발급할 때마다 Refresh Token을 새로 발급하고 이전 것은 무효화한다. Refresh Token은 해시로만 저장한다.
- Device: 다기기 로그인은 고려하지 않는다. 기기별로 Refresh Token을 구분하지 않고, 회원당 활성 Refresh Token은 하나다(새 로그인은 기존 것을 대체한다).
- Logout: 해당 회원의 Refresh Token을 무효화한다.
- Config: `application-{dev,prod}.yml`(gitignore)의 `jwt.secret-key`, `jwt.access-exp-millis`, `jwt.refresh-exp-millis`, `jwt.issuer`로 주입하고 `@ConfigurationProperties`로 바인딩한다. 값은 문서와 로그에 남기지 않는다.

## Security config

- Stateless: 세션을 쓰지 않는다. formLogin, httpBasic, csrf는 끈다(토큰 인증 API).
- Paths: 공개 경로(가입, 로그인, 토큰 재발급, 닉네임 중복 확인, `/actuator/health` 등)는 상수 한 곳에 모으고 그 외는 인증이 필요하다.
- Error: 401과 403도 `ErrorResponse`로 응답한다. 인증 관련 `ErrorCode`는 구현 시 중앙 enum에 추가한다.
- Login failure: 이메일 존재 여부를 구분하지 않고 하나의 `ErrorCode`로 응답한다.
- Location: 보안 설정과 필터는 `auth` 도메인의 `infrastructure/config`에 둔다.

## Server-to-server

- AI 서버가 BE를 호출하는 엔드포인트(통화 종료 보고 등)는 사용자 토큰이 아닌 서버 간 인증을 쓴다. 인증 방식은 AI 서버가 구성된 뒤에 정한다(미정).

## Dependencies

- Approved: `spring-boot-starter-security`, `jjwt-api`, `jjwt-impl`, `jjwt-jackson`. 그 외 보안 관련 의존성은 사용자 확인 후 추가한다.
- Reference: 같은 조합(Boot 4.1.1 + jjwt)을 whoim-platform이 컴파일과 슬라이스 테스트로 확인했다. 실기동 검증은 도입할 때 직접 한다.
