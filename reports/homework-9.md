# Репликация и удаление
Конфигурация кластера с именем otus описана в [cluster.xml](../infrastructure/config.d/cluster.xml).
Конфигурации макросов хранятся в каталоге [macros](../infrastructure/macros) и подключаются через bind mount каждый в свою в реплику в [docker-compose.yml](../infrastructure/docker-compose.yml).

## Возьмите любой демонстрационный DATASET
Возьму уже имеющийся в базе TPC-H [homework-2.md](../reports/homework-2.md).

## Конвертируйте таблицу в реплицируемую
Конвертирую таблицу orders о 613МБ:
```sql
clickhouse :) SELECT 
    database,
    table,
    sum(bytes) as size
FROM system.parts
WHERE active
    AND database = 'tpch'
    AND table = 'orders'
GROUP BY database, table;

   ┌─database─┬─table──┬──────size─┐
1. │ tpch     │ orders │ 643397441 │
   └──────────┴────────┴───────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) DETACH TABLE tpch.orders;

Ok.

0 rows in set. Elapsed: 0.001 sec. 

clickhouse :) ATTACH TABLE tpch.orders AS REPLICATED;

Ok.

0 rows in set. Elapsed: 0.006 sec. 

clickhouse :) SYSTEM RESTORE REPLICA tpch.orders;

Ok.

0 rows in set. Elapsed: 0.049 sec. 

clickhouse :) SELECT
    shard_num,
    replica_num,
    host_name,
    host_address,
    port,
    is_local
FROM system.clusters
WHERE cluster = 'otus';

Query id: a17ddb34-b002-4046-a356-72e2a4a7745a

   ┌─shard_num─┬─replica_num─┬─host_name──┬─host_address─┬─port─┬─is_local─┐
1. │         1 │           1 │ clickhouse │ 172.18.0.4   │ 9000 │        1 │
   └───────────┴─────────────┴────────────┴──────────────┴──────┴──────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

## Добавьте 2 реплики
В [docker-compose.yml](../infrastructure/docker-compose.yml) это сервисы clickhouse_2 и clickhouse_3.
```sql
clickhouse :) SELECT
    shard_num,
    replica_num,
    host_name,
    host_address,
    port,
    is_local
FROM system.clusters
WHERE cluster = 'otus';

   ┌─shard_num─┬─replica_num─┬─host_name────┬─host_address─┬─port─┬─is_local─┐
1. │         1 │           1 │ clickhouse   │ 172.18.0.4   │ 9000 │        1 │
2. │         1 │           2 │ clickhouse-2 │ 172.18.0.2   │ 9000 │        0 │
3. │         1 │           3 │ clickhouse-3 │ 172.18.0.3   │ 9000 │        0 │
   └───────────┴─────────────┴──────────────┴──────────────┴──────┴──────────┘

3 rows in set. Elapsed: 0.002 sec. 

clickhouse :)
```
Чтобы добавить реплики к самой таблице, надо создать на каждой новой ноде такую же ReplicatedMergeTree таблицу с тем же путём в зукипере, только с другим значением replica.
Делать это руками мне лень, и, т.к. у нас настроен макрос на каждой ноде, то можно отправить CREATE TABLE IF NOT EXISTS ... ON CLUSTER ... в любую ноду и таблица создастся с нужными параметрами там, где её нет. Ещё надо не забыть создать базу в каждой новой ноде, тоже через IF NOT EXISTS ON CLUSTER. DDL таблицы получим через SHOW CREATE TABLE.
```sql
clickhouse :) SHOW CREATE TABLE tpch.orders;

   ┌─statement──────────────────────────────────────────────────────────────────────┐
1. │ CREATE TABLE tpch.orders                                                      ↴│
   │↳(                                                                             ↴│
   │↳    `o_orderkey` Int32,                                                       ↴│
   │↳    `o_custkey` Int32,                                                        ↴│
   │↳    `o_orderstatus` String,                                                   ↴│
   │↳    `o_totalprice` Decimal(15, 2),                                            ↴│
   │↳    `o_orderdate` Date,                                                       ↴│
   │↳    `o_orderpriority` String,                                                 ↴│
   │↳    `o_clerk` String,                                                         ↴│
   │↳    `o_shippriority` Int32,                                                   ↴│
   │↳    `o_comment` String                                                        ↴│
   │↳)                                                                             ↴│
   │↳ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')↴│
   │↳ORDER BY o_orderkey                                                           ↴│
   │↳SETTINGS index_granularity = 8192                                              │
   └────────────────────────────────────────────────────────────────────────────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :)
```
Видно, что глупый кликхаус при формировании зноды во время ATTACH AS REPLICATED использовал некий макрос UUID, поэтому реальную зноду этой таблицы надо достать из списка реплик:
```sql
clickhouse :) SELECT zookeeper_path
FROM system.replicas
WHERE 
    database = 'tpch'
    AND table = 'orders';

   ┌─zookeeper_path────────────────────────────────────────────┐
1. │ /clickhouse/tables/dddaeb1e-47c6-4642-b400-f90f09d97def/1 │
   └───────────────────────────────────────────────────────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) l_files
```
Теперь можно создать базу и табличку на нодах:
```sql
clickhouse :) CREATE DATABASE IF NOT EXISTS tpch ON CLUSTER 'otus';

   ┌─host─────────┬─port─┬─status─┬─error─┬─num_hosts_remaining─┬─num_hosts_active─┐
