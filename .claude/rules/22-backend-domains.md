---
paths:
  - "backend/**"
---

# Backend Domains

MVP BE의 도메인, 소유 테이블, 도메인별 규칙이다. 구조는 `10-backend-architecture.md`, 계정과 토큰은 `21-backend-auth.md`를 따른다. 화면(Figma)에서 읽은 기능을 기준으로 정했다.

## Scope

- BE가 맡는 것: 계정, 온보딩, 캐릭터 저장, 홈 조회, 통화 사용 토큰, 피드백.
- BE가 맡지 않는 것: AI 기능 전체와 음성 통화. AI 서버(AI 개발자)가 파이프라인을 구성하고 BE는 API로 호출하거나 호출받는다. 음성 연결은 FE와 AI 서버가 직접 한다.
- 이번 MVP에서 제외: 기억(Memory) 열람·수정·삭제, Analytics, Cost Tracking, Safety(귀갓길·위치 공유), 프로필 사진, 소셜 로그인, 다기기 로그인.

## Domains

| 도메인 | 책임 | 소유 테이블(후보) |
| --- | --- | --- |
| member | 계정, 닉네임, 약관 동의 | member, terms_agreement |
| auth | 로그인, 토큰, 보안 설정 | refresh_token |
| character | 온보딩 응답, 캐릭터 | character, onboarding_answer |
| home | 홈 조회 | 없음(조회 전용) |
| call | 통화 세션, 통화 사용 토큰 | call_session, 사용 토큰 테이블 |
| feedback | 통화 후 피드백, 추가 피드백 | call_feedback, extra_feedback, extra_feedback_suggestion |

- 테이블 이름과 컬럼은 후보이며 Flyway 마이그레이션을 쓸 때 확정한다.
- 도메인 패키지는 구현할 때 만든다. 빈 패키지를 미리 만들지 않는다.

## Character and onboarding

- Question: 온보딩 질문은 7개다. 관계, 성격, 말투, 목소리, 고민 상담 스타일(T/F), 대화 주도, 피하고 싶은 대화 방식이다. 마지막의 캐릭터 이름 입력까지 한 번에 제출한다.
- Select: 6개는 단일 선택, 피하고 싶은 대화 방식만 복수 선택이다.
- Enum: 질문과 선택지는 서버 enum으로 관리하고 BE는 코드를 검증만 한다. 화면 문구는 FE가 하드코딩한다. enum 이름은 구현할 때 정한다.
- Store: 사용자의 선택지를 DB에 저장한다. 복수 선택은 선택지마다 한 행으로 둔다.
- Overwrite: 재설정하면 이전 선택지를 덮어쓴다. 이력은 두지 않으므로 이 테이블은 기존 행을 삭제하고 다시 넣는 hard delete 예외다(soft delete 규칙의 이력성 데이터 예외).
- One per member: 캐릭터는 회원당 하나다.
- Character number: BE가 답변을 취합해 AI 서버를 호출하고, AI 서버가 반환한 캐릭터 번호를 저장한다. 외형과 성격 태그는 AI 서버가 결정한다.
- Open: 호출이 동기인지 비동기인지, 응답 형식(성격 태그 포함 여부), 재설정 시 캐릭터 이름 입력 여부는 AI 서버 명세와 디자이너 확인 후 정한다.

## AI server integration

- Port: AI 서버 호출은 `core`에 port 인터페이스를 두고 `infrastructure`에 adapter를 둔다(`10-backend-architecture.md`).
- Status: AI 서버가 아직 구성되지 않았다. API 명세, 인증 방식, 타임아웃과 에러 규약, 장애 시 BE의 동작은 미정이다. 확정 전에는 adapter를 임의로 구현하지 않는다.
- Inbound: 통화 종료 시 AI 서버가 BE를 호출한다. 서버 간 인증은 `21-backend-auth.md`의 Server-to-server를 따른다.

## Home

- Read: 홈은 캐릭터 정보와 BE에 저장된 인사말을 조회해서 돌려준다. 홈을 열 때마다 AI 서버를 호출하지 않는다.
- Greeting: 인사말은 통화 종료 시 AI 서버가 BE를 호출해 전달하는 것으로 가정한다. 종료 호출에 포함할지와 저장 위치는 AI 명세 후 정한다.
- Login response: 로그인 응답과 내 정보 조회에서 캐릭터 보유 여부를 알려, FE가 온보딩과 홈 중 갈 곳을 정하게 한다.

## Call

- Flow: FE가 BE에 통화 시작을 요청하면 BE가 사용 토큰 잔여를 확인해 허용 여부를 알려준다. 음성 연결은 FE와 AI 서버가 직접 한다. 종료와 사용량은 AI 서버가 BE에 보고하고, BE가 사용 토큰을 차감한다.
- Unit: 사용 토큰의 단위는 분이다.
- Purpose: AI 무제한 호출을 막기 위한 사용자별 한도다.
- Counted: 최소 통화 시간(초기값 30초, 설정값) 이상인 통화만 통화로 인정한다. 피드백 횟수 판정에도 이 기준을 쓴다.
- Open: 한도 값, 충전과 리셋 방식, 하루 경계, 연결 실패나 재연결 시 차감 규칙, 중복 보고 방지는 정책 명세 후 정한다.

## Feedback

- Post-call: 통화마다 한 건이다. 항목은 만족도(별 1~5), 재통화 의향(아니요, 보통이에요, 네 좋아요), 어색했던 순간(복수 선택: 말이 끊겼어요, 답이 늦었어요, 맥락이 달랐어요, 반복했어요, 없었어요)이다.
- Memory question: 인정된 통화가 두 번째부터는 "지난 대화를 기억했는지"(기억했어요, 잘 모르겠어요, 아니요)가 추가된다. 첫 통화에는 없다.
- Optional: 피드백은 제출하지 않아도 된다.
- Extra: 세 번째 인정 통화 후 BE가 추가 피드백 제안 여부를 판정해 응답에 플래그로 알려준다. 거절하면 다시 제안하지 않으므로 제안 이력(제안일, 응답 여부)을 저장한다.
- Extra answer: 1~5점 문항 3개(대화 타이밍, 성격과 말투, 기억과 이어감)와 각 문항의 선택 사유 한 줄이다. 기억 문항에는 "평가하기 어려워요" 체크가 있다. 정확한 문항 구성은 구현할 때 화면 기준으로 확정한다.
