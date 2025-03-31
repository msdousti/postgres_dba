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
    case when ltrim(a.query) ~* '^analyze' then
        'user'
    else
        'regular'
    end as mode,
    p.phase,
    case p.phase
    when 'initializing' then
        '1 of 6'
    when 'acquiring sample rows' then
        '2 of 6'
    when 'acquiring inherited sample rows' then
        '3 of 6'
    when 'computing statistics' then
        '4 of 6'
    when 'computing extended statistics' then
        '5 of 6'
    when 'finalizing analyze' then
        '6 of 6'
    end as phase_progress,
    format('%s (%s of %s)', coalesce(round(100.0 * p.sample_blks_scanned / nullif (p.sample_blks_total, 0), 2)::text || '%', 'not applicable'), p.sample_blks_scanned::text, p.sample_blks_total::text) as scan_progress,
    format('%s (%s of %s)', coalesce((100 * p.ext_stats_computed / nullif (p.ext_stats_total, 0))::text || '%', 'not applicable'), p.ext_stats_computed::text, p.ext_stats_total::text) as extended_statistics_progress,
    format('%s (%s of %s)', coalesce((100 * p.ext_stats_computed / nullif (p.child_tables_total, 0))::text || '%', 'not applicable'), p.child_tables_done::text, p.child_tables_total::text) as child_tables_progress,
    current_child_table_relid::regclass as current_child_table
from
    pg_stat_progress_analyze as p
    join pg_stat_activity as a on a.pid = p.pid
order by
    clock_timestamp() - a.xact_start desc \gx
