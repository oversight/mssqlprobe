IF CONVERT(INT, LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(MAX)), 2)) < 11
  EXECUTE sp_executesql N'
	  SELECT
      type,
      CASE WHEN type = ''USERSTORE_TOKENPERM'' THEN ''ACRUserStore'' ELSE name END [memory_name],
      sum(virtual_memory_reserved_kb) * 1024 AS [virtual_memory_reserved],
      sum(virtual_memory_committed_kb) * 1024 AS [virtual_memory_committed],
      sum(awe_allocated_kb) * 1024 AS [awe_allocated],
      sum(shared_memory_reserved_kb) * 1024 AS [shared_memory_reserved],
      sum(shared_memory_committed_kb) * 1024 AS [shared_memory_committed],
	    sum(multi_pages_kb + single_pages_kb) * 1024 AS [page_memory_size]
	FROM sys.dm_os_memory_clerks
	GROUP BY
		type,
		CASE WHEN type = ''USERSTORE_TOKENPERM'' THEN ''ACRUserStore'' ELSE name END'
ELSE
	EXECUTE sp_executesql N'
	SELECT
	  type,
	  CASE WHEN type = ''USERSTORE_TOKENPERM'' THEN ''ACRUserStore'' ELSE name END [memory_name],
	  sum(virtual_memory_reserved_kb) * 1024 AS [virtual_memory_reserved],
	  sum(virtual_memory_committed_kb) * 1024 AS [virtual_memory_committed],
	  sum(awe_allocated_kb) * 1024 AS [awe_allocated],
	  sum(shared_memory_reserved_kb) * 1024 AS [shared_memory_reserved],
	  sum(shared_memory_committed_kb) * 1024 AS [shared_memory_committed],
	  sum(pages_kb) * 1024  AS [page_memory_size]
	FROM sys.dm_os_memory_clerks
	GROUP BY
		type,
		CASE WHEN type = ''USERSTORE_TOKENPERM'' THEN ''ACRUserStore'' ELSE name END'