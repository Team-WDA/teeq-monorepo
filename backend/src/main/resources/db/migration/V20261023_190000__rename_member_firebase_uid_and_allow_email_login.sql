-- 회원 조회 키를 firebase_uid 하나로 통일하고 이메일/비밀번호(Firebase password 제공자) 로그인을 허용한다.
-- 컬럼 이름만 바꾸면 인덱스 구성이 그대로이므로 인덱스는 삭제 후 다시 만든다.
drop index uq_member_social_active;

alter table member rename column social_user_id to firebase_uid;

create unique index uq_member_firebase_uid_active on member (firebase_uid) where deleted = false;

alter table member drop constraint ck_member_login_type;
alter table member add constraint ck_member_login_type check (login_type in ('APPLE', 'GOOGLE', 'EMAIL'));
