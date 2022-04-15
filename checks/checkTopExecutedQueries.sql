SELECT TOP (25)
  master.dbo.fn_varbintohexstr(plan_handle) AS [name],
  DB_NAME(t.[dbid]) AS [database_name],
  SUBSTRING(t.[text],qs.statement_start_offset/2 + 1, (
      CASE WHEN qs.statement_end_offset = -1
         THEN LEN(CONVERT(nvarchar(max), t.[text])) * 2
      ELSE
         qs.statement_end_offset
      END - qs.statement_start_offset
  )/2 + 1) AS query,
  qs.execution_count,
  qs.total_logical_reads,
  qs.total_logical_reads / qs.execution_count AS [avg_logical_reads],
  qs.total_worker_time / 1000000.0 AS [total_worker_time],
  qs.total_worker_time / 1000000.0 /qs.execution_count AS [avg_worker_time],
  qs.total_elapsed_time / 1000000.0 AS [total_elapsed_time],
  qs.total_elapsed_time / 1000000.0 / qs.execution_count AS [avg_elapsed_time],
  qs.creation_time
FROM
  sys.dm_exec_query_stats AS qs WITH (NOLOCK)
  CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
  CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
ORDER BY
  qs.execution_count DESC OPTION (RECOMPILE);