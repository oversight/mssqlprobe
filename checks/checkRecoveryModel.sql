SELECT
    db.[name],
    db.recovery_model_desc,
    db.state_desc,
    -- db.containment_desc, -- Version 10.x incompatible
    db.log_reuse_wait_desc,
    ls.cntr_value * 1024.0 AS [log_size_bytes],
    lu.cntr_value * 1024.0 AS [log_used_bytes],
    CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS [log_used_percentage],
    db.[compatibility_level],
    db.page_verify_option_desc,
    db.is_auto_create_stats_on,
    db.is_auto_update_stats_on,
    db.is_auto_update_stats_async_on,
    db.is_parameterization_forced,
    db.snapshot_isolation_state_desc,
    db.is_read_committed_snapshot_on,
    db.is_auto_close_on,
    db.is_auto_shrink_on,
    -- db.target_recovery_time_in_seconds, -- Version 10.x incompatible
    db.is_cdc_enabled,
    db.is_published,
    -- db.group_database_id, -- Version 10.x incompatible
    -- db.replica_id,  -- Version 10.x incompatible
    db.is_encrypted,
    de.encryption_state,
    de.percent_complete,
    de.key_algorithm,
    de.key_length
FROM 
    sys.databases AS db WITH (NOLOCK)
    INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)
    ON db.name = lu.instance_name
    INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK)
    ON db.name = ls.instance_name
    LEFT OUTER JOIN sys.dm_database_encryption_keys AS de WITH (NOLOCK)
    ON db.database_id = de.database_id
WHERE 
    lu.counter_name LIKE N'Log File(s) Used Size (KB)%'
    AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
    AND ls.cntr_value > 0 
OPTION (RECOMPILE);