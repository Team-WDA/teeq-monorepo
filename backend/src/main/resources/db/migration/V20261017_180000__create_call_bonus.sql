create table call_bonus (
    id uuid primary key,
    member_id uuid not null,
    bonus_date date not null,
    seconds integer not null,
    reason varchar(200) not null,
    granted_by_member_id uuid not null,
    canceled_by_member_id uuid,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint ck_call_bonus_seconds check (seconds > 0),
    constraint fk_call_bonus_member foreign key (member_id) references member (id),
    constraint fk_call_bonus_granted_by_member foreign key (granted_by_member_id) references member (id),
    constraint fk_call_bonus_canceled_by_member foreign key (canceled_by_member_id) references member (id)
);

create index ix_call_bonus_member_date_active on call_bonus (member_id, bonus_date) where deleted = false;

create index ix_call_history_started_active on call_history (started_at) where deleted = false;
