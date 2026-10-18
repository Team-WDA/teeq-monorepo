alter table member alter column nickname drop not null;

alter table member add constraint ck_member_nickname_required check (nickname is not null or login_type <> 'EMAIL');
