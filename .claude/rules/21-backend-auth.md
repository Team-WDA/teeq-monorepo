---
paths:
  - "backend/**"
---

# Backend Auth

인증·보안 설정의 공통 원칙만 둔다. 가입 항목, 비밀번호·닉네임 규칙, 약관, 토큰 만료와 저장 방식 같은 계정 상세는 코드와 이슈 코멘트가 원천이다. 에러 응답 형식은 `20-backend-conventions.md`, AI 연동은 `22-backend-domains.md`를 따른다.

## Domain split

- member: 프로필과 `Member` 엔티티, `AuthenticatedMember`(principal)를 맡는다. `auth`를 참조하지 않는다.
- auth: 자격 증명 전반(가입, 로그인, 토큰, 비밀번호, 계정 삭제)과 보안 설정을 맡는다. `member.core`를 참조한다. 토큰 폐기와 얽힌 기능은 `auth`에서 처리한다.
- 토큰 발급과 검증은 `auth.core.port.TokenProvider` port로 추상화하고 `auth.infrastructure`의 `JwtProvider`가 구현한다. 구현체가 하나뿐이지만 `application`이 `infrastructure`를 import할 수 없는 계층 규칙 때문에 두는 port이며, `10-backend-architecture.md`의 Ports and adapters 예외다.

## Credentials and tokens

- 비밀번호는 평문으로 저장하지 않고 BCrypt로 해시한다.
- 인증은 JWT(jjwt)이고 `Authorization: Bearer` 헤더로 전달한다. Access Token과 Refresh Token은 `type` claim으로 구분하고, 맞지 않는 토큰은 거부한다. Access Token에는 role을 넣지 않고 DB 값을 쓴다.
- 이메일은 저장·비교 전에 정규화한다. 이메일·닉네임 같은 UNIQUE는 활성 행에만 걸리도록 partial unique index(`where deleted = false`)로 만든다.
- 로그인 실패는 이메일 존재 여부를 구분하지 않고 `INVALID_CREDENTIALS` 하나로 응답한다.

## Principal

- `AuthenticatedMember`(`member.core.principal`)는 `Member` 엔티티를 품는 record다. 컨트롤러는 `@AuthenticationPrincipal AuthenticatedMember`로 받아 `.member()`를 서비스에 넘긴다.
- JWT 필터는 Access Token을 파싱한 뒤 `MemberRepository.findByIdAndDeletedFalse`로 회원을 조회한다. 회원이 없거나 삭제되었으면 401 `UNAUTHENTICATED`다. 권한은 `ROLE_<role>`이다.
- 엔티티 사용: `open-in-view: false`라 컨트롤러가 받은 `Member`는 분리 상태다. 읽기에는 그대로 쓰고, 수정은 서비스 `@Transactional` 메서드 안에서 id로 다시 조회한 엔티티에만 한다.

## Security config

- Stateless: 세션을 쓰지 않는다. formLogin, httpBasic, csrf, logout은 끈다. CORS는 설정하지 않는다(모바일 앱 전용).
- Method security: `@EnableMethodSecurity`를 켠다. role 기반 접근 제어는 `@PreAuthorize`로 선언한다.
- Paths: 인증 없이 여는 경로는 `SecurityPaths` 상수에 모으고 그 외는 인증이 필요하다.
- Error: 401과 403도 `ErrorResponse`로 응답한다. `GlobalExceptionHandler`는 `AccessDeniedException`과 `AuthenticationException`을 다시 던져 보안 체인이 처리하게 한다.
- Location: 보안 설정과 필터는 `auth` 도메인의 `infrastructure/config`에 둔다.
- Secrets: `jwt.*`, `ai-server.*` 같은 설정값은 `application-{dev,prod}.yml`(gitignore)에서 `@ConfigurationProperties`로 바인딩하고, 필수 값이 비어 있으면 기동 시 실패시킨다. 값은 문서와 로그에 남기지 않는다.

## Server-to-server

- Prefix: AI 서버가 BE를 호출하는 엔드포인트는 모두 `/api/ai-server/**` 아래에 둔다. 사용자 JWT가 필요한 경로는 이 접두사를 쓰지 않는다.
- Auth: 이 접두사는 JWT가 아니라 공유 헤더로만 인증한다. 헤더 이름과 값은 `ai-server.auth-header-name`, `ai-server.auth-header-value`이며 BE→AI 서버 호출도 같은 헤더·값을 쓴다. 양방향 공유라 한쪽이 유출되면 양쪽이 뚫리는 점은 MVP에서 허용한다. HTTPS를 전제로 하며 타임스탬프 서명·IP 허용 목록 같은 보강은 운영 단계에서 검토한다.
- Chain: `/api/ai-server/**` 전용 `SecurityFilterChain`을 따로 둔다(`securityMatcher`로 경로 한정, JWT 필터 없음). 기존 JWT 체인은 이 경로를 매칭하지 않으며 `SecurityPaths` 공개 경로에도 넣지 않는다. 헤더 값은 상수 시간 비교(`MessageDigest.isEqual`)로 검증하고, 없거나 다르면 401 `UNAUTHENTICATED`를 `ErrorResponse`로 응답한다. 이 경로에서는 사용자 JWT를 받아도 인증되지 않는다.

## Dependencies

- Approved: `spring-boot-starter-security`, `jjwt-api`, `jjwt-impl`, `jjwt-jackson`(0.13.0), 테스트용 `spring-boot-starter-security-test`. 그 외 보안 관련 의존성은 사용자 확인 후 추가한다.
- Jackson: jjwt-jackson 0.13.0은 Jackson 2(`com.fasterxml`) 전용이다. Boot 4의 Jackson 3(`tools.jackson`)과 공존하며, 에러 응답을 쓰는 `ObjectMapper`는 `tools.jackson.databind.ObjectMapper`다.
