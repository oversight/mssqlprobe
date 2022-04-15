-- table reports micro seconds: https://msdn.microsoft.com/en-us/library/ms189741.aspx
SELECT TOP 25
    master.dbo.fn_varbintohexstr(plan_handle) as name,
    DB_NAME(t.[dbid]) AS [database_name], 
    t.[text] AS [query],
    qs.total_logical_reads,
    qs.min_logical_reads,
    qs.total_logical_reads/qs.execution_count AS [avg_logical_reads],
    qs.max_logical_reads,
    qs.min_worker_time / 1000000.0 [min_worker_time],
    qs.total_worker_time / 1000000.0 / qs.execution_count AS [avg_worker_time],
    qs.max_worker_time / 1000000.0 AS [max_worker_time],
    qs.min_elapsed_time / 1000000.0 AS [min_elapsed_time],
    qs.total_elapsed_time / 1000000.0 / qs.execution_count AS [avg_elapsed_time],
    qs.max_elapsed_time / 1000000.0 AS [max_elapsed_time],
    qs.execution_count, 
    qs.creation_time 
FROM 
    sys.dm_exec_query_stats as qs
    CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) AS t
WHERE 
    t.text is not null
ORDER BY 
    qs.total_logical_reads DESC
OPTION (RECOMPILE)
