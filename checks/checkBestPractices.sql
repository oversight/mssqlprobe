/*

0	Emergency	emerg	panic[7]	System is unusable.
  A panic condition.[8]
1	Alert	alert		Action must be taken immediately.
  A condition that should be corrected immediately, such as a corrupted system database.[8]
2	Critical	crit
  Critical conditions, such as hard device errors.[8]
3	Error	err	error[7]
  Error conditions.
4	Warning	warning	warn[7]
  Warning conditions.
5	Notice	notice
  Normal but significant conditions.
  Conditions that are not error conditions, but that may require special handling.[8]
6	Informational	info
  Informational messages.
7	Debug


 */

DECLARE @CPU_COUNT INT
DECLARE @TEMPDB_COUNT INT
DECLARE @MAINT_PLAN_COUNT INT

SET @CPU_COUNT = (SELECT cpu_count FROM sys.dm_os_sys_info)
SET @TEMPDB_COUNT = (SELECT COUNT(*)
    FROM sys.master_files WITH (NOLOCK)
    WHERE DB_NAME([database_id]) = 'tempdb')



SET @MAINT_PLAN_COUNT = (select count(*)
    from msdb..sysmaintplan_plans p
        inner join msdb..sysmaintplan_subplans sp
        on p.id = sp.plan_id
        inner join msdb..sysjobs j
        on sp.job_id = j.job_id
    where j.[enabled] = 1)


SELECT 'one per core, up to max 8, found ' + CAST(@CPU_COUNT AS VARCHAR) + ' cores' AS [suggested], CAST(@TEMPDB_COUNT AS VARCHAR) + ' tempdb files' as [found], CASE WHEN (@CPU_COUNT = @TEMPDB_COUNT OR (@TEMPDB_COUNT = 8 AND @CPU_COUNT = 8)) THEN 4 ELSE 0 END as [severity]
  UNION ALL
SELECT 'minimal 1' AS [suggested], CAST(@MAINT_PLAN_COUNT AS VARCHAR) + ' active maintenance plans' as [found], CASE WHEN (@MAINT_PLAN_COUNT = 0) THEN 3 ELSE 0 END as [severity]