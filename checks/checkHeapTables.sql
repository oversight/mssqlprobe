SELECT
	database_name,
	o.[object_id],
	[table_name],
	num_rows,
	num_reads,
	LOG10(num_rows * num_reads) AS advantage
FROM (
	SELECT
		DB_NAME(database_id) as database_name,
		s.[object_id],
		OBJECT_NAME(s.[object_id]) as [table_name],
		sum(p.[rows]) as num_rows,
		sum(ISNULL(s.user_scans, 0)) + sum(ISNULL(s.user_seeks, 0)) + sum(ISNULL(s.user_lookups, 0)) as num_reads
	FROM sys.dm_db_index_usage_stats AS s
	INNER JOIN sys.partitions AS p WITH (NOLOCK) ON s.object_id = p.[object_id]
	INNER JOIN sys.indexes AS i WITH (NOLOCK) ON s.index_id = i.index_id AND s.object_id = i.[object_id]
	WHERE i.type = 0 --'HEAP'
	GROUP BY database_id, s.object_id
) AS idx_data
	LEFT JOIN sys.objects AS o WITH (NOLOCK) ON o.object_id = idx_data.[object_id]
WHERE o.type = 'U' -- USER_TABLE
	AND idx_data.num_rows > 0
	AND idx_data.num_reads > 0
ORDER BY advantage DESC
