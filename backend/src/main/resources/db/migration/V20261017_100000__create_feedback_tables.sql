create table required_feedback (
    id uuid primary key,
    call_history_id uuid not null,
    rating integer not null,
    revisit_intention varchar(20) not null,
    previous_call_recall varchar(20),
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint ck_required_feedback_rating check (rating between 1 and 5),
    constraint ck_required_feedback_revisit_intention check (revisit_intention in ('NO', 'NEUTRAL', 'YES')),
    constraint ck_required_feedback_previous_call_recall
        check (previous_call_recall in ('REMEMBERED', 'UNSURE', 'NO')),
    constraint fk_required_feedback_call_history foreign key (call_history_id) references call_history (id)
);

create unique index uq_required_feedback_call_history_active on required_feedback (call_history_id)
    where deleted = false;

create table required_feedback_awkward_moment (
    id uuid primary key,
    required_feedback_id uuid not null,
    awkward_moment varchar(20) not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint ck_required_feedback_awkward_moment
        check (awkward_moment in ('CUT', 'SLOW', 'CONTEXT', 'REPEAT', 'NONE')),
    constraint fk_required_feedback_awkward_moment_required_feedback
        foreign key (required_feedback_id) references required_feedback (id)
);

create unique index uq_required_feedback_awkward_moment_active
    on required_feedback_awkward_moment (required_feedback_id, awkward_moment) where deleted = false;

create table detailed_feedback (
    id uuid primary key,
    call_history_id uuid not null,
    timing_score integer not null,
    timing_reason varchar(100),
    persona_fit_score integer not null,
    persona_fit_reason varchar(100),
    memory_score integer,
    memory_reason varchar(100),
    memory_not_applicable boolean not null,
    empathy_trust_score integer not null,
    empathy_trust_reason varchar(100),
    personal_comfort_score integer not null,
    personal_comfort_reason varchar(100),
    storage_comfort_score integer not null,
    storage_comfort_reason varchar(100),
    free_text varchar(1000),
    start_reason_other_text varchar(100),
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint ck_detailed_feedback_timing_score check (timing_score between 1 and 5),
    constraint ck_detailed_feedback_persona_fit_score check (persona_fit_score between 1 and 5),
    constraint ck_detailed_feedback_memory_score check (memory_score between 1 and 5),
    constraint ck_detailed_feedback_empathy_trust_score check (empathy_trust_score between 1 and 5),
    constraint ck_detailed_feedback_personal_comfort_score check (personal_comfort_score between 1 and 5),
    constraint ck_detailed_feedback_storage_comfort_score check (storage_comfort_score between 1 and 5),
    constraint ck_detailed_feedback_memory_not_applicable
        check (not memory_not_applicable or (memory_score is null and memory_reason is null)),
    constraint fk_detailed_feedback_call_history foreign key (call_history_id) references call_history (id)
);

create unique index uq_detailed_feedback_call_history_active on detailed_feedback (call_history_id)
    where deleted = false;

create table detailed_feedback_start_reason (
    id uuid primary key,
    detailed_feedback_id uuid not null,
    start_reason varchar(30) not null,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    deleted boolean not null default false,
    deleted_at timestamptz,
    constraint ck_detailed_feedback_start_reason check (start_reason in (
        'NEED_TO_TALK', 'WANT_TO_CONFIDE', 'BORED_OR_LONELY', 'CURIOUS_ABOUT_CHARACTER', 'TESTING_SERVICE', 'OTHER'
    )),
    constraint fk_detailed_feedback_start_reason_detailed_feedback
        foreign key (detailed_feedback_id) references detailed_feedback (id)
);

create unique index uq_detailed_feedback_start_reason_active
    on detailed_feedback_start_reason (detailed_feedback_id, start_reason) where deleted = false;
