alter table app.users
    add column if not exists email_verified boolean not null default true;

create table if not exists app.email_action_token (
    id bigserial primary key,
    user_id bigint not null references app.users(id) on delete cascade,
    token_type varchar(30) not null,
    token varchar(255) not null unique,
    expires_at timestamptz not null,
    used_at timestamptz null,
    created_at timestamptz not null
);

create index if not exists idx_email_action_token_user_type_used
    on app.email_action_token (user_id, token_type, used_at);

create index if not exists idx_email_action_token_expires
    on app.email_action_token (expires_at);
