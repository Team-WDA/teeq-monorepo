-- 기존 call_bonus 행은 없다는 전제(확인 완료)이므로 데이터 이관 없이 행위자 컬럼을 member에서 admin으로 교체한다
alter table call_bonus drop constraint fk_call_bonus_granted_by_member;
alter table call_bonus drop constraint fk_call_bonus_canceled_by_member;
alter table call_bonus drop column granted_by_member_id;
alter table call_bonus drop column canceled_by_member_id;

alter table call_bonus add column granted_by_admin_id uuid not null;
alter table call_bonus add column canceled_by_admin_id uuid;
alter table call_bonus add constraint fk_call_bonus_granted_by_admin foreign key (granted_by_admin_id) references admin (id);
alter table call_bonus add constraint fk_call_bonus_canceled_by_admin foreign key (canceled_by_admin_id) references admin (id);
