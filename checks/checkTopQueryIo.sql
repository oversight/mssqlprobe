SELECT TOP(25) 
    master.dbo.fn_varbintohexstr(plan_handle) AS [name],
    DB_NAME(qt.[dbid]) AS [database_name],
    OBJECT_NAME(qt.objectid, dbid) AS [sp_name],
    (qs.total_logical_reads + qs.total_logical_writes) /qs.execution_count AS [avg_io],
    qs.execution_count,
    SUBSTRING(qt.[text],qs.statement_start_offset/2, (
        CASE WHEN qs.statement_end_offset = -1
           THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2
        ELSE 
           qs.statement_end_offset
        END - qs.statement_start_offset
    )/2 ) AS [query_text]
FROM 
    sys.dm_exec_query_stats AS qs
    WITH (NOLOCK)
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE
    DB_NAME(qt.[dbid]) IS NOT NULL
ORDER BY 
    [avg_io] DESC 
OPTION (RECOMPILE);