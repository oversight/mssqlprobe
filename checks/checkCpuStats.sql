WITH DB_CPU_Stats
AS
(
	SELECT pa.DatabaseID,
	DB_Name(pa.DatabaseID) AS [name],
	CONVERT(FLOAT, SUM(qs.total_worker_time/1000000.0)) AS [cpu_time_sec]
 FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
 CROSS APPLY (
 	SELECT CONVERT(int, value) AS [DatabaseID]
    FROM sys.dm_exec_plan_attributes(qs.plan_handle)
    WHERE attribute = N'dbid') AS pa
    GROUP BY DatabaseID
)
SELECT
	ROW_NUMBER() OVER(ORDER BY [cpu_time_sec] DESC) AS [CPU Rank],
    [name], cpu_time_sec,
    CAST(ISNULL([cpu_time_sec] * 1.0 / NULLIF(SUM([cpu_time_sec]) OVER(), 0), 0) * 100.0 AS DECIMAL(5, 2)) AS [cpu_percent_used]
FROM
	DB_CPU_Stats
WHERE
	DatabaseID <> 32767 -- ResourceDB
OPTION (RECOMPILE);
