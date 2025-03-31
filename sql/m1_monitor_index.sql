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
    p.index_relid::regclass as index_name,
    p.relid::regclass as table_name,
    pg_size_pretty(pg_relation_size(p.relid)) as table_size,
    p.phase,
    case p.phase
    when 'initializing' then
        '1 of 12'
    when 'waiting for writers before build' then
        '2 of 12'
    when 'building index: scanning table' then
        '3 of 12'
    when 'building index: sorting live tuples' then
        '4 of 12'
    when 'building index: loading tuples in tree' then
        '5 of 12'
    when 'waiting for writers before validation' then
        '6 of 12'
    when 'index validation: scanning index' then
        '7 of 12'
    when 'index validation: sorting tuples' then
        '8 of 12'
    when 'index validation: scanning table' then
        '9 of 12'
    when 'waiting for old snapshots' then
        '10 of 12'
    when 'waiting for readers before marking dead' then
        '11 of 12'
    when 'waiting for readers before dropping' then
        '12 of 12'
    end as phase_progress,
    format('%s (%s of %s)', coalesce(round(100.0 * p.blocks_done / nullif (p.blocks_total, 0), 2)::text || '%', 'not applicable'), p.blocks_done::text, p.blocks_total::text) as scan_progress,
    format('%s (%s of %s)', coalesce(round(100.0 * p.tuples_done / nullif (p.tuples_total, 0), 2)::text || '%', 'not applicable'), p.tuples_done::text, p.tuples_total::text) as tuples_loading_progress,
    format('%s (%s of %s)', coalesce((100 * p.lockers_done / nullif (p.lockers_total, 0))::text || '%', 'not applicable'), p.lockers_done::text, p.lockers_total::text) as lockers_progress,
    format('%s (%s of %s)', coalesce((100 * p.partitions_done / nullif (p.partitions_total, 0))::text || '%', 'not applicable'), p.partitions_done::text, p.partitions_total::text) as partitions_progress,
    p.current_locker_pid,
    trim(trailing ';' from l.query) as current_locker_query
from
    pg_stat_progress_create_index as p
    join pg_stat_activity as a on a.pid = p.pid
    left join pg_stat_activity as l on l.pid = p.current_locker_pid
order by
    clock_timestamp() - a.xact_start desc \gx
