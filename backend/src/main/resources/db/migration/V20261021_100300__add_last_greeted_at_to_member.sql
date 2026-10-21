-- AI가 홈 한마디를 마지막으로 정상 생성한 시각. 한 번도 없으면 null이다
alter table member add column last_greeted_at timestamptz;
