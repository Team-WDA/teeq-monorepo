---
paths:
  - "backend/**"
---

# Backend Domains

MVP BE의 도메인, 소유 테이블, 도메인별 규칙이다. 구조는 `10-backend-architecture.md`, 계정과 토큰은 `21-backend-auth.md`를 따른다. 화면(Figma)에서 읽은 기능을 기준으로 정했다.

## Scope

- BE가 맡는 것: 계정, 온보딩, 캐릭터 저장, 홈 조회, 통화 한도 검사와 사용 시간 기록, 피드백.
- BE가 맡지 않는 것: AI 기능 전체와 음성 통화. 통화 세션 생성, LiveKit 토큰 발급, 통화 시간 계산은 AI 서버(AI 개발자)가 하고 BE는 API로 호출하거나 호출받는다.
- 이번 MVP에서 제외: 기억(Memory) 열람·수정·삭제, Analytics, Cost Tracking, Safety(귀갓길·위치 공유), 프로필 사진, 소셜 로그인, 다기기 로그인.

## Domains

| 도메인 | 책임 | 소유 테이블(후보) |
| --- | --- | --- |
| member | 프로필(닉네임), 계정 엔티티 | member(약관 동의는 컬럼) |
| auth | 가입, 로그인, 토큰, 비밀번호 변경, 계정 삭제, 보안 설정 | refresh_token |
| character | 온보딩 응답, 캐릭터 | character, onboarding_answer |
| home | 홈 조회, 오늘의 한마디 | daily_message(하루 한 건) |
| call | 통화 한도 검사, 통화 사용 시간 기록 | 통화 사용 기록 테이블 |
| feedback | 통화 후 필수 피드백, 상세 피드백 | feedback_mandatory, feedback_detail |
| setting | 관리자가 수정하는 동적 설정(`setting_config`) | setting_config |

- 가입, 비밀번호 변경, 계정 삭제는 토큰 폐기와 얽혀 있어 `auth`에서 처리하며 `member`는 `auth`를 참조하지 않는다(`21-backend-auth.md`).
- 테이블 이름과 컬럼은 후보이며 Flyway 마이그레이션을 쓸 때 확정한다.
- 도메인 패키지는 구현할 때 만든다. 빈 패키지를 미리 만들지 않는다.

## Character and onboarding

