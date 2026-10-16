create table onboarding_answer (
    id uuid primary key,
    member_id uuid not null,
    question_code varchar(50) not null,
    option_code varchar(50) not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint fk_onboarding_answer_member foreign key (member_id) references member (id),
    constraint uq_onboarding_answer_member_option unique (member_id, option_code)
);
