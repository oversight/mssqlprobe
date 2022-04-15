SELECT TOP (25)
  OBJECT_NAME(p.[object_id]) AS [object_name],
  ind.name as index_name,
  CAST(COUNT(*) AS bigint) * CAST(8 * 1024 as bigint) AS buffer_size,
  COUNT(*) AS [buffer_count],
  p.Rows AS [row_count],
  p.data_compression_desc AS [compression_type]
FROM sys.allocation_units AS a WITH (NOLOCK)
INNER JOIN sys.dm_os_buffer_descriptors AS b WITH (NOLOCK)
  ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p WITH (NOLOCK)
  ON a.container_id = p.hobt_id
LEFT OUTER JOIN sys.indexes ind
  ON p.object_id = ind.object_id
  AND p.index_id = ind.index_id
WHERE b.database_id = CONVERT(int, DB_ID())
AND p.[object_id] > 100
GROUP BY p.[object_id],
         ind.name,
         p.data_compression_desc,
         p.[Rows]
ORDER BY [buffer_count] DESC
OPTION (RECOMPILE);