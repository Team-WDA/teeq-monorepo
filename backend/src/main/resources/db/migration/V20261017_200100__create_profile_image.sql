create table profile_image (
    id uuid primary key,
    member_id uuid not null,
    storage_key varchar(100) not null,
    content_type varchar(50) not null,
    file_size bigint not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint ck_profile_image_file_size check (file_size > 0),
    constraint fk_profile_image_member foreign key (member_id) references member (id)
);

create unique index uq_profile_image_member_active on profile_image (member_id) where deleted = false;
