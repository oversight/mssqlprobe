SELECT 
    node_id, 
    node_id as name, 
    node_state_desc, 
    memory_node_id, 
    processor_group, 
    online_scheduler_count,
    active_worker_count, 
    avg_load_balance, 
    resource_monitor_state
FROM 
    sys.dm_os_nodes 
WITH (NOLOCK)
WHERE 
    node_state_desc <> N'ONLINE DAC' 
OPTION (RECOMPILE);