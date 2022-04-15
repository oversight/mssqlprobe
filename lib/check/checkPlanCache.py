from .base import MsSqlCheckBase

qry = '''
DECLARE @TOTAL_PLAN_CACHE BIGINT, @SINGLE_USE_PLAN_CACHE BIGINT;
SELECT @TOTAL_PLAN_CACHE = SUM(CAST(cp_tot.size_in_bytes AS BIGINT))
FROM sys.dm_exec_cached_plans AS cp_tot
WHERE cp_tot.cacheobjtype = N'Compiled Plan';

SELECT @SINGLE_USE_PLAN_CACHE = SUM(CAST(cp_single.size_in_bytes AS BIGINT))
FROM sys.dm_exec_cached_plans AS cp_single
WHERE
    cp_single.cacheobjtype = N'Compiled Plan'
    AND cp_single.objtype IN (N'Adhoc', N'Prepared')
    AND cp_single.usecounts = 1;

SELECT
    'system' AS [name],
    @TOTAL_PLAN_CACHE AS total_plan_cache,
    @SINGLE_USE_PLAN_CACHE AS single_use_plan_cache,
    100.0 * CAST(@SINGLE_USE_PLAN_CACHE AS float) /
        CAST(@TOTAL_PLAN_CACHE AS float) AS plan_bloat
'''


class CheckPlanCache(MsSqlCheckBase):

    type_name = 'plancache'
    db = 'master'

    @classmethod
    def _get_data(cls, cr, host, port, username, password):
        with cls._get_conn(host, port, username, password) as conn:
            with conn.cursor() as cur:
                cur.execute(qry)
                try:
                    _ = cur.return_value
                except Exception:
                    pass
                res = [cur._session.row]
                collnames = [tup[0] for tup in cur.description]

                cr[cls.type_name] = cls.format_response(res, collnames)
