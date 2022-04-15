SELECT
    'system' as [name],
    physical_memory_in_use_kb * 1024 AS [physical_memory_in_use_bytes],
    large_page_allocations_kb * 1024 AS [large_page_allocations_bytes],
    locked_page_allocations_kb * 1024 AS [locked_page_allocations_bytes],
    page_fault_count,
	memory_utilization_percentage,
    available_commit_limit_kb * 1024 AS [available_commit_limit_bytes],
	process_physical_memory_low,
    process_virtual_memory_low
FROM 
    sys.dm_os_process_memory 
WITH (NOLOCK) 
OPTION (RECOMPILE);