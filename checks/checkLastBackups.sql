SELECT
	bs.machine_name,
	bs.server_name,
	bs.database_name,
	DATEDIFF(second, MAX(bs.backup_finish_date), CURRENT_TIMESTAMP) AS [last_backup_age],
	DATEDIFF(second, '1970-01-01 00:00:00', MAX(bs.backup_finish_date)) AS [last_backup_date]
FROM
	msdb.dbo.backupset AS bs WITH (NOLOCK)
WHERE
	bs.[type] = 'D'
GROUP BY
	bs.machine_name,
	bs.server_name,
	bs.database_name