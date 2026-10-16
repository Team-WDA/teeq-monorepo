create table setting_config (
    id uuid primary key,
    config_key text not null,
    config_value text not null,
    value_type text not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint ck_setting_config_value_type check (value_type in ('INT', 'BOOLEAN', 'STRING'))
);

create unique index uq_setting_config_key_active on setting_config (config_key) where deleted = false;
