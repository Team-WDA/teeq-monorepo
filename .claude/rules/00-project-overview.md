# Project Overview

## Purpose

- Product: AI 페르소나 기반 실시간 음성 동행 서비스. 사용자가 AI 캐릭터에게 실제 전화하듯 통화하고, 통화 → 기억 → 관계 → 재통화 루프로 관계를 쌓는다.
- Core vs Support: AI Companion이 Core Product이다. 귀갓길 Safety Support(지인 공유, 위치 공유, 위험 신호)는 Core 경험을 보강하는 보조 레이어이며, 서비스를 "안전 앱"으로 정의하지 않는다.
- Target: 20~30대 여성. 첫 핵심 사용 맥락은 "늦은 밤 혼자 집으로 이동하는 시간".
- North Star: Weekly Returning Callers (일주일 내 2회 이상 통화한 사용자 수/비율).
- Principles: 전화가 가장 먼저 보여야 한다 / Safety는 필요할 때 자연스럽게 나타난다 / 기능 수보다 반복 행동을 검증한다.
- Priority: Voice Latency > Conversation Quality > Persona Consistency > Memory > Context Awareness > Safety Support 신뢰성.
- Client scope: 기획서는 10월 Web MVP, 11월 Web+App을 서술하지만, 이 저장소의 클라이언트는 Flutter(android/ios)이며 Web은 범위 밖이다. 회사 대표 사이트(기능 없음)가 필요해지면 Spring MVC + Thymeleaf로 추가한다.
- Source of truth: 원문 기획서(`project.md`)는 저장소에 두지 않는다. 이 요약이 기준이다.

## MVP scope

- Core(P0): 간편 로그인(Google/Apple/카카오), 캐릭터 선택(든든한 언니, 찐친, 다정한 연인)과 최소 커스터마이즈(이름, 호칭, 말투),
  실시간 음성통화(STT → LLM → TTS, turn-taking, 사용자 끼어들기), Persona 일관성, Minimal Memory(통화 종료 후 구조화),
  최소 Context(현재 시간, 사용자가 선택한 상황), 통화 종료/재통화, Analytics, Cost Tracking.
- Safety Support(P0.5): 지인 등록/초대(초대받은 사람은 가입 없이 공유 세션 열람), 귀갓길 공유, 실시간 위치 공유, 사용자 직접 위험 신호,
  AI 위험 가능성 확인(사용자 확인 후에만 지인에게 알림).
- Out of scope: 112 자동 신고, 경찰 연결, 사용자 확인 없는 자동 지인 연락, 완전 자동 위험 판단, 정교한 음향 위험 분류, 영상통화, Voice Cloning, Marketplace, 결제/구독, B2B/B2G.
- Data model: User → Characters(Persona, Memory), Friends(Connection State), Call Sessions(Duration, Context, Cost), Journeys(Start/End, Shared Friends, Location Events, Risk Events).
- Cost tracking: 통화 Session별 STT·LLM 토큰·TTS·통화시간 비용을 기록한다.

## Glossary

- Character: 사용자가 선택하는 AI 통화 상대(관계 설정 포함).
- Persona: 캐릭터의 관계, 말투, 성격, 사용자 호칭 등 일관성을 유지할 설정.
- Memory: 통화 종료 후 구조화하는 사용자·관계 기억. 다음 통화에서 대화가 이어지게 한다.
- Call Session: 한 번의 AI 통화 기록(시간, Context, 비용, 재통화 여부).
- Journey: 귀갓길 공유 세션(시작/종료, 공유 지인, 위치 이벤트, 위험 신호).
- Friend: 귀갓길을 공유하는 실제 지인 관계.
- Context: 통화에 전달하는 상황 정보(시간, 이동 수단 등).

## Primary Stack

| 영역 | 기술 |
| --- | --- |
| Backend | Java 21, Spring Boot 4.1.x (`spring-boot-starter-webmvc`, 가상 스레드), Gradle Groovy DSL, 단일 모듈 |
| Database | PostgreSQL 17 단일 DB, Spring Data JPA, Flyway |
| Frontend | Flutter (android/ios), Riverpod, go_router, dio, freezed |
| Test | JUnit 6, Testcontainers(`postgres:17`), ArchUnit / flutter_test |
| CI/CD | `project-auto-wizard`(사용자가 나중에 적용), trunk-based(`main` 단일) |

## Important directories

- `backend/`: Spring Boot 앱. 소스 루트 `backend/src/main/java/com/chuseok22/aifriend`
- `frontend/`: Flutter 앱. `lib/core`, `lib/features`, 환경값 `frontend/config/`(gitignore)
- `scripts/sql/`: Flyway 파일명 검증 스크립트
- `.claude/rules/`: 프로젝트 규칙

## Main commands

- Backend build/test: `cd backend && ./gradlew build` (Docker 필요)
- Backend run: `cd backend && ./gradlew bootRun` (`application-dev.yml`을 채운 뒤)
- Frontend 준비: `cd frontend && flutter pub get && dart run build_runner build`
- Frontend 검증: `cd frontend && flutter analyze && flutter test`
- Frontend run: `cd frontend && flutter run --dart-define-from-file=config/dev.json`
- Flyway 파일명 검증: `scripts/sql/check_flyway_filenames.sh`

## Change policy

- 수정 범위: 요청받은 범위만 수정한다. 인접 코드를 개선하거나 리팩터링하지 않는다.
- 새 의존성: 필요해지는 시점에 추가하며, 미리 넣지 않는다(마이크, 위치, 푸시, springdoc, QueryDSL, security 등).
- 미확정 영역: 로그인 방식, 음성(STT/LLM/TTS) 파이프라인, 실시간 전송 방식(WebSocket 등)은 아직 정하지 않았다. 확정 전에는 임의로 구현하지 않는다.
