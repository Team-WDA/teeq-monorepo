-- 기존 데이터가 없어 기본값 없이 not null로 추가한다. end_reason은 사용량 보고(AI 서버)가 채운다
alter table call_history add column persona_id varchar(64) not null;
alter table call_history add column limit_kind varchar(20) not null
    constraint ck_call_history_limit_kind check (limit_kind in ('PER_CALL', 'PER_DAY', 'WHOLE_SERVICE'));
alter table call_history add column prompt_version varchar(100);
alter table call_history add column llm_model varchar(100);
alter table call_history add column end_reason varchar(30)
    constraint ck_call_history_end_reason check (end_reason in ('USER_HANGUP', 'USER_DISCONNECTED', 'LIMIT_REACHED', 'AGENT_ERROR', 'DISPATCH_FAILED'));
