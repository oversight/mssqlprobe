import json
import os

from .base import MsSqlCheckBase
from .checkApplicationSessions import CheckApplicationSessions
from .checkDbPerfCounters import CheckDbPerfCounters
from .checkInstancePerfCounters import CheckInstancePerfCounters
from .checkPlanCache import CheckPlanCache


CHECKS = {
    'CheckApplicationSessions': CheckApplicationSessions,
    'CheckPlanCache': CheckPlanCache,
    'CheckInstancePerfCounters': CheckInstancePerfCounters,
    'CheckDbPerfCounters': CheckDbPerfCounters
}

CHECKS_FOLDER = 'checks'

for fn in os.listdir(CHECKS_FOLDER):
    if fn.endswith('.sql'):
        check_name = fn[0].upper() + fn[1:-4]
        sql_file = os.path.join(CHECKS_FOLDER, fn)
        with open(sql_file) as f:
            query = f.read()
        meta_file = os.path.join(CHECKS_FOLDER, fn.replace('.sql', '.json'))
        if os.path.exists(meta_file):
            try:
                with open(meta_file) as f:
                    meta = json.load(f)
            except Exception as ex:
                raise Exception('failed to load {} {}'.format(meta_file, ex))
        else:
            meta = {}
        assert isinstance(meta, dict)

        CHECKS[check_name] = type(check_name, (MsSqlCheckBase, ), {
            'auto_dedup_char': meta.pop('autoDedupChar', None),
            'auto_dedup_count': meta.pop('autoDedupCount', None),
            'db': meta.pop('db', None),
            'index_columns': meta.pop('indexColumns', None),
            'metric_lookups': meta.pop('metricLookups', None),
            'min_version': meta.pop('minVersion', None),
            'top': meta.pop('top', None),
            'nextset_count': meta.pop('nextSetCount', 0),
            'each_db': meta.pop('eachDb', False),
            'ignore_duplicates': meta.pop('ignoreDuplicates', False),
            'required': meta.pop('required', False),
            'interval': meta.pop('defaultCheckInterval', 300),
            'type_name': meta.pop('typeName', check_name.lower()[5:]),
            'qry': query
        })
