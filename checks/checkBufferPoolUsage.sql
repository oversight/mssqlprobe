WITH AggregateBufferPoolUsage
AS
(
	SELECT 
		DB_NAME(database_id) AS [name],
		CAST(COUNT(*) * 8 AS DECIMAL (10,2)) * 1024.0 AS [cached_size]
	FROM 
		sys.dm_os_buffer_descriptors 
	WITH (NOLOCK)
	WHERE 
		database_id <> 32767 -- ResourceDB
	GROUP BY DB_NAME(database_id)
)
SELECT 
	ROW_NUMBER() OVER(ORDER BY cached_size DESC) AS [buffer_pool_rank], 
	[name], 
	cached_size,
    CAST(cached_size / SUM(cached_size) OVER() * 100.0 AS DECIMAL(5,2)) AS [buffer_pool_percent]
FROM 
	AggregateBufferPoolUsage
OPTION (RECOMPILE);