1. │ clickhouse-2 │ 9000 │      0 │       │                   2 │                0 │
2. │ clickhouse   │ 9000 │      0 │       │                   1 │                0 │
3. │ clickhouse-3 │ 9000 │      0 │       │                   0 │                0 │
   └──────────────┴──────┴────────┴───────┴─────────────────────┴──────────────────┘

3 rows in set. Elapsed: 0.070 sec. 

clickhouse :) CREATE TABLE IF NOT EXISTS tpch.orders ON CLUSTER 'otus' (
    o_orderkey       Int32,
    o_custkey        Int32,
    o_orderstatus    String,
    o_totalprice     Decimal(15,2),
    o_orderdate      Date,
    o_orderpriority  String,
    o_clerk          String,
    o_shippriority   Int32,
    o_comment        String)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/dddaeb1e-47c6-4642-b400-f90f09d97def/{shard}', '{replica}')
ORDER BY (o_orderkey);

   ┌─host─────────┬─port─┬─status─┬─error─┬─num_hosts_remaining─┬─num_hosts_active─┐
1. │ clickhouse-2 │ 9000 │      0 │       │                   2 │                0 │
2. │ clickhouse   │ 9000 │      0 │       │                   1 │                0 │
3. │ clickhouse-3 │ 9000 │      0 │       │                   0 │                0 │
   └──────────────┴──────┴────────┴───────┴─────────────────────┴──────────────────┘

3 rows in set. Elapsed: 0.064 sec. 

clickhouse :)
```

## Выполните запросы
Команду из задания я немного модифицировал, т.к. без яввного указания логина и пароля при обращении не к локальнмоу серверу возвращается AUTHENTICATION_FAILED.
```bash
root@clickhouse:/# clickhouse-client -q "SELECT
    getMacro('replica'),
    *
FROM remote('clickhouse,clickhouse-2,clickhouse-3', system, parts, 'default', 'default')
WHERE 
    database = 'tpch'
    AND table = 'orders'
FORMAT JSONEachRow;" > /tmp/system.parts.json
root@clickhouse:/# clickhouse-client -q "SELECT *
FROM system.replicas
WHERE 
    database = 'tpch'
    AND table = 'orders'
FORMAT JSONEachRow;" > /tmp/system.replicas.json
root@clickhouse:/# 
```
Результирующие файлы:
- [system.parts.json](../results/homework-9/system.parts.json)
- [system.replicas.json](../results/homework-9/system.replicas.json)

## Добавьте или выберите колонку с типом Date
В tpch.orders уже есть подходящая o_orderdate с типом Date со значениями от 1992 до 1998. Если поставить TTL в 1 день, то, все данные должны будут исчезнуть при следующем мёрдже.
```sql
clickhouse :) SELECT DISTINCT toYear(o_orderdate) FROM tpch.orders;

   ┌─toYear(o_orderdate)─┐
1. │                1992 │
2. │                1993 │
3. │                1994 │
4. │                1997 │
5. │                1996 │
6. │                1995 │
7. │                1998 │
   └─────────────────────┘

7 rows in set. Elapsed: 0.036 sec. Processed 15.00 million rows, 30.00 MB (422.37 million rows/s., 844.75 MB/s.)
Peak memory usage: 846.42 KiB.

clickhouse :) ALTER TABLE tpch.orders ON CLUSTER 'otus' MODIFY TTL o_orderdate + INTERVAL 1 DAY;

   ┌─host─────────┬─port─┬─status─┬─error─┬─num_hosts_remaining─┬─num_hosts_active─┐
1. │ clickhouse-2 │ 9000 │      0 │       │                   2 │                0 │
2. │ clickhouse   │ 9000 │      0 │       │                   1 │                0 │
3. │ clickhouse-3 │ 9000 │      0 │       │                   0 │                0 │
   └──────────────┴──────┴────────┴───────┴─────────────────────┴──────────────────┘

3 rows in set. Elapsed: 1.413 sec. 

clickhouse :) SELECT count(1) FROM tpch.orders;

   ┌─count(1)─┐
1. │        0 │
   └──────────┘

1 row in set. Elapsed: 0.001 sec. 

clickhouse :) SHOW CREATE TABLE tpch.orders;

   ┌─statement──────────────────────────────────────────────────────────────────────┐
1. │ CREATE TABLE tpch.orders                                                      ↴│
   │↳(                                                                             ↴│
   │↳    `o_orderkey` Int32,                                                       ↴│
   │↳    `o_custkey` Int32,                                                        ↴│
   │↳    `o_orderstatus` String,                                                   ↴│
   │↳    `o_totalprice` Decimal(15, 2),                                            ↴│
   │↳    `o_orderdate` Date,                                                       ↴│
   │↳    `o_orderpriority` String,                                                 ↴│
   │↳    `o_clerk` String,                                                         ↴│
   │↳    `o_shippriority` Int32,                                                   ↴│
   │↳    `o_comment` String                                                        ↴│
   │↳)                                                                             ↴│
   │↳ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')↴│
   │↳ORDER BY o_orderkey                                                           ↴│
   │↳TTL o_orderdate + toIntervalDay(1)                                            ↴│
   │↳SETTINGS index_granularity = 8192                                              │
   └────────────────────────────────────────────────────────────────────────────────┘

1 row in set. Elapsed: 0.001 sec. 

clickhouse :) 
```
