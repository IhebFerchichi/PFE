create table if not exists app.chart_marker (
    id bigserial primary key,
    pack_type varchar(20) not null,
    bms_id varchar(100) not null,
    chart_key varchar(80) not null,
    cell_index smallint null,
    marked_at timestamptz not null,
    created_by varchar(255) not null,
    created_at timestamptz not null
);

create index if not exists idx_chart_marker_pack_bms_marked_at
    on app.chart_marker (pack_type, bms_id, marked_at);
