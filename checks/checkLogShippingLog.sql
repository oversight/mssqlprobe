select TOP 100 *
From
	msdb.dbo.log_shipping_monitor_history_detail
WHERE 1 = 1
	AND session_status IN (3, 4)
	AND log_time > DateAdd(MONTH, -1, GETDATE())
ORDER BY log_time_utc DESC