alter table call_history alter column call_session_id drop not null;

alter table call_history add column status varchar(20) not null default 'ENDED';
alter table call_history alter column status drop default;
alter table call_history add column ended_at timestamptz;

alter table call_history add constraint ck_call_history_status
    check (status in ('PENDING', 'IN_PROGRESS', 'ENDED', 'FAILED', 'EXPIRED'));

create unique index uq_call_history_member_in_progress on call_history (member_id)
    where deleted = false and status in ('PENDING', 'IN_PROGRESS');
