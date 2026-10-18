# Project Overview

## Purpose

- 목적: AI 페르소나 기반 실시간 음성 동행 서비스. 사용자가 AI 캐릭터에게 실제 전화하듯 통화하고, 통화 → 기억 → 관계 → 재통화 루프로 관계를 쌓는다. AI Companion이 Core이고 귀갓길 Safety Support는 보조 레이어다.
- 해결하려는 문제: 늦은 밤 혼자 이동하는 시간에 곁에 있어 주는 대화 상대.
- 사용자: 20~30대 여성. North Star는 Weekly Returning Callers(일주일 내 2회 이상 통화).
- 우선순위: Voice Latency > Conversation Quality > Persona Consistency > Memory > Context Awareness > Safety Support 신뢰성.
- 범위: 클라이언트는 Flutter(android/ios), Web은 범위 밖. 이번 MVP의 BE는 Figma 화면에 있는 기능(가입·로그인, 온보딩·캐릭터, 홈, 통화 한도·기록, 피드백)만 한다. AI 기능과 음성 파이프라인은 AI 개발자의 별도 AI 서버가 맡는다.

## Primary Stack

- Backend: Java 21, Spring Boot 4.1.x(`spring-boot-starter-webmvc`, 가상 스레드), Gradle Groovy DSL, 단일 모듈
- Database: PostgreSQL 17, Spring Data JPA, Flyway
- Frontend: Flutter(android/ios), Riverpod, go_router, dio, freezed
- CI/CD: `project-auto-wizard`로 구성한 GitHub Actions, trunk-based(`main` 단일)

## Important directories

- `backend/`: Spring Boot 앱, 소스 루트 `backend/src/main/java/kr/co/teeq/api`
- `frontend/`: Flutter 앱(`lib/core`, `lib/features`), 환경값 `frontend/config/`(gitignore)
- `scripts/sql/`: Flyway 파일명 검증 스크립트
- `.report/`: 작업 보고서(gitignore)

## Main commands

- BE build/test: `cd backend && ./gradlew build`
- BE run: `cd backend && ./gradlew bootRun` (`application-dev.yml`을 채운 뒤)
- FE 준비: `cd frontend && flutter pub get && dart run build_runner build`
- FE 검증: `cd frontend && flutter analyze && flutter test`
- FE run: `cd frontend && flutter run --dart-define-from-file=config/dev.json`
- Flyway 파일명 검증: `scripts/sql/check_flyway_filenames.sh`

## Project-specific constraints

- 도메인 상세(엔드포인트, 필드, 에러 코드, 상태, 정책 값)는 문서에 적지 않는다. 원천은 코드이고 결정은 각 이슈 구현 전 브레인스토밍에서 확정한다. 확정 전에는 임의로 구현하지 않는다. 결정 이력은 vault(second-brain)에 남긴다. 문서와 코드가 어긋나면 코드가 맞다.
- 이슈 본문은 브레인스토밍 시작 때 맥락으로 한 번 가볍게 읽는 용도다. 이슈를 갱신하거나 근거 문서로 쓰지 않는다.
- 새 의존성은 필요해지는 시점에 추가한다(마이크, 위치, 푸시, QueryDSL 등은 미리 넣지 않는다). 인증용 `spring-boot-starter-security`와 jjwt는 승인되어 있다.
- 서버 시크릿은 클라이언트(Flutter)에 넣지 않는다.

## Change policy

- 요청받은 범위만 수정한다. 인접 코드를 개선하거나 리팩터링하지 않는다.
- 커밋 금지: `application-dev.yml`, `application-prod.yml`, `frontend/config/*.json`, 키·인증서. `.env`, `*.example` 파일을 추가하지 않는다.
- MVP BE 제외: 기억 열람·수정·삭제, Analytics, Cost Tracking, Safety Support, 이메일 인증, 비밀번호 찾기, 다기기 로그인.
