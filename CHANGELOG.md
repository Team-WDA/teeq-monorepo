# Changelog

**현재 버전:** 0.2.0  
**마지막 업데이트:** 2026-10-16T01:33:23Z  

---

## [0.2.0] - 2026-10-16

**✨ 기능**
- 인증 API 컨트롤러 추가
- 내 정보 조회와 닉네임 변경 구현
- 가입, 로그인, 토큰 재발급 서비스 구현
- 가입, 로그인 요청과 응답 DTO 추가
- Spring Security 보안 설정 추가
- JWT 토큰 provider 추가
- member, refresh_token 테이블 마이그레이션 추가
- RefreshToken 엔티티 추가
- Member 엔티티 추가
- 보안 예외를 필터 체인으로 다시 던지는 핸들러 추가
- 인증과 계정용 ErrorCode 추가

**📝 문서**
- 인증과 계정 규칙을 확정된 설계로 갱신

**🔧 변경사항**
- docs, report, issue 디렉터리를 git 추적에서 제외
- spring security와 jjwt 의존성 추가
- .issue 디렉터리를 git 추적에서 제외
- GitHub 이슈, PR, 디스커션 템플릿과 라벨 동기화 설정 추가
- image 디렉터리를 git 추적에서 제외

---

## [0.1.1] - 2026-10-15

**📝 문서**
- BE MVP 범위, 인증, 도메인 규칙 추가

---

## [0.1.0] - 2026-10-15

**✨ 기능**
- 스토어 배포 플로우(fastlane) 구성

**🐛 수정**
- 진행 상황 댓글에 남아있던 브랜치명 JS 인젝션과 Play 업로드 옵션 수정
- backend jar 산출물을 bootJar 하나로 단일화

**📝 문서**
- FE 규칙을 BE 에러, URL, 시각 규칙에 맞추고 Docker 안내 제거
- 백엔드 규칙을 soft delete, 중앙 ErrorCode, 테스트 최소화 기준으로 정리
- 규칙 문서와 README의 서비스명을 teeq로 변경
- README에 에뮬레이터/시뮬레이터 실행 및 빌드 안내 추가
- CI/CD 워크플로우 규칙 문서화
- build_runner 옵션 안내 수정
- CLAUDE.md 및 프로젝트 rules 추가

**♻️ 리팩토링**
- 에러 응답을 중앙 ErrorCode와 CustomException으로 바꾸고 BaseEntity에 soft delete 추가

**🔧 변경사항**
- 워크플로우와 배포 설정의 서비스명을 teeq로 변경
- 프론트엔드 앱 이름과 번들 ID를 teeq로 변경
- 백엔드 패키지와 서비스명을 teeq로 변경
- CI/CD 워크플로우를 ai-friend 구조에 맞게 수정
- project-auto-wizard 산출물 추가
- 앱 식별자 통일 및 임시 앱 이름 설정
- frontend 골격 추가
- backend 골격 추가
- 기본 설정 파일 추가

---

