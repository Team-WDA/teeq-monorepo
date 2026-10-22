create table bug_report (
    id uuid primary key,
    member_id uuid not null,
    content text not null,
    status varchar(20) not null,
    source varchar(30) not null,
    app_version varchar(50) not null,
    platform varchar(10) not null,
    os_version varchar(100) not null,
    device_model varchar(100) not null,
    error_logs_json text,
    network_logs_json text,
    omitted_error_log_count int not null default 0,
    omitted_network_log_count int not null default 0,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint fk_bug_report_member foreign key (member_id) references member (id)
);

create index idx_bug_report_status_created_at on bug_report (status, created_at desc);
create index idx_bug_report_source_created_at on bug_report (source, created_at desc);

create table bug_report_image (
    id uuid primary key,
    bug_report_id uuid not null,
    storage_key varchar(100) not null,
    content_type varchar(50) not null,
    file_size bigint not null,
    sort_order int not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint ck_bug_report_image_file_size check (file_size > 0),
    constraint fk_bug_report_image_bug_report foreign key (bug_report_id) references bug_report (id)
);

create index idx_bug_report_image_bug_report on bug_report_image (bug_report_id);
