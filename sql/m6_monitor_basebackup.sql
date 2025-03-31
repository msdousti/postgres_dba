SELECT
    a.datname AS database_name,
    p.pid,
    clock_timestamp() - a.query_start AS duration_so_far,
    a.application_name,
    a.client_addr,
    a.usename,
    coalesce(a.wait_event_type || '.' || a.wait_event, 'false') AS waiting,
    trim(TRAILING ';' FROM a.query) AS query,
    a.state,
    p.phase,
    CASE p.phase
    WHEN 'initializing' THEN
        '1 of 6'
    WHEN 'waiting for checkpoint to finish' THEN
        '2 of 6'
    WHEN 'estimating backup size' THEN
        '3 of 6'
    WHEN 'streaming database files' THEN
        '4 of 6'
    WHEN 'waiting for wal archiving to finish' THEN
        '5 of 6'
    WHEN 'transferring wal files' THEN
        '6 of 6'
    END AS phase_progress,
    format('%s (%s of %s)', coalesce(round(100.0 * p.backup_streamed / nullif (p.backup_total, 0), 2)::text || '%', 'not applicable'), p.backup_streamed::text, coalesce(p.backup_total::text, '0')) AS backup_progress,
    format('%s (%s of %s)', coalesce((100 * p.tablespaces_streamed / nullif (p.tablespaces_total, 0))::text || '%', 'not applicable'), p.tablespaces_streamed::text, p.tablespaces_total::text) AS tablespace_progress
FROM
    pg_stat_progress_basebackup AS p
    JOIN pg_stat_activity AS a ON a.pid = p.pid
ORDER BY
    clock_timestamp() - a.query_start DESC \gx
