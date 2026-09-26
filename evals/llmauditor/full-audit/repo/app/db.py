from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

from app import config

pool = ConnectionPool(config.DATABASE_URL, kwargs={"row_factory": dict_row}, open=True)


def connect():
    return pool.connection()


def fetch_one(sql, params=()):
    with pool.connection() as conn:
        return conn.execute(sql, params).fetchone()


def fetch_all(sql, params=()):
    with pool.connection() as conn:
        return conn.execute(sql, params).fetchall()


def execute(sql, params=()):
    with pool.connection() as conn:
        conn.execute(sql, params)
