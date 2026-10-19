-- 관리자 계정은 admin 테이블로 분리됐다. member에 ADMIN 행이 없다는 것은 사용자가 확인했다.
alter table member drop constraint ck_member_role;
alter table member add constraint ck_member_role check (role in ('USER'));
