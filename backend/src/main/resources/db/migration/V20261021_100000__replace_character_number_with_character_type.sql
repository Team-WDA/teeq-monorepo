-- 기존 데이터가 없어 컬럼을 지우고 다시 추가한다
alter table ai_character drop column character_number;
alter table ai_character add column character_type varchar(20) not null;
alter table ai_character add constraint ck_ai_character_character_type
    check (character_type in ('CHARACTER_1', 'CHARACTER_2', 'CHARACTER_3', 'CHARACTER_4', 'CHARACTER_5'));

alter table onboarding_submission drop column character_number;
alter table onboarding_submission add column character_type varchar(20) not null;
alter table onboarding_submission add constraint ck_onboarding_submission_character_type
    check (character_type in ('CHARACTER_1', 'CHARACTER_2', 'CHARACTER_3', 'CHARACTER_4', 'CHARACTER_5'));
