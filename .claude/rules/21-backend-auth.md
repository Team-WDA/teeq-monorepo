---
paths:
  - "backend/**"
---

# Backend Auth

계정, 토큰, 보안 설정 규칙이다. 에러 응답 형식은 `20-backend-conventions.md`, 도메인별 규칙은 `22-backend-domains.md`를 따른다.

## Domain split

- member: 프로필(내 정보, 닉네임 변경, 닉네임 중복 확인)과 `Member` 엔티티, `AuthenticatedMember`(principal)를 맡는다. `auth`를 참조하지 않는다.
- auth: 자격 증명 전반(가입, 로그인, 토큰 재발급, 로그아웃, 비밀번호 변경, 계정 삭제)과 토큰, 보안 설정을 맡는다. `member.core`를 참조한다.
- 토큰 발급과 검증은 `auth.core.port.TokenProvider` port로 추상화하고 `auth.infrastructure`의 `JwtProvider`가 구현한다. 구현체가 하나뿐이지만 `application`이 `infrastructure`를 import할 수 없는 계층 규칙 때문에 두는 port이며, `10-backend-architecture.md`의 Ports and adapters 예외다.

## Account

- Login: 이메일과 비밀번호만 쓴다. 소셜 로그인, 이메일 인증, 비밀번호 찾기, 다기기 로그인, 로그인 시도 제한은 MVP 범위 밖이다.
- Signup: API 한 번에 이메일, 비밀번호, 약관 동의, 닉네임을 받고 토큰을 함께 응답한다. 닉네임 중복 확인 API를 별도로 둔다.
- Email: 저장 전에 소문자로 정규화한다. 가입 요청은 `@Email` 검증이 앞뒤 공백을 거부하므로(400) 공백이 섞인 이메일로는 가입되지 않는다. 로그인 이메일은 trim + 소문자로 정규화해서 비교한다.
- Delete: 계정 삭제 API를 둔다(`Member` soft delete). 삭제하면 해당 회원의 Refresh Token을 삭제한다.
- Unique: 이메일(`email`)과 닉네임(`lower(nickname)`) UNIQUE는 활성 행에만 걸리도록 partial unique index(`where deleted = false`)로 만든다. 삭제된 회원의 이메일과 닉네임은 다시 쓸 수 있다.
- Role: `Member.role`은 `USER`/`ADMIN`이다. 가입 계정은 `USER`이며 ADMIN 생성 방법은 별도 이슈에서 정한다.

## Password

- Rule: 영문과 숫자를 포함한 8~64자이고, 공백과 한글을 제외한 출력 가능한 ASCII 문자만 쓴다(BCrypt 72바이트 한계로 인한 오류를 막기 위함).
- Storage: 평문으로 저장하지 않고 BCrypt로 해시한다.
- Change: 현재 비밀번호를 확인한 뒤 변경하고, 새 Access Token과 Refresh Token을 응답한다. 이미 발급된 Access Token은 만료까지(최대 1일) 유효하므로 비밀번호 변경이 탈취된 AT를 무효화하지는 않는다.

## Nickname

- Rule: 한글, 영문, 숫자만 허용하고 2~10자다. 공백, 특수문자, 이모지는 허용하지 않는다.
- Unique: 활성 회원 안에서 대소문자 구분 없이 중복을 허용하지 않는다. 자신의 닉네임을 대소문자만 바꾸는 것은 허용한다.
- Change: 변경 횟수 제한은 두지 않는다.

## Terms

- Required: 서비스 이용약관, 개인정보 수집·이용 두 가지가 필수 동의다. 둘 다 `true`여야 가입된다.
- Storage: `Member`의 boolean 필드(`serviceTermsAgreed`, `privacyPolicyAgreed`)로만 둔다. 동의 시각과 약관 버전은 저장하지 않으며 `created_at`이 가입 시점이다. 약관 본문은 서버가 제공하지 않고 외부 URL이며 클라이언트 설정(`AppConfig`)에 둔다.

## Token

- Type: JWT(jjwt, HS512). Access Token 1일, Refresh Token 30일(만료는 `jwt.*` 설정값). 전달은 `Authorization: Bearer` 헤더다.
- Claims: `sub`(memberId), `iss`, `iat`, `exp`, `jti`(랜덤), `type`(`access`/`refresh`). `type`이 맞지 않는 토큰은 거부한다(RT를 AT로, AT를 RT로 쓰지 못하게 함). AT에는 role을 넣지 않고 DB 값을 쓴다.
- Refresh Token storage: `refresh_token` 테이블에 평문 JWT로 저장한다. 회원당 1행(`member_id` UNIQUE)이고 hard delete한다(이력 불필요, soft delete 예외). RT 만료와 위조, 이미 교체된 RT는 모두 `INVALID_REFRESH_TOKEN`이다.
- Rotation: 재발급과 새 로그인은 기존 행을 덮어쓴다. 교체되기 전의 이전 RT는 저장된 값과 달라 거부된다.
- Device: 다기기 로그인은 고려하지 않는다. 기기별 RT 구분이 없고 새 로그인은 기존 RT를 대체한다.
- Logout: 해당 회원의 RT를 삭제한다. 이미 발급된 AT는 만료까지 유효하다.
- Config: `application-{dev,prod}.yml`(gitignore)의 `jwt.secret-key`, `jwt.access-exp-millis`, `jwt.refresh-exp-millis`, `jwt.issuer`로 주입하고 `@ConfigurationProperties`로 바인딩한다. `secret-key`는 UTF-8 64바이트 이상이어야 하며 `JwtProperties` 생성 시 검증한다. 값은 문서와 로그에 남기지 않는다.

