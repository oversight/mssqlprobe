SELECT 
	ec.client_net_address, 
	es.[program_name], 
	es.[host_name], 
	es.login_name,
	COUNT(ec.session_id) AS [connection_count]
FROM 
	sys.dm_exec_sessions AS es WITH (NOLOCK)
	INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK)
	ON es.session_id = ec.session_id
GROUP 
	BY ec.client_net_address, 
	es.[program_name], 
	es.[host_name], 
	es.login_name
OPTION (RECOMPILE);