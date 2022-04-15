SELECT TOP(25)
    QUOTENAME(DB_NAME(s.database_id)) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(i.[object_id], s.database_id)) + '.' + QUOTENAME(OBJECT_NAME(i.[object_id], s.database_id)) + '.' + QUOTENAME(i.name) as name,
    OBJECT_NAME(i.[object_id]) AS [object_name], 
    i.name AS [index_name], 
    i.index_id,
    s.user_updates AS [writes], 
    s.user_seeks + s.user_scans + s.user_lookups AS [total_reads],
    i.type_desc AS [index_type], 
    i.fill_factor AS [fill_factor], 
    i.has_filter, 
    i.filter_definition,
    s.last_system_update, 
    s.last_user_update,
    s.user_seeks + s.user_scans + s.user_lookups + s.user_updates as [total_usage]
FROM 
    sys.indexes AS i WITH (NOLOCK)
    LEFT OUTER JOIN sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
    ON i.[object_id] = s.[object_id]
    AND i.index_id = s.index_id
WHERE 
    OBJECTPROPERTY(i.[object_id],'IsUserTable') = 1 and
    QUOTENAME(DB_NAME(s.database_id)) + '.' +
      QUOTENAME(OBJECT_SCHEMA_NAME(i.[object_id], s.database_id)) + '.' +
      QUOTENAME(OBJECT_NAME(i.[object_id], s.database_id)) + '.' +
      QUOTENAME(i.name) is not Null
    AND s.database_id = DB_ID()
ORDER BY [total_usage] DESC OPTION (RECOMPILE); -- Order by reads

