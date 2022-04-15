SELECT
  total_physical_memory_kb * 1024 AS [total_physical_memory_bytes],
  available_physical_memory_kb * 1024 AS [available_physical_memory_bytes],
  100.0 * CONVERT(DECIMAL, (total_physical_memory_kb - available_physical_memory_kb)) / total_physical_memory_kb AS [physical_memory_percent_used],
  total_page_file_kb * 1024 AS [total_page_file_bytes],
  available_page_file_kb * 1024 AS [available_page_file_bytes],
  100.0 * CONVERT(DECIMAL, (total_page_file_kb - available_page_file_kb)) / total_page_file_kb AS [page_file_percent_used],
  system_cache_kb * 1024 AS [system_cache_bytes],
  system_memory_state_desc AS [system_memory_state_desc],
  'system' as [name]
FROM 
    sys.dm_os_sys_memory 
WITH (NOLOCK) 
OPTION (RECOMPILE);