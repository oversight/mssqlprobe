SELECT TOP(25)
    CONVERT(decimal(18,2), user_seeks * avg_total_user_cost * (avg_user_impact * 0.01)) AS [index_advantage],
    migs.last_user_seek, 
    mid.[statement] AS [Database.Schema.Table],
    mid.equality_columns, 
    mid.inequality_columns, 
    mid.included_columns,
    migs.unique_compiles, 
    migs.user_seeks, 
    migs.avg_total_user_cost, 
    migs.avg_user_impact,
    LOG10(user_seeks * avg_total_user_cost * avg_user_impact) as index_usefulness
FROM
    sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
    INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK) ON migs.group_handle = mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK) ON mig.index_handle = mid.index_handle
WHERE
    user_seeks > 0 AND
    avg_total_user_cost > 0 AND
    avg_user_impact > 0
ORDER BY index_usefulness DESC
OPTION (RECOMPILE);
