from .base import MsSqlCheckBase


# http://michaeljswart.com/tag/probe-scans/
# http://www.databasejournal.com/features/mssql/article.php/3932406/Top-10-SQL-Server-Counters-for-Monitoring-SQL-Server-Performance.htm

class CheckInstancePerfCounters(MsSqlCheckBase):

    # ratioMetrics = {
    #     'buffer_cache_hit': 'buffer_cache_hit_ratio_base',
    #     'average_wait_time': 'average_wait_time_base',
    #     'update_conflict': 'update_conflict_ratio_base'
    # }

    # diffpsMetrics = [
    #     'batch_compilations',
    #     'batch_requests',
    #     'checkpoint_pages',
    #     'connection_reset',
    #     'full_scans',
    #     'index_searches',
    #     'lock_requests',
    #     'lock_timeouts',
    #     'lock_wait_time',
    #     'lock_waits',
    #     'logins',
    #     'logouts',
    #     'number_of_deadlocks',
    #     'page_deallocations',
    #     'page_splits',
    #     'pages_allocated',
    #     'page_reads',
    #     'page_writes',
    #     'probe_scans',
    #     'query_optimizations',
    #     'range_scans',
    #     'readahead_pages',
    #     'sql_compilations',
    #     'sql_re_compilations',
    #     'stored_procedures_invoked',
    #     'suboptimal_plans',
    #     'table_lock_escalations',
    #     'temp_tables_creation_rate',
    # ]

    type_name = 'instanceperf'

    qry = '''
    SELECT [counter_name], [cntr_value] FROM sys.dm_os_performance_counters
    WHERE
        (counter_name = 'Batch Requests/sec' AND object_name
            LIKE '%SQL Statistics%') OR
        (counter_name = 'SQL Compilations/sec' AND object_name
            LIKE '%SQL Statistics%') OR
        (counter_name = 'SQL Re-Compilations/sec' AND object_name
            LIKE '%SQL Statistics%') OR
        (counter_name = 'Lock Waits/sec' AND instance_name = '_Total'
            AND object_name LIKE '%Locks%') OR
        (counter_name = 'Page Splits/sec' AND object_name
            LIKE '%Access Methods%') OR
        (counter_name = 'Processes blocked' AND object_name
            LIKE '%General Statistics%') OR
        (counter_name = 'Query optimizations/sec' AND object_name
            LIKE '%SQLServer:Workload Group Stats%') OR
        (counter_name = 'Suboptimal plans/sec' AND object_name
            LIKE '%SQLServer:Workload Group Stats%')  OR
        (counter_name = 'Stored Procedures Invoked/sec'
            AND instance_name = '_Total' AND object_name
            LIKE '%SQLServer:Broker Activation%') OR
        (counter_name = 'Full Scans/sec' AND object_name
            LIKE '%SQLServer:Access Methods%') OR
        (counter_name = 'Range Scans/sec' AND object_name
            LIKE '%SQLServer:Access Methods%') OR
        (counter_name = 'Probe Scans/sec' AND object_name
            LIKE '%SQLServer:Access Methods%') OR
        (counter_name = 'Index Searches/sec' AND object_name
            LIKE '%SQLServer:Access Methods%') OR
        (counter_name = 'Pages Allocated/sec' AND object_name
            LIKE '%SQLServer:Access Methods%') OR
        (counter_name = 'Page Deallocations/sec' AND object_name
            LIKE '%SQLServer:Access Methods%') OR
        (counter_name = 'Table Lock Escalations/sec' AND object_name
            LIKE '%SQLServer:Access Methods%') OR
        (counter_name = 'Lock Requests/sec' AND instance_name = '_Total'
            AND object_name LIKE '%SQLServer:Locks%') OR
        (counter_name = 'Lock Timeouts/sec' AND instance_name = '_Total'
            AND object_name LIKE '%SQLServer:Locks%') OR
        (counter_name = 'Number of Deadlocks/sec' AND instance_name = '_Total'
            AND object_name LIKE '%SQLServer:Locks%') OR
        (counter_name = 'Lock Waits/sec' AND instance_name = '_Total'
            AND object_name LIKE '%SQLServer:Locks%') OR
        (counter_name = 'Lock Wait Time (ms)' AND instance_name = '_Total'
            AND object_name LIKE '%SQLServer:Locks%') OR
        (counter_name = 'Average Wait Time (ms)' AND instance_name = '_Total'
            AND object_name LIKE '%SQLServer:Locks%') OR
        (counter_name = 'Average Wait Time Base' AND instance_name = '_Total'
            AND object_name LIKE '%SQLServer:Locks%') OR
        (counter_name = 'Lock Timeouts (timeout > 0)/sec'
            AND instance_name = '_Total' AND object_name
            LIKE '%SQLServer:Locks%') OR
        (counter_name = 'Active Temp Tables' AND object_name
            LIKE '%SQLServer:General Statistics%') OR
        (counter_name = 'Temp Tables Creation Rate' AND object_name
            LIKE '%SQLServer:General Statistics%') OR
        (counter_name = 'Logins/sec' AND object_name
            LIKE '%SQLServer:General Statistics%') OR
        (counter_name = 'Connection Reset/sec' AND object_name
            LIKE '%SQLServer:General Statistics%') OR
        (counter_name = 'Logouts/sec' AND object_name
            LIKE '%SQLServer:General Statistics%') OR
        (counter_name = 'Update conflict ratio' AND object_name
            LIKE '%SQLServer:Transactions%') OR
        (counter_name = 'Update conflict ratio base' AND object_name
            LIKE '%SQLServer:Transactions%') OR
        (counter_name = 'Checkpoint Pages/sec' AND object_name
            LIKE '%Buffer Manager%') OR
        (counter_name = 'Buffer cache hit ratio' AND object_name
            LIKE '%Buffer Manager%') OR
        (counter_name = 'Buffer cache hit ratio base' AND object_name
            LIKE '%Buffer Manager%') OR
        (counter_name = 'Page writes/sec' AND object_name
            LIKE '%Buffer Manager%') OR
        (counter_name = 'Page reads/sec' AND object_name
            LIKE '%Buffer Manager%') OR
        (counter_name = 'Readahead pages/sec' AND object_name
            LIKE '%Buffer Manager%')
    '''

    @classmethod
    def rows_to_items(cls, collnames, resp):
        assert collnames[0] == 'counter_name'
        assert collnames[1] == 'cntr_value'
        item = {'name': 'system'}
        for row in resp:
            metric_name = row[0] \
                .strip() \
                .lower() \
                .replace(' ', '_') \
                .replace('-', '_') \
                .replace('/sec', '')  # we later add _diffps

            if metric_name.endswith('_ratio'):
                metric_name = metric_name[:-6]

            val = row[1]
            if metric_name.endswith('_(ms)'):
                metric_name = metric_name[:-5]
                val = float(val) / 1000.

            if metric_name == 'average_wait_time_base':
                val = float(val) / 1000.

            if metric_name in item:
                raise Exception(
                    f'Duplicate metric: {metric_name}: '
                    f'{val} vs {item[metric_name]}')
            item[metric_name] = val
        return {'system': item}
