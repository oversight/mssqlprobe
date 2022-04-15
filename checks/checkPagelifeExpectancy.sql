SELECT 
	RTRIM(@@SERVERNAME) AS [server_name],
	RTRIM([object_name]) as object_name, 
	RTRIM(instance_name) as instance_name, 
	cntr_value AS [page_life_expectancy]
FROM 
    sys.dm_os_performance_counters 
WITH (NOLOCK)
WHERE 
    [object_name] LIKE N'%Buffer Node%' -- Handles named instances
    AND counter_name = N'Page life expectancy' 
OPTION (RECOMPILE);