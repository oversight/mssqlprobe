from .base import MsSqlCheckBase


class CheckDbPerfCounters(MsSqlCheckBase):

    type_name = 'dbperf'

    # ratioMetrics = {
    #     'cache_hit': 'cache_hit_ratio_base'
    # }

    # diffpsMetrics = [
    #     'write_transactions',
    #     'log_flushes',
    #     'log_bytes_flushed',
    #     'log_flush_waits',
    #     'transactions'
    # ]

    qry = '''
        SELECT
            counter_name,
            cntr_value,
            LTRIM(RTRIM(instance_name)) AS instance_name
        FROM
            sys.dm_os_performance_counters
        WHERE
            (counter_name = 'Cache Hit Ratio' AND object_name
                LIKE '%SQLServer:Catalog Metadata%') OR
            (counter_name = 'Cache Hit Ratio Base' AND object_name
                LIKE '%SQLServer:Catalog Metadata%') OR
            (counter_name = 'Cache Entries Count' AND object_name
                LIKE '%SQLServer:Catalog Metadata%') OR
            (counter_name = 'Cache Entries Pinned Count' AND object_name
                LIKE '%SQLServer:Catalog Metadata%') OR
            (counter_name = 'Write Transactions/sec' AND object_name
                LIKE '%SQLServer:Databases%') OR
            (counter_name = 'Log Flushes/sec' AND object_name
                LIKE '%SQLServer:Databases%') OR
            (counter_name = 'Log Bytes Flushed/sec' AND object_name
                LIKE '%SQLServer:Databases%') OR
            (counter_name = 'Log Flush Waits/sec' AND object_name
                LIKE '%SQLServer:Databases%') OR
            (counter_name = 'Transactions/sec' AND object_name
                LIKE '%SQLServer:Databases%')
    '''

    @classmethod
    def rows_to_items(cls, collnames, resp):
        assert collnames[0] == 'counter_name'
        assert collnames[1] == 'cntr_value'
        assert collnames[2] == 'instance_name'
        out = {}

        for row in resp:
            value = row[1]
            item_name = row[2]
            if item_name not in out:
                out[item_name] = {'name': item_name}
            item = out[item_name]
            metric_name = row[0] \
                .strip() \
                .lower() \
                .replace(' ', '_') \
                .replace('/sec', '')  # we later add _diffps

            if metric_name.endswith('_ratio'):
                metric_name = metric_name[:-6]
            item[metric_name] = value
        return out