## Principal

- `AuthenticatedMember`(`member.core.principal`)는 `Member` 엔티티를 품는 record다. 컨트롤러는 `@AuthenticationPrincipal AuthenticatedMember`로 받아 `.member()`를 서비스에 넘긴다.
- JWT 필터는 AT를 파싱한 뒤 `MemberRepository.findByIdAndDeletedFalse`로 회원을 조회한다. 회원이 없거나 삭제되었으면 401 `UNAUTHENTICATED`다. 권한은 `ROLE_<role>`이다.
- 엔티티 사용: `open-in-view: false`라 컨트롤러가 받은 `Member`는 분리 상태다. 읽기에는 그대로 쓰고, 수정은 서비스 `@Transactional` 메서드 안에서 id로 다시 조회한 엔티티에만 한다.

## Security config

- Stateless: 세션을 쓰지 않는다. formLogin, httpBasic, csrf, logout은 끈다. CORS는 설정하지 않는다(모바일 앱 전용).
- Method security: `@EnableMethodSecurity`를 켠다. role 기반 접근 제어는 `@PreAuthorize`로 선언한다.
- Paths: 공개 경로(가입 `POST /api/members`, 닉네임 중복 확인, 로그인, 재발급, `/actuator/health`, `/error`)는 `SecurityPaths` 상수에 모으고 그 외는 인증이 필요하다.
- Error: 401과 403도 `ErrorResponse`로 응답한다. `GlobalExceptionHandler`는 `AccessDeniedException`과 `AuthenticationException`을 다시 던져 보안 체인이 처리하게 한다.
- Login failure: 이메일 존재 여부를 구분하지 않고 `INVALID_CREDENTIALS` 하나로 응답한다.
- Location: 보안 설정과 필터는 `auth` 도메인의 `infrastructure/config`에 둔다.

## Server-to-server

- Prefix: AI 서버가 BE를 호출하는 엔드포인트(통화 종료 보고 등)는 모두 `/api/ai-server/**` 아래에 둔다. 사용자 JWT가 필요한 경로는 이 접두사를 쓰지 않는다.
- Auth: 이 접두사는 JWT가 아니라 공유 헤더로만 인증한다. 헤더 이름과 값은 `ai-server.auth-header-name`, `ai-server.auth-header-value`(`application-{dev,prod}.yml`)이며 이름은 `X-Teeq-Server-Key`다. BE→AI 서버 호출도 같은 헤더·값을 쓴다(양방향 공유, 한쪽이 유출되면 양쪽이 뚫리는 점은 MVP에서 허용).
- Chain: `/api/ai-server/**` 전용 `SecurityFilterChain`을 따로 둔다(`securityMatcher`로 경로 한정, JWT 필터 없음). 기존 JWT 체인은 이 경로를 매칭하지 않으며 `SecurityPaths` 공개 경로에도 넣지 않는다. 헤더 값은 상수 시간 비교(`MessageDigest.isEqual`)로 검증하고, 없거나 다르면 401 `UNAUTHENTICATED`를 `ErrorResponse`로 응답한다. 이 경로에서는 사용자 JWT를 받아도 인증되지 않는다.
- Config: `ai-server.{base-url,auth-header-name,auth-header-value,timeout-millis}`를 `@ConfigurationProperties`로 바인딩하고, 비어 있으면 기동 시 실패시킨다(`JwtProperties`와 같은 방식). 값은 문서와 로그에 남기지 않는다.

## Dependencies

- Approved: `spring-boot-starter-security`, `jjwt-api`, `jjwt-impl`, `jjwt-jackson`(0.13.0), 테스트용 `spring-boot-starter-security-test`. 그 외 보안 관련 의존성은 사용자 확인 후 추가한다.
- Jackson: jjwt-jackson 0.13.0은 Jackson 2(`com.fasterxml`) 전용이다. Boot 4의 Jackson 3(`tools.jackson`)과 공존하며, 에러 응답을 쓰는 `ObjectMapper`는 `tools.jackson.databind.ObjectMapper`다.
- Reference: 같은 조합(Boot 4.1.1 + jjwt)을 whoim-platform이 컴파일과 슬라이스 테스트로 확인했다.
