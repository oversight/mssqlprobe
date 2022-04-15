SELECT TOP(25) 
    DB_NAME(t.[dbid]) AS [database_name], 
    master.dbo.fn_varbintohexstr(plan_handle) AS [name],
    SUBSTRING(t.[text],qs.statement_start_offset/2 + 1, (
      CASE WHEN qs.statement_end_offset = -1
         THEN LEN(CONVERT(nvarchar(max), t.[text])) * 2
      ELSE
         qs.statement_end_offset
      END - qs.statement_start_offset
    )/2 + 1) AS query,
    qs.total_worker_time / 1000000.0 AS [total_worker_time],
    qs.min_worker_time / 1000000.0 AS [min_worker_time],
    qs.total_worker_time  / 1000000.0 / qs.execution_count AS [avg_worker_time],
    qs.max_worker_time / 1000000.0 AS [max_worker_time],
    qs.min_elapsed_time / 1000000.0 AS [min_elapsed_time],
    qs.total_elapsed_time / 1000000.0 / qs.execution_count AS [avg_elapsed_time],
    qs.max_elapsed_time / 1000000.0 AS [max_elapsed_time],
    qs.min_logical_reads AS [min_logical_reads],
    qs.total_logical_reads/qs.execution_count AS [avg_logical_reads],
    qs.max_logical_reads AS [max_logical_reads],
    qs.execution_count AS [execution_count], 
    qs.creation_time
FROM 
    sys.dm_exec_query_stats AS qs WITH (NOLOCK)
    CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
WHERE
    t.[text] IS NOT NULL
ORDER BY 
    qs.total_worker_time DESC 
OPTION (RECOMPILE);