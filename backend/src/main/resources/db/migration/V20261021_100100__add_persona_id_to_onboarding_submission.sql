-- 기존 데이터가 없어 기본값 없이 not null로 추가한다
alter table onboarding_submission add column persona_id varchar(64) not null;
