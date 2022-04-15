from collections import Counter

import re

from .base import MsSqlCheckBase

UUID_RE = re.compile('([0-9a-f]{4,}-)+[0-9a-f]{4,}', re.IGNORECASE)


"""
-- perhaps useful in the future:
-- the problem is, that sessions are ephemeral and disappearing sessions
-- distort the results

SELECT
    program_name,
    COUNT(host_name) as hosts,
    COUNT(login_name) as accounts,
    SUM(cpu_time) / 1000000.0 as cpu_time,
    SUM(memory_usage) * 8 * 1024 as memory_usage,
    SUM(total_scheduled_time) / 1000000.0 as total_scheduled_time,
    SUM(total_elapsed_time) / 1000000.0 as total_elapsed_time,
    SUM(reads) as reads,
    SUM(writes) as writes,
    SUM(logical_reads) as logical_reads,
    SUM(row_count) as row_count
FROM
    sys.dm_exec_sessions
WHERE
    is_user_process = 0x1
GROUP by
    program_name

"""


class CheckApplicationSessions(MsSqlCheckBase):

    type_name = 'applications'
    ignore_duplicates = True
    # diffMetrics = ['cpu_time', 'disk_io']
    # ignoreNegativeValuesInDiff = True

    @classmethod
    def _get_data(cls, cr, host, port, username, password):
        with cls._get_conn(host, port, username, password) as conn:
            with conn.cursor() as cur:
                cur.execute('''
                IF OBJECT_ID(\'tempdb..#tmpwho2\') IS NOT NULL
                    DROP TABLE #tmpwho2;
                CREATE TABLE #tmpwho2 (
                    SPID INT,
                    Status VARCHAR(MAX),
                    login VARCHAR(MAX),
                    HostName VARCHAR(MAX),
                    BlkBy VARCHAR(MAX),
                    database_name VARCHAR(MAX),
                    command VARCHAR(MAX),
                    cpu_time INT,
                    disk_io INT,
                    last_batch VARCHAR(MAX),
                    ProgramName VARCHAR(MAX),
                    spid_1 INT,
                    request_id INT
                )
                INSERT INTO #tmpwho2 EXEC sp_who2;
                ''')
                cur.execute('''
                SELECT
                    SPID AS [name],
                    RTRIM(Status) AS [status],
                    login,
                    RTRIM(HostName) AS [host_name],
                    LTRIM(RTRIM(BlkBy)) AS [blk_by],
                    database_name AS [database_name],
                    command as [command],
                    CONVERT(FLOAT, cpu_time / 1000000.0) AS [cpu_time],
                    disk_io,
                    last_batch,
                    LTRIM(RTRIM(ProgramName)) AS program_name,
                    spid_1,
                    request_id
                FROM
                    #tmpwho2
                WHERE
                    ProgramName is not NULL
                    AND len(rtrim(ltrim(ProgramName))) > 0
                ''')
                res = cur.fetchall()
                collnames = [tup[0] for tup in cur.description]

                type_data_pre_count = cls.format_response(res, collnames)
                cur.execute('DROP TABLE #tmpwho2;')

                counts = {}
                block_sources = {}
                victim_count = 0
                for item_name in type_data_pre_count:
                    item = type_data_pre_count[item_name]
                    if len(item['blk_by']) > 1:
                        victim_count += 1
                        block_source = \
                            item['database_name'] + '-' + item['blk_by']
                        if block_source not in block_sources:
                            block_sources[block_source] = {
                                'name': block_source,
                                'victims': 0,
                                'database_name': item['database_name'],
                                'command': item['command'],
                                'login': item['login'],
                                'program_name': item['program_name'],
                                'status': item['status'],
                                'spid_1': item['spid_1']
                            }
                        block_item = block_sources[block_source]
                        block_item['victims'] += 1

                    program_name = item['program_name']
                    program_name = UUID_RE.sub('', program_name) \
                        if program_name else program_name
                    if program_name in counts:
                        cur_counts = counts[program_name]
                    else:
                        counts[program_name] = cur_counts = {
                            'cpu_time': 0.0,
                            'disk_io': 0,
                            'logins': Counter(),
                            'host_names': Counter()
                        }

                    cur_counts['cpu_time'] += item['cpu_time'] \
                        if item['cpu_time'] > 0 else 0
                    cur_counts['disk_io'] += item['disk_io']
                    cur_counts['logins'][item['login']] += 1
                    cur_counts['host_names'][item['host_name']] += 1

                for item_name in counts:
                    item = counts[item_name]
                    item['name'] = item_name
                    item['sessions'] = sum(v for v in item['logins'].values())
                    item['hosts'] = len(list(set(item.pop('host_names'))))
                    item['accounts'] = len(list(set(item.pop('logins'))))

                cr['applications'] = counts
                cr['blocks'] = block_sources
                cr['blockcount'] = {'victims': {'victims': victim_count}}
