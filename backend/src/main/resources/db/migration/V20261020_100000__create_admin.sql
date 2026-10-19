create table admin (
    id uuid primary key,
    username text not null,
    password text not null,
    name text not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz
);

create unique index uq_admin_username_active on admin (username) where deleted = false;
