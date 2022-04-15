SELECT TOP 25
    DB_NAME(DB_ID()) AS [database_name],
    [so].[name] AS [table_name],
    [ss].[name] AS [statistic],
    [ss].[auto_created],
    [ss].[user_created],
    [ss].[has_filter],
    [ss].[filter_definition],
    [ss].[is_temporary],
    [sp].[last_updated],
    [sp].[rows] AS [row_cnt],
    [sp].[rows_sampled],
    [sp].[unfiltered_rows],
    [sp].[modification_counter],
    [sp].[steps] AS [histogram_steps],
    DATEDIFF(second, ISNULL([sp].[last_updated], cast('2010-1-1' as datetime)), CURRENT_TIMESTAMP) AS [age]
FROM
    [sys].[stats] [ss]
    JOIN [sys].[objects] [so] ON [ss].[object_id] = [so].[object_id]
    OUTER APPLY [sys].[dm_db_stats_properties]([so].[object_id],[ss].[stats_id]) sp
WHERE
    [so].[type] = 'U'
    AND [sp].[rows] > 1000
    AND [sp].[modification_counter] > 1000
ORDER BY
    [sp].[last_updated] DESC;