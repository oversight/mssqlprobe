--EXEC sp_help_log_shipping_monitor requires more access and appears to return less data
select
    s.secondary_id,
    s.primary_server,
    s.primary_database,
    s.backup_source_directory,
    s.backup_destination_directory,
    s.file_retention_period,
    s.copy_job_id,
    s.restore_job_id,
    case
        when (s.user_specified_monitor = 1) then s.monitor_server
        else cast(NULL as sysname)
    end AS monitor_server,
    case
        when (s.user_specified_monitor = 1) then s.monitor_server_security_mode
        else cast(NULL as bit)
    end AS monitor_server_security_mode,
    sd.secondary_database,
    sd.restore_delay,
    sd.restore_all,
    sd.restore_mode,
    sd.disconnect_users,
    sd.block_size,
    sd.buffer_count,
    sd.max_transfer_size,
    sm.restore_threshold,
    sm.threshold_alert,
    sm.threshold_alert_enabled,
    sm.last_copied_file,
    sm.last_copied_date,
    sm.last_copied_date_utc,
    sm.last_restored_file,
    sm.last_restored_date,
    sm.last_restored_date_utc,
    sm.history_retention_period,
    sm.last_restored_latency,
    CASE
        WHEN threshold_alert_enabled = 0 THEN 0
        WHEN DATEDIFF(minute, sm.last_restored_date_utc, GETUTCDATE()) > sm.restore_threshold THEN 1
        ELSE 0
    END AS alert
from ((msdb.dbo.log_shipping_secondary as s join msdb.dbo.log_shipping_secondary_databases as sd
        on s.secondary_id = sd.secondary_id)
    join msdb.dbo.log_shipping_monitor_secondary as sm on sd.secondary_id = sm.secondary_id
        and sd.secondary_database = sm.secondary_database
        and s.primary_server = sm.primary_server
        and s.primary_database = sm.primary_database)
