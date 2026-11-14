alter table call_history drop constraint ck_call_history_status;
alter table call_history add constraint ck_call_history_status
    check (status in ('PENDING', 'IN_PROGRESS', 'ENDED', 'FAILED', 'EXPIRED', 'CANCELLED'));
