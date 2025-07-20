# Интеграция ClickHouse с PostgreSQL
Постгрес поднят как сервис postgresql в [docker-compose.yml](../infrastructure/docker-compose.yml). Создадим базу и пару таблиц.

```sql
postgres=# CREATE DATABASE clickhouse;
CREATE DATABASE
postgres=# \c clickhouse
You are now connected to database "clickhouse" as user "postgres".
clickhouse=# CREATE TABLE t1 (id int, message text);
CREATE TABLE
clickhouse=# INSERT INTO t1 (id, message) VALUES (1, 'a'), (2, 'b'), (3, 'c');
INSERT 0 3
clickhouse=# CREATE TABLE t2 (k text, v text);
CREATE TABLE
clickhouse=# INSERT INTO t2 (k, v) VALUES ('k1', 'v1'), ('k2', 'v2'), ('k3', 'v3');
INSERT 0 3
clickhouse=# SELECT * FROM t1;
 id | message 
----+---------
  1 | a
  2 | b
  3 | c
(3 rows)

clickhouse=# SELECT * FROM t2;
 k  | v  
----+----
 k1 | v1
 k2 | v2
 k3 | v3
(3 rows)

clickhouse=# 
```
Запросим данные из постгреса функцией postgresql:
```sql
clickhouse :) SELECT * FROM postgresql('postgresql:5432', 'clickhouse', 't2', 'postgres', 'postgres');

   ┌─k──┬─v──┐
1. │ k1 │ v1 │
2. │ k2 │ v2 │
3. │ k3 │ v3 │
   └────┴────┘

3 rows in set. Elapsed: 0.013 sec. 

clickhouse :) 
```

Создадим в кликхаусе таблицу с движком Postgresql:
```sql

clickhouse :) CREATE TABLE t1 (
  id int,
  message text)
ENGINE = PostgreSQL('postgresql:5432', 'clickhouse', 't1', 'postgres', 'postgres');

Ok.

0 rows in set. Elapsed: 0.002 sec. 

clickhouse :) SELECT * FROM t1;

   ┌─id─┬─message─┐
1. │  1 │ a       │
2. │  2 │ b       │
3. │  3 │ c       │
   └────┴─────────┘

3 rows in set. Elapsed: 0.019 sec. 

clickhouse :) 
```
Строки корректные, но на каждый запро кликхаус идёт сам в постгрес. Чтобы этого не делать можно использовать MaterializedPostgreSQL движок:
```sql
clickhouse :) SET allow_experimental_database_materialized_postgresql=1;

Ok.

0 rows in set. Elapsed: 0.001 sec. 

clickhouse :) CREATE DATABASE postgresql
ENGINE = MaterializedPostgreSQL('postgresql:5432', 'clickhouse', 'postgres', 'postgres');

Ok.

0 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

Ничего не изменится, т.к. клик будет ругаться на отсутствующий первичный ключ:
```
2025.07.20 21:09:04.394302 [ 257 ] {} <Error> PostgreSQLReplicationHandler: Code: 36. DB::Exception: Table postgresql.t1 has no primary key and no replica identity index: while loading table `clickhouse`.`t1`. (BAD_ARGUMENTS), Stack trace (when copying this message, always include the lines below):
```

Добавим его:
```sql
postgres=# \c clickhouse
You are now connected to database "clickhouse" as user "postgres".
clickhouse=# ALTER TABLE t1 ADD PRIMARY KEY (id);
ALTER TABLE
clickhouse=# ALTER TABLE t2 ADD PRIMARY KEY (k);
ALTER TABLE
clickhouse=# 
```

Пересоздадим базу в кликхаусе:
```sql
clickhouse :) DROP DATABASE postgresql;

Ok.

0 rows in set. Elapsed: 0.013 sec. 

clickhouse :) SET allow_experimental_database_materialized_postgresql=1;

Ok.

0 rows in set. Elapsed: 0.001 sec. 

clickhouse :) CREATE DATABASE postgresql
ENGINE = MaterializedPostgreSQL('postgresql:5432', 'clickhouse', 'postgres', 'postgres');

Ok.

0 rows in set. Elapsed: 0.016 sec. 

clickhouse :) SHOW TABLES FROM postgresql;

   ┌─name─┐
1. │ t1   │
2. │ t2   │
   └──────┘

2 rows in set. Elapsed: 0.002 sec. 

clickhouse :) SELECT * FROM postgresql.t1;

   ┌─id─┬─message─┐
1. │  1 │ a       │
2. │  2 │ b       │
3. │  3 │ c       │
   └────┴─────────┘

3 rows in set. Elapsed: 0.002 sec. 

clickhouse :) SELECT * FROM postgresql.t2;

   ┌─k──┬─v──┐
1. │ k1 │ v1 │
2. │ k2 │ v2 │
3. │ k3 │ v3 │
   └────┴────┘

3 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 

Все строки на месте.
