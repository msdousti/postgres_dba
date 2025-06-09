--Monitor vacuum
-- Based on: https://dev.to/bolajiwahab/progress-reporting-in-postgresql-1i0d

select
    p.datname as database_name,
    p.pid,
    clock_timestamp() - a.xact_start as duration_so_far,
    a.application_name,
    a.client_addr,
    a.usename,
    coalesce(a.wait_event_type || '.' || a.wait_event, 'false') as waiting,
    trim(trailing ';' from a.query) as query,
    a.state,
    p.relid::regclass as table_name,
    pg_size_pretty(pg_relation_size(p.relid)) as table_size,
    pg_size_pretty(pg_total_relation_size(p.relid)) as total_table_size,
    case when ltrim(a.query) ~* '^autovacuum.to prevent wraparound' then
        'wraparound'
    when ltrim(a.query) ~ '^vacuum' then
        'user'
    else
        'regular'
    end as mode,
    p.phase,
    case p.phase
    when 'initializing' then
        '1 of 7'
    when 'scanning heap' then
        '2 of 7'
    when 'vacuuming indexes' then
        '3 of 7'
    when 'vacuuming heap' then
        '4 of 7'
    when 'cleaning up indexes' then
        '5 of 7'
    when 'truncating heap' then
        '6 of 7'
    when 'performing final cleanup' then
        '7 of 7'
    end as vacuum_phase_progress,
    format('%s (%s of %s)', coalesce(round(100.0 * p.heap_blks_scanned / nullif (p.heap_blks_total, 0), 2)::text || '%', 'not applicable'), p.heap_blks_scanned::text, p.heap_blks_total::text) as vacuum_scan_progress,
    format('%s (%s of %s)', coalesce(round(100.0 * p.heap_blks_vacuumed / nullif (p.heap_blks_total, 0), 2)::text || '%', 'not applicable'), p.heap_blks_vacuumed::text, p.heap_blks_total::text) as vacuum_progress,
    p.index_vacuum_count,
    p.max_dead_tuples,
    p.num_dead_tuples
from
    pg_stat_progress_vacuum as p
    join pg_stat_activity as a on a.pid = p.pid
order by
    clock_timestamp() - a.xact_start desc \gx
