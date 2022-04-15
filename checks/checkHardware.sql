IF CONVERT(INT, LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(MAX)), 2)) < 11
  EXECUTE sp_executesql N'SELECT
      ''system'' as [name],
      cpu_count,
      scheduler_count,
      hyperthread_ratio,
      cpu_count/hyperthread_ratio as [cpu_hyperthread_ratio],
      physical_memory_in_bytes AS [physical_memory_bytes],
      CONVERT(bigint, bpool_committed) * 1024 AS [committed_bytes],
      CONVERT(bigint, bpool_commit_target) * 1024 AS [committed_target_bytes],
      max_workers_count,
      affinity_type_desc,
      sqlserver_start_time,
      virtual_machine_type_desc
  FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE)';
ELSE
  EXECUTE sp_executesql N'SELECT
      ''system'' as [name],
      cpu_count,
      scheduler_count,
      hyperthread_ratio,
      cpu_count/hyperthread_ratio as [cpu_hyperthread_ratio],
      physical_memory_kb * 1024 AS [physical_memory_bytes],
      committed_kb * 1024 AS [committed_bytes],
      committed_target_kb * 1024 AS [committed_target_bytes],
      max_workers_count,
      affinity_type_desc,
      sqlserver_start_time,
      virtual_machine_type_desc
  FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE)';