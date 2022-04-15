import asyncio
import datetime
import decimal
import logging
import pytds
import uuid
from agentcoreclient.exceptions import IgnoreResultException
from calendar import timegm
from pytds.login import NtlmAuth

from .asset_cache import AssetCache
from .exceptions import MsSqlQueryException
from .utils import version_tuple


DEFAULT_MSSQL_PORT = 1433


class MsSqlCheckBase:

    qry = None
    type_name = None
    interval = 300
    required = False

    nextset_count = 0
    each_db = False
    ignore_duplicates = False
    auto_dedup_char = None
    auto_dedup_count = None
    db = None
    index_columns = None
    metric_lookups = None
    min_version = None
    top = None

    @classmethod
    def _get_item_name(cls, item):
        if cls.index_columns:
            item['name'] = val = '[' + '].['.join(map(str, [
                item[col] for col in cls.index_columns])) + ']'
        else:
            val = item['name']
        return val

    @classmethod
    def _item_to_out(cls, out, item, name):
        if cls.auto_dedup_char:
            # this is used in CheckVolumes to remain backwards compatible
            # itemnames for performance data
            while name in out:
                name += cls.auto_dedup_char
            item['name'] = name
        elif cls.auto_dedup_count:
            i = 1
            while name in out:
                name = '{}_{}'.format(name, i)
                if i > 1000:
                    raise MsSqlQueryException(
                        f'Max auto dedup (1000) reached for:{name}')
                i += 1
            item['name'] = name
        elif name in out:
            if cls.ignore_duplicates:
                return
            raise MsSqlQueryException(
                f'Duplicate itemname:{name}\nEXISTING:{out[name]}\nCUR:{item}')
        out[name] = item

    @classmethod
    def format_response(cls, resp, collnames):
        out = cls.rows_to_items(collnames, resp)
        if cls.metric_lookups:
            for lk in cls.metric_lookups:
                for item in out.values():
                    metric_name = lk['metricName']
                    lookups = lk['lookups']
                    item[lk.get('newMetricName', metric_name)] = \
                        lookups.get(str(item[metric_name]), '???')
        get_top_n_from_orderby = cls.top
        if get_top_n_from_orderby:
            itms = cls._get_top_n(out.values(), **get_top_n_from_orderby)
            out = {item['name']: item for item in itms}
        return out

    @classmethod
    def rows_to_items(cls, collnames, resp):
        out = {}
        for row in resp:
            item = {}
            for collname, val in zip(collnames, row):
                if isinstance(val, decimal.Decimal):
                    val = float(val)
                elif isinstance(val, datetime.datetime):
                    val = timegm(val.utctimetuple())
                elif isinstance(val, uuid.UUID):
                    val = str(val)
                item[collname] = val
            name = cls._get_item_name(item)
            cls._item_to_out(out, item, name)
        return out

    @staticmethod
    def _get_top_n(items, count, orderBy):
        sortedItems = sorted(items, key=lambda i: tuple(
            -i[ky[1:]] if ky[0] == '-' else i[ky] for ky in orderBy))
        return sortedItems[:count]

    @classmethod
    async def run(cls, data, asset_config=None):
        try:
            asset_id = data['hostUuid']
            config = data['hostConfig']['probeConfig']['msSqlProbe']
            ip4 = config['ip4']
            port = config.get('port', DEFAULT_MSSQL_PORT)
        except Exception as e:
            logging.error(
                f'invalid check configuration: {e.__class__.__name__}: {e}')
            return

        if asset_config is None or 'credentials' not in asset_config:
            logging.warning(f'missing asset config for {asset_id} {ip4}')
            return

        loop = asyncio.get_event_loop()
        state_data = {}
        try:
            func = cls._get_data_each_db if cls.each_db \
                else cls._get_data
            await loop.run_in_executor(
                None,
                func,
                state_data,
                ip4,
                port,
                asset_config['credentials']['username'],
                asset_config['credentials']['password']
            )
        except IgnoreResultException as ex:
            raise
        except MsSqlQueryException as ex:
            raise
        except Exception as ex:
            msg = str(ex)
            if msg.startswith('SQL Server message'):
                msg = '\n'.join(msg.split('\n')[1:])
            if 'Previous statement didn\'t produce any results' in msg:
                state_data[cls.type_name] = {}
            else:
                raise Exception(msg)
        return state_data

    @classmethod
    def _get_version(cls, host, port, username, password):
        with cls._get_conn(host, port, username, password) as conn:
            with conn.cursor() as cur:
                cur.execute('''
                    SELECT SERVERPROPERTY(\'ProductVersion\') AS ProductVersion
                ''')
                res = cur.fetchall()
                return res[0][0]

    @classmethod
    def _check_version(cls, host, port, username, password):
        if cls.min_version:
            min_version = cls.min_version
            version, _ = AssetCache.get_value((host, port, 'version'))
            if version is None:
                version = cls._get_version(host, port, username, password)
                AssetCache.set_value((host, port, 'version'), version)
            check_name = cls.__name__
            if version_tuple(version) < version_tuple(min_version):
                raise IgnoreResultException(
                    f'{check_name} requires SQL version {min_version}, '
                    f'current is {version}.'
                )

    @classmethod
    def _get_data(cls, cr, host, port, username, password):
        cls._check_version(host, port, username, password)

        with cls._get_conn(host, port, username, password, cls.db) as conn:
            with conn.cursor() as cur:
                cur.execute(cls.qry)
                for _ in range(cls.nextset_count):
                    cur.nextset()
                res = cur.fetchall()
                collnames = [tup[0] for tup in cur.description]
                cr[cls.type_name] = cls.format_response(res, collnames)

    @staticmethod
    def _get_conn(host, port, username, password, dbname=None):
        auth = NtlmAuth(username, password) if '\\' in username else None
        return pytds.connect(
            host,
            dbname,
            username,
            password,
            port=port,
            auth=auth,
            appname='oversight'
        )

    @classmethod
    def _get_data_each_db(cls, cr, host, port, username, password):
        cls._check_version(host, port, username, password)

        with cls._get_conn(host, port, username, password) as conn:
            dbs, expired = AssetCache.get_value((host, port, 'dbnames'))
            if dbs is None or expired:
                dbs = cls._get_db_names(conn)
                AssetCache.set_value((host, port, 'dbnames'), dbs, 900)

            # blame [msdb] for our CPU usage. Since we otherwise are blaming
            # the measured instances
            with conn.cursor() as cur:
                cur.execute('USE [msdb];\r\n{}'.format(cls.qry))
                cur.fetchall()

            res = []
            collnames = []
            for db in dbs:
                try:
                    with conn.cursor() as cur:
                        cur.execute('USE [{}];\r\n{}'.format(db, cls.qry))
                        if not collnames:
                            collnames = [tup[0] for tup in cur.description]
                        res.extend(cur.fetchall())
                except Exception as ex:
                    msg = str(ex)
                    if 'cannot be opened. It is in the middle of a restore' \
                            in msg:
                        continue
                    else:
                        raise
            cr[cls.type_name] = cls.format_response(res, collnames)

    @staticmethod
    def _get_db_names(conn):
        with conn.cursor() as cur:
            cur.execute('''
                SELECT name FROM sys.databases
                WHERE name not in ('master', 'tempdb', 'model', 'msdb')
            ''')
            res = cur.fetchall()
            dbs = [row[0] for row in res]
            return dbs
