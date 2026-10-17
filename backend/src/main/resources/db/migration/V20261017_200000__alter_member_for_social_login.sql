alter table member add column login_type text not null default 'EMAIL';
alter table member alter column login_type drop default;
alter table member add column social_user_id text;
alter table member alter column password drop not null;

alter table member add constraint ck_member_login_type check (login_type in ('EMAIL', 'APPLE'));
alter table member add constraint ck_member_login_method check (
    (login_type = 'EMAIL' and password is not null and social_user_id is null)
    or (login_type = 'APPLE' and password is null and social_user_id is not null)
);

create unique index uq_member_social_active on member (login_type, social_user_id)
    where deleted = false and social_user_id is not null;
