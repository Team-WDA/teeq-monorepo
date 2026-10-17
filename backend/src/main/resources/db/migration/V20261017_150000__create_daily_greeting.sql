create table daily_greeting (
    id uuid primary key,
    member_id uuid not null,
    greeting_date date not null,
    message varchar(200) not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint fk_daily_greeting_member foreign key (member_id) references member (id)
);

create unique index uq_daily_greeting_member_date_active
    on daily_greeting (member_id, greeting_date)
    where deleted = false;
