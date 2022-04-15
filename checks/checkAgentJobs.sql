WITH CTE_MostRecentJobRun AS
 (
	 -- For each job get the most recent run (this will be the one where rnk=1)
	 SELECT
		job_id,
		run_status,
		run_date,
		run_time,
		RANK() OVER (PARTITION BY job_id ORDER BY run_date DESC,run_time DESC) AS rnk
	 FROM
		msdb.dbo.sysjobhistory WITH (NOLOCK)
	 WHERE 1 = 1
		AND step_id=0 -- step0 is jobstatus
		AND run_date > CONVERT(VARCHAR(8), DateAdd(Year, -1, GETDATE()), 112) -- only over last year to prevent long runtimes
 )
SELECT
	isnull(js.job_id, sj.job_id) as [name],
	sj.name AS [jobname],
	sj.[description] AS [job_description],
	SUSER_SNAME(sj.owner_sid) AS [job_owner],
	sj.date_created,
	sj.[enabled],
	sj.notify_email_operator_id,
	sj.notify_level_email,
	sc.name AS [category_name],
	js.next_run_date,
	js.next_run_time,
	CONVERT(DATETIME, CONVERT(VARCHAR,DATEADD(S,(mrjr.run_time/10000)*60*60 /* hours */
		+((mrjr.run_time - (mrjr.run_time/10000) * 10000)/100) * 60 /* mins */
		+ (mrjr.run_time - (mrjr.run_time/100) * 100)  /* secs */,
	  CONVERT(DATETIME,RTRIM(mrjr.run_date),113)),100)) AS last_run_ts,
	CASE
	    WHEN js.next_run_date >= CONVERT(VARCHAR(8), DateAdd(Year, -1, GETDATE()), 112) THEN (
			CONVERT(DATETIME, CONVERT(VARCHAR,DATEADD(S,(js.next_run_time/10000)*60*60 /* hours */
				+((js.next_run_time - (js.next_run_time/10000) * 10000)/100) * 60 /* mins */
				+ (js.next_run_time - (js.next_run_time/100) * 100)  /* secs */,
			  CONVERT(DATETIME,RTRIM(js.next_run_date),113)),100))
		)
		ELSE NULL
	END AS next_run_ts,
	CASE
		WHEN run_status = 0 THEN 'Failed'
		WHEN run_status = 1 THEN 'Succeeded'
		WHEN run_status = 2 THEN 'Retry'
		WHEN run_status = 3 THEN 'Canceled'
		WHEN run_status = 4 THEN 'In Progress'
        ELSE NULL
    END AS run_status_txt
FROM
	msdb.dbo.sysjobs AS sj WITH (NOLOCK)
	LEFT JOIN CTE_MostRecentJobRun mrjr ON MRJR.job_id = sj.job_id AND mrjr.rnk = 1
	INNER JOIN msdb.dbo.syscategories AS sc WITH (NOLOCK) ON sj.category_id = sc.category_id
	LEFT OUTER JOIN msdb.dbo.sysjobschedules AS js WITH (NOLOCK) ON sj.job_id = js.job_id
OPTION (RECOMPILE);