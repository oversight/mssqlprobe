SELECT
    DB_NAME(fs.database_id) AS [database_name],
    CONVERT(DECIMAL(18,2), mf.size/128.0) * 1024  * 1024 as [file_size_bytes],
    mf.physical_name,
    mf.physical_name as name,
    mf.type_desc,
    CONVERT(FLOAT, fs.io_stall_read_ms) / 1000.0 as [io_stall_read_sec_total],
    CONVERT(FLOAT, fs.io_stall_write_ms) / 1000.0 as [io_stall_write_sec_total],
    CONVERT(FLOAT, fs.io_stall_read_ms + fs.io_stall_write_ms) / 1000.0 as [io_stalls_sec_total],
    fs.num_of_reads AS [num_of_reads_total],
    fs.num_of_writes AS [num_of_writes_total],
    fs.num_of_reads + fs.num_of_writes AS [total_iops],
    fs.num_of_bytes_read AS [num_of_bytes_read_total],
    fs.num_of_bytes_written AS [num_of_bytes_written_total],
    fs.num_of_bytes_read + fs.num_of_bytes_written as [total_bytes_io],
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
FROM 
    sys.dm_io_virtual_file_stats(null,null) AS fs
    INNER JOIN sys.master_files AS mf WITH (NOLOCK)
    ON fs.database_id = mf.database_id
    AND fs.[file_id] = mf.[file_id]
OPTION (RECOMPILE);