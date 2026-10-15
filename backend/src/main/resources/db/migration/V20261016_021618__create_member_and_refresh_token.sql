create table member (
    id uuid primary key,
    email text not null,
    password text not null,
    nickname text not null,
    role text not null,
    service_terms_agreed boolean not null,
    privacy_policy_agreed boolean not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint ck_member_role check (role in ('USER', 'ADMIN'))
);

create unique index uq_member_email_active on member (email) where deleted = false;
create unique index uq_member_nickname_active on member (lower(nickname)) where deleted = false;

create table refresh_token (
    id uuid primary key,
    member_id uuid not null,
    token text not null,
    expires_at timestamptz not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint uq_refresh_token_member unique (member_id),
    constraint fk_refresh_token_member foreign key (member_id) references member (id)
);
