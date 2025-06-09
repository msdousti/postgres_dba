--Monitor copy
-- Based on: https://dev.to/bolajiwahab/progress-reporting-in-postgresql-1i0d

select
    p.datname as database_name,
    p.pid,
    clock_timestamp() - a.xact_start as duration_so_far,
    a.application_name,
    a.client_addr,
    a.usename,
    coalesce(a.wait_event_type || '.' || a.wait_event, 'false') as waiting,
    p.command,
    p.type,
    trim(trailing ';' from a.query) as query,
    a.state,
    p.relid::regclass as table_name,
    coalesce(pg_size_pretty(pg_relation_size(p.relid)), '-') as table_size,
    coalesce(pg_size_pretty(pg_total_relation_size(p.relid)), '-') as total_table_size,
    format('%s (%s of %s)', coalesce(round(100.0 * p.bytes_processed / nullif (p.bytes_total, 0), 2)::text || '%', 'not applicable'), p.bytes_processed::text, p.bytes_total::text) as bytes_progress,
    p.tuples_processed,
    p.tuples_excluded
from
    pg_stat_progress_copy as p
    join pg_stat_activity as a on a.pid = p.pid
order by
    clock_timestamp() - a.xact_start desc \gx
