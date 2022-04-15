-- http://dba.stackexchange.com/questions/4283/when-should-i-rebuild-indexes
-- Simple defrag: https://blog.sqlauthority.com/2009/01/30/sql-server-2008-2005-rebuild-every-index-of-all-tables-of-database-rebuild-index-with-fillfactor/
-- Extended defrag:  http://sqlfool.com/2011/06/index-defrag-script-v4-1/
-- MSDN: https://blogs.msdn.microsoft.com/axinthefield/database-maintenance-strategies-for-dynamics-ax/

SELECT TOP(25)
  DB_NAME(ps.database_id) AS [database_name],
  SCHEMA_NAME(o.[schema_id]) AS [schema_name],
  OBJECT_NAME(ps.OBJECT_ID) AS [object_name],
  i.name AS [index_name],
  ps.index_id,
  ps.index_type_desc,
  ps.avg_fragmentation_in_percent,
  ps.fragment_count,
  ps.page_count,
  i.fill_factor,
  i.has_filter,
  i.filter_definition,
  i.allow_page_locks
FROM
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL , N'LIMITED') AS ps
    INNER JOIN sys.indexes AS i WITH (NOLOCK) ON ps.[object_id] = i.[object_id] AND ps.index_id = i.index_id
    INNER JOIN sys.objects AS o WITH (NOLOCK) ON i.[object_id] = o.[object_id] AND ps.page_count > 2500
ORDER BY
  ps.avg_fragmentation_in_percent DESC
OPTION (RECOMPILE);