- Question: 온보딩 질문은 7개다. 관계, 성격, 말투, 목소리, 고민 상담 스타일(T/F), 대화 주도, 피하고 싶은 대화 방식이다. 마지막의 캐릭터 이름 입력까지 한 번에 제출한다.
- Select: 6개는 단일 선택, 피하고 싶은 대화 방식만 복수 선택이다.
- Code: 질문과 선택지는 서버가 정의한 코드로 관리하고 BE는 코드를 검증만 한다. 화면 문구는 FE가 하드코딩한다. 코드 형식(teeq-docs의 `q1_1` 형태 `option_id` vs enum 이름)과 질문 순서는 온보딩 이슈(#4) 구현 때 정한다.
- Store: 사용자의 선택지를 DB에 저장한다. 복수 선택은 선택지마다 한 행으로 둔다.
- Overwrite: 재설정하면 이전 선택지를 덮어쓴다. 이력은 두지 않으므로 이 테이블은 기존 행을 삭제하고 다시 넣는 hard delete 예외다(soft delete 규칙의 이력성 데이터 예외).
- One per member: 캐릭터는 회원당 하나다.
- Name: 캐릭터 이름은 한글, 영문, 숫자 2~10자다.
- Open: 캐릭터 결정 방식(BE 규칙 기반 vs AI 서버가 번호 반환 vs FE 추천), 캐릭터 번호(사용자가 추후 제공), 성향 태그 도출 위치, 재설정 시 캐릭터 이름 입력 여부는 캐릭터 이슈(#5)와 AI 연동 이슈(#7) 구현 때 정한다.

## AI server integration

- Port: AI 서버 호출은 `core`에 port 인터페이스를 두고 `infrastructure`에 adapter를 둔다(`10-backend-architecture.md`).
- Status: AI 서버가 아직 구성되지 않았다. API 명세, 서버 간 인증 방식, 타임아웃, 에러 형식(AI 명세는 `{code, message}`, BE는 `{errorCode, errorMessage}`), BE DB와 AI DB의 데이터 소유 경계는 AI 서버 연결 때 정한다. 확정 전에는 adapter를 임의로 구현하지 않는다.
- Inbound: AI 서버가 BE를 호출한다(통화 사용 시간 등). 서버 간 인증은 `21-backend-auth.md`의 Server-to-server를 따른다. 참고: teeq-docs AI 명세는 Standard Webhooks(HMAC) 방식이다.

## Home

- Read: 홈은 캐릭터 정보와 오늘의 한마디를 조회해서 돌려준다.
- Greeting: 오늘의 한마디는 하루(KST) 한 번, 그날 첫 홈 진입 시 BE가 AI 서버에 생성을 요청해 저장하고 그날은 같은 문구를 쓴다(teeq-docs PRD HOM-17). 요청이 실패하거나 3초를 넘기면 고정 문구 9개 중 하나를 쓰고, 앞에 호칭을 BE가 붙인다. AI 서버의 요청 API가 정해지기 전에는 고정 문구만 쓴다.
- Login response: 로그인 응답과 내 정보 조회에서 캐릭터 보유 여부를 알려, FE가 온보딩과 홈 중 갈 곳을 정하게 한다. (character 도메인을 구현할 때 추가한다. 이번 이슈의 응답에는 없다)

## Call

- Scope: 통화 세션 생성, LiveKit 토큰 발급, 통화 시간 계산은 AI 서버가 한다. BE는 통화 시작 전 한도 검사와 AI 서버가 알려 주는 사용 시간 기록만 맡는다.
- Unit: 한도의 단위는 초다(teeq-docs PRD §7). 값은 `setting_config`의 동적 설정으로 둔다(아래 "Dynamic settings"). 키는 통화 한도 이슈에서 `SettingKey`에 추가한다. 1회 통화 1,200초, 사용자별 하루 1,800초, 남은 시간이 60초 미만이면 통화 시작을 거절한다.
- Reset: 하루 한도는 KST 0시에 리셋되고 통화 시작일 기준으로 센다. 시각은 `Clock` + `Instant`로 다룬다.
- Purpose: AI 무제한 호출을 막기 위한 사용자별 한도다.
- Out of scope: 잔액·충전(관리자 페이지에서 추가할 기능), 서비스 전체 월간 풀은 이번 범위에서 제외한다.
- Open: 한도 값 최종 확정, 에러 코드 이름(후보 `CALL_LIMIT_INSUFFICIENT`), 통화 세션 식별자 발급 주체, 동시 통화 1개 제한 담당, 사용 시간 수신 형식과 중복 수신 방지, 정리되지 않은 통화 처리는 통화 한도 이슈(#8) 구현 때 정한다.

## Feedback

- Basis: teeq-docs PRD 명세를 기준으로 한다. 문구와 선택지는 디자이너 확정에 맞춘다.
- Mandatory: 통화마다 한 건이고 건너뛸 수 없다. 별점 1~5, 재통화 의향(`no`/`neutral`/`yes`), 이전 통화 기억 여부(`remembered`/`unsure`/`no`, 통화 순번 2 이상에서만), 어색했던 순간(복수 선택: `cut`/`slow`/`context`/`repeat`/`none`, `none`은 단독 선택)이다.
- Detail: 통화 순번 3, 6, 9… 마다 초대한다. 타이밍, 성향 적합, 기억, 공감·신뢰(5점 척도 + 선택 사유), 자유 서술, 개인정보 편안함, 저장 편안함(5점 척도), 통화를 시작한 이유(복수 선택, 기타는 100자 이내)이다.
- Open: 통화 순번을 세는 기준, 상세 피드백 거절 기록과 재제안 규칙, 최종 문구와 선택지 코드는 피드백 이슈(#9) 구현 때 정한다.

## Dynamic settings

- Table: `setting_config`(`config_key` 활성 행 unique, `config_value` 문자열, `value_type` INT/BOOLEAN/STRING). 키 생성·삭제 API는 없다.
- Keys: 키는 코드 enum `SettingKey`가 정의한다(타입, 기본값, 설명, INT 최소·최대). 상수는 필요한 기능을 구현할 때 추가하며 지금은 0개다. 시드 값은 마이그레이션에 넣지 않는다.
- Read: 캐시 없이 읽을 때마다 DB를 조회하고, 행이 없으면 enum 기본값을 쓴다. 소비처는 `SettingConfigService.getInt/getBoolean/getString`을 쓴다(INT는 `long` 반환).
- Update: 관리자 API만 쓴다. `GET /api/admin/setting-configs`, `PATCH /api/admin/setting-configs/{key}`(본문 `{value}`). 정의되지 않은 키는 `SETTING_CONFIG_NOT_FOUND`, 타입·범위 위반은 `INVALID_SETTING_VALUE`다. 수정자와 이력은 저장하지 않는다.
- Candidate review: 새 도메인을 구현할 때 하드코딩하거나 `@ConfigurationProperties`로 둘 값(한도, 임계값, 기능 on/off, 고정 문구 등) 중 운영 중 바꿀 만한 것이 있는지 검토해 `SettingKey` 후보로 추천한다. 추가는 사용자 확인 후에 한다.
