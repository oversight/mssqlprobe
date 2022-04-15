SELECT 
	name as msg, 
	event_source, 
	message_id, 
	message_id as name, 
	severity, 
	[enabled], 
	has_notification,
    delay_between_responses, 
    occurrence_count, 
    last_occurrence_date,
    last_occurrence_time
FROM 
	msdb.dbo.sysalerts WITH (NOLOCK)
WHERE
    occurrence_count > 0
OPTION (RECOMPILE);