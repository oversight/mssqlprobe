SELECT TOP(25)
  DB_NAME(DB_ID()) AS [database_name],
	OBJECT_NAME(object_id) AS [table_name],
	SUM(Rows) AS [row_count], 
	data_compression_desc
FROM 
	sys.partitions 
WITH (NOLOCK)
WHERE 
	index_id < 2 --ignore the partitions from the non-clustered index if any
	AND OBJECT_NAME(object_id) NOT LIKE N'sys%'
	AND OBJECT_NAME(object_id) NOT LIKE N'queue_%'
	AND OBJECT_NAME(object_id) NOT LIKE N'filestream_tombstone%'
	AND OBJECT_NAME(object_id) NOT LIKE N'fulltext%'
	AND OBJECT_NAME(object_id) NOT LIKE N'ifts_comp_fragment%'
	AND OBJECT_NAME(object_id) NOT LIKE N'filetable_updates%'
	AND OBJECT_NAME(object_id) NOT LIKE N'xml_index_nodes%'
	AND OBJECT_NAME(object_id) NOT LIKE N'sqlagent_job%'
	AND OBJECT_NAME(object_id) NOT LIKE N'plan_persist%'
GROUP BY 
	object_id, 
	data_compression_desc
ORDER BY
  [row_count] DESC
OPTION (RECOMPILE);