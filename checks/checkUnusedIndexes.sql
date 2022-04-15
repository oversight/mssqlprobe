SELECT TOP 25
	  o.name as [object_name],
	  i.name as [index_name],
	  dm_ius.user_seeks,
	  dm_ius.user_scans,
	  dm_ius.user_lookups,
	  dm_ius.user_updates,
	  DB_NAME(dm_ius.database_id) AS [database_name],
	  LOG10(CONVERT(float, (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups + 1)) / CONVERT(float, dm_ius.user_updates + 1)) AS [index_usefulness]
FROM
	sys.indexes i WITH (NOLOCK)
	INNER JOIN sys.dm_db_index_usage_stats dm_ius WITH (NOLOCK)
        ON i.index_id = dm_ius.index_id
        AND dm_ius.OBJECT_ID = i.OBJECT_ID
	INNER JOIN sys.objects o WITH (NOLOCK) ON dm_ius.OBJECT_ID = o.OBJECT_ID
WHERE
	OBJECTPROPERTY(dm_ius.OBJECT_ID,'IsUserTable') = 1
	AND dm_ius.user_updates > 0
	AND i.type_desc = 'nonclustered'
	AND i.is_primary_key = 0
	AND i.is_unique_constraint = 0
	AND dm_ius.database_id = DB_ID()
ORDER BY index_usefulness ASC