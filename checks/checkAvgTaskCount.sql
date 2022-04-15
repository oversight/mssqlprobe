SELECT
  'system' as [name],
	AVG(current_tasks_count) as avg_current_tasks_count,
	AVG(work_queue_count) as avg_work_queue_count,
	AVG(runnable_tasks_count) as avg_runnable_tasks_count,
	AVG(pending_disk_io_count) as avg_pending_disk_io_count
FROM 
	sys.dm_os_schedulers 
WITH (NOLOCK)
WHERE 
	scheduler_id < 255 
OPTION (RECOMPILE);