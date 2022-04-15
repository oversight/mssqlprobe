SELECT 
	rtrim(@@SERVERNAME) AS [server_name], 
	rtrim([object_name]) AS [object_name], 
	cntr_value AS [memory_grants_pending]
FROM 
	sys.dm_os_performance_counters WITH (NOLOCK)
WHERE 
	[object_name] LIKE N'%Memory Manager%' -- Handles named instances
	AND counter_name = N'Memory Grants Pending' 
OPTION (RECOMPILE);