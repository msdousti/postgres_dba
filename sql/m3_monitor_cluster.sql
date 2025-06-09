--Monitor cluster & vacuum full
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
    trim(trailing ';' from a.query) as query,
    a.state,
    p.relid::regclass as table_name,
    p.phase,
    case p.phase
    when 'initializing' then
        '1 of 8'
    when 'seq scanning heap' then
        '2 of 8'
    when 'index scanning heap' then
        '3 of 8'
    when 'sorting tuples' then
        '4 of 8'
    when 'writing new heap' then
        '5 of 8'
    when 'swapping relation files' then
        '6 of 8'
    when 'rebuilding index' then
        '7 of 8'
    when 'performing final cleanup' then
        '7 of 8'
    end as vacuum_phase_progress,
    cluster_index_relid::regclass as cluster_index,
    format('%s (%s of %s)', coalesce(round(100.0 * p.heap_blks_scanned / nullif (p.heap_blks_total, 0), 2)::text || '%', 'not applicable'), p.heap_blks_scanned::text, p.heap_blks_total::text) as heap_scan_progress,
    format('%s (%s of %s)', coalesce(round(100.0 * p.heap_tuples_written / nullif (p.heap_tuples_scanned, 0), 2)::text || '%', 'not applicable'), p.heap_tuples_written::text, p.heap_tuples_scanned::text) as heap_tuples_written_progress,
    p.index_rebuild_count
from
    pg_stat_progress_cluster as p
    join pg_stat_activity as a on a.pid = p.pid
order by
    clock_timestamp() - a.xact_start desc \gx
