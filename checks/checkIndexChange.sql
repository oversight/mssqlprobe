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
    CAST(100 * [sp].[modification_counter] / [sp].[rows] AS DECIMAL(18, 2)) AS [percent_change]
FROM
    [sys].[stats] [ss]
    JOIN [sys].[objects] [so] ON [ss].[object_id] = [so].[object_id]
    OUTER APPLY [sys].[dm_db_stats_properties]([so].[object_id], [ss].[stats_id]) sp
WHERE
    [so].[type] = 'U'
    AND CAST(100 * [sp].[modification_counter] / [sp].[rows] AS DECIMAL(18, 2)) >= 10.00
    AND [sp].[modification_counter] > 1000
    AND [sp].[rows] > 10000
ORDER BY
    CAST(100 * [sp].[modification_counter] / [sp].[rows] AS DECIMAL(18, 2)) DESC;


