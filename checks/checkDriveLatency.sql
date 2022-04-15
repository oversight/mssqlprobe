SELECT
  tab.[Drive] as [name],
  tab.[Drive],
  tab.volume_mount_point AS [volume_mount_point],
  CONVERT(FLOAT, io_stall_read_ms) / 1000.0 AS [io_stall_read_sec_total],
  CONVERT(FLOAT, io_stall_write_ms) / 1000.0 AS [io_stall_write_sec_total],
  CONVERT(FLOAT, io_stall / 1000.0) as [io_stalls_sec_total],
  num_of_reads AS [num_of_reads_total],
  num_of_writes AS [num_of_writes_total],
  num_of_reads + num_of_writes AS [total_iops],
  num_of_bytes_read AS [num_of_bytes_read_total],
  num_of_bytes_written AS [num_of_bytes_written_total],
  num_of_bytes_read + num_of_bytes_written AS [total_bytes_io],
	CASE
		WHEN num_of_reads = 0 THEN 0
		ELSE (io_stall_read_ms / 1000.0 /num_of_reads)
	END AS [avg_read_latency_sec],
	CASE
		WHEN num_of_writes = 0 THEN 0
		ELSE (io_stall_write_ms / 1000.0 / num_of_writes)
	END AS [avg_write_latency_sec],
	CASE
		WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0
		ELSE (io_stall / 1000.0  / (num_of_reads + num_of_writes))
	END AS [avg_io_latency_sec],
	CASE
		WHEN num_of_reads = 0 THEN 0
		ELSE (num_of_bytes_read / num_of_reads)
	END AS [avg_bytes_per_read],
	CASE
		WHEN num_of_writes = 0 THEN 0
		ELSE (num_of_bytes_written / num_of_writes)
	END AS [avg_bytes_per_write],
	CASE
		WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0
		ELSE ((num_of_bytes_read + num_of_bytes_written) / (num_of_reads + num_of_writes))
	END AS [avg_bytes_per_iop]
FROM (
    SELECT
        LEFT(UPPER(mf.physical_name), 2) AS Drive, 
        SUM(num_of_reads) AS num_of_reads,
        SUM(io_stall_read_ms) AS io_stall_read_ms, 
        SUM(num_of_writes) AS num_of_writes,
        SUM(io_stall_write_ms) AS io_stall_write_ms, 
        SUM(num_of_bytes_read) AS num_of_bytes_read,
        SUM(num_of_bytes_written) AS num_of_bytes_written, 
        SUM(io_stall) AS io_stall, vs.volume_mount_point
    FROM 
        sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
        INNER JOIN sys.master_files AS mf WITH (NOLOCK)
        ON vfs.database_id = mf.database_id AND vfs.file_id = mf.file_id
	    CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.[file_id]
    ) AS vs
GROUP BY 
    LEFT(UPPER(mf.physical_name), 2), 
    vs.volume_mount_point) AS tab
OPTION (RECOMPILE);