create table ai_character (
    id uuid primary key,
    member_id uuid not null,
    name varchar(10) not null,
    character_number integer not null,
    personality_tag_1 varchar(50) not null,
    personality_tag_2 varchar(50) not null,
    personality_tag_3 varchar(50) not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint fk_ai_character_member foreign key (member_id) references member (id),
    constraint uq_ai_character_member unique (member_id)
);
