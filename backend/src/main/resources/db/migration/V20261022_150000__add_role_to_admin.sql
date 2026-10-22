alter table admin add column role text;

-- 기존 관리자는 모두 SUPER_ADMIN으로 승계한다
update admin set role = 'SUPER_ADMIN';

alter table admin alter column role set not null;

alter table admin add constraint ck_admin_role check (role in ('SUPER_ADMIN', 'ADMIN'));
