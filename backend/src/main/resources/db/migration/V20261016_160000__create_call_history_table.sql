create table call_history (
    id uuid primary key,
    member_id uuid not null,
    call_session_id varchar(64) not null,
    started_at timestamptz not null,
    duration_seconds integer not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint ck_call_history_duration check (duration_seconds >= 0),
    constraint fk_call_history_member foreign key (member_id) references member (id)
);

create unique index uq_call_history_session_active on call_history (call_session_id) where deleted = false;
create index ix_call_history_member_started_active on call_history (member_id, started_at) where deleted = false;
