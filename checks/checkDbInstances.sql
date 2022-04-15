/*SELECT
  database_id,
  DB_NAME([database_id]) as [database_name],
  [file_id],
  name as db_name,
  physical_name as name,
  type_desc,
  state_desc,
  is_percent_growth,
  CONVERT(bigint, growth) * 8 * 1024 AS [growth_bytes],
  CONVERT(bigint, size) * 8 * 1024 AS [size_bytes]
FROM
    sys.master_files WITH (NOLOCK)
OPTION (RECOMPILE);*/
DECLARE @total_buffer INT

SELECT @total_buffer = cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Database Pages'
AND RTRIM([object_name]) LIKE '%Buffer Manager'
;WITH src AS
(
  SELECT
      database_id,
      db_buffer_pages = COUNT_BIG(*)
  FROM
      sys.dm_os_buffer_descriptors
  GROUP BY database_id
)
SELECT
    src.database_id,
    CASE src.[database_id] WHEN 32767 THEN 'Resource DB' ELSE DB_NAME(src.[database_id]) END AS database_name,
    db_buffer_pages,
    db_buffer_bytes = db_buffer_pages * 8 * 1024,
    db_buffer_percent = CONVERT(DECIMAL(6,3), db_buffer_pages * 100.0 / @total_buffer),
    mf.[file_id],
    mf.name as db_name,
    ISNULL(mf.physical_name, 'Resource DB') as name,
    mf.type_desc,
    mf.state_desc,
    mf.is_percent_growth,
    CONVERT(bigint, mf.growth) * 8 * 1024 AS [growth_bytes],
    CONVERT(bigint, mf.size) * 8 * 1024 AS [size_bytes]
FROM
    src LEFT OUTER JOIN sys.master_files AS mf WITH (NOLOCK) ON src.database_id = mf.database_id
