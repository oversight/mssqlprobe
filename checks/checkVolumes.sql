SELECT DISTINCT
  vs.volume_mount_point,
  vs.file_system_type,
  vs.logical_volume_name as name,
  vs.total_bytes,
  vs.available_bytes,
  vs.total_bytes - vs.available_bytes as used_bytes,
  CONVERT(DECIMAL(18,2), (vs.total_bytes - vs.available_bytes) * 1. / vs.total_bytes * 100.) AS [percent_used]
FROM sys.master_files AS f WITH (NOLOCK)
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs
ORDER BY vs.volume_mount_point OPTION (RECOMPILE);