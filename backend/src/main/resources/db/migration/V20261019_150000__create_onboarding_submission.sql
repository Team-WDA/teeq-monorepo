create table onboarding_submission (
    id uuid primary key,
    member_id uuid not null,
    character_number integer not null,
    personality_tag_1 varchar(50) not null,
    personality_tag_2 varchar(50) not null,
    personality_tag_3 varchar(50) not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint fk_onboarding_submission_member foreign key (member_id) references member (id)
);

create index ix_onboarding_submission_member_created on onboarding_submission (member_id, created_at);

alter table onboarding_answer add column submission_id uuid;

-- 회원별 활성 답변 한 묶음을 제출 1건으로 옮긴다. 캐릭터 값은 현재 ai_character에서 가져온다
insert into onboarding_submission (id, member_id, character_number, personality_tag_1, personality_tag_2,
    personality_tag_3, created_at, updated_at)
select gen_random_uuid(), c.member_id, c.character_number, c.personality_tag_1, c.personality_tag_2,
    c.personality_tag_3, min(a.created_at), min(a.created_at)
from onboarding_answer a
join ai_character c on c.member_id = a.member_id
where a.deleted = false
group by c.member_id, c.character_number, c.personality_tag_1, c.personality_tag_2, c.personality_tag_3;

update onboarding_answer a
set submission_id = s.id
from onboarding_submission s
where s.member_id = a.member_id and a.deleted = false;

-- 캐릭터가 없어 이전하지 못한 개발 데이터 답변은 지운다(운영 데이터 없음)
delete from onboarding_answer where submission_id is null;

alter table onboarding_answer alter column submission_id set not null;
alter table onboarding_answer add constraint fk_onboarding_answer_submission
    foreign key (submission_id) references onboarding_submission (id);
create index ix_onboarding_answer_submission on onboarding_answer (submission_id);

alter table onboarding_answer drop constraint uq_onboarding_answer_member_option;
create unique index uq_onboarding_answer_member_option_active
    on onboarding_answer (member_id, option_code) where deleted = false;
