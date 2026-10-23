-- 이메일 로그인 제거: 앱 회원은 Apple, Google(Firebase)로만 가입한다. 기존 행은 사용자가 비운 DB를 전제로 한다.
-- 제약 삭제를 먼저 해야 이후 컬럼 변경과 새 제약 추가가 가능하다.
alter table member drop constraint ck_member_login_type;
alter table member drop constraint ck_member_login_method;
alter table member drop constraint ck_member_nickname_required;

drop index uq_member_email_active;

alter table member drop column password;

alter table member alter column nickname set not null;
alter table member alter column social_user_id set not null;

alter table member add constraint ck_member_login_type check (login_type in ('APPLE', 'GOOGLE'));
