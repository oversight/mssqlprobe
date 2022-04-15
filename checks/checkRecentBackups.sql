SELECT TOP (30) 
	bs.machine_name, 
	bs.server_name, 
	bs.database_name, 
	bs.recovery_model,
	bs.backup_size,
	bs.compressed_backup_size,
	CONVERT (NUMERIC (20,2), (CONVERT (FLOAT, bs.backup_size) /
	CONVERT (FLOAT, bs.compressed_backup_size))) AS [compression_ratio], 
	bs.has_backup_checksums, 
	bs.is_copy_only, 
	--bs.encryptor_type,
	DATEDIFF (SECOND, bs.backup_start_date, bs.backup_finish_date) AS [backup_elapsed_time_sec],
	bs.backup_finish_date
FROM 
	msdb.dbo.backupset AS bs WITH (NOLOCK)
WHERE 
	bs.[type] = 'D' -- Change to L if you want Log backups
ORDER BY 
	bs.backup_finish_date DESC OPTION (RECOMPILE);
