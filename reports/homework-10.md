# Шардирование
## 6 экземпляров и две топологии
Добавлю к уже имеющимся трём экземплярям ещё столько же: clickhouse_4, clickhouse_5 и clickhouse_6.
Сконфигурирую два кластера: 2 шарда по 3 реплики и 3 шарда по 2 реплики, см. [cluster.xml](../infrastructure/config.d/cluster.xml).
Секции с макросом для каждой ноды находятся в каталоге [macros](../infrastructure/macros).
```sql
clickhouse :) SELECT
    cluster,
    shard_num,
    replica_num,
    host_name,
    host_address,
    port,
    is_local
FROM system.clusters;

    ┌─cluster──┬─shard_num─┬─replica_num─┬─host_name────┬─host_address─┬─port─┬─is_local─┐
 1. │ default  │         1 │           1 │ localhost    │ 127.0.0.1    │ 9000 │        1 │
 2. │ otus2S3R │         1 │           1 │ clickhouse   │ 172.18.0.3   │ 9000 │        1 │
 3. │ otus2S3R │         1 │           2 │ clickhouse-2 │ 172.18.0.6   │ 9000 │        0 │
 4. │ otus2S3R │         1 │           3 │ clickhouse-3 │ 172.18.0.7   │ 9000 │        0 │
 5. │ otus2S3R │         2 │           1 │ clickhouse-4 │ 172.18.0.9   │ 9000 │        0 │
 6. │ otus2S3R │         2 │           2 │ clickhouse-5 │ 172.18.0.4   │ 9000 │        0 │
 7. │ otus2S3R │         2 │           3 │ clickhouse-6 │ 172.18.0.8   │ 9000 │        0 │
 8. │ otus3S2R │         1 │           1 │ clickhouse   │ 172.18.0.3   │ 9000 │        1 │
 9. │ otus3S2R │         1 │           2 │ clickhouse-2 │ 172.18.0.6   │ 9000 │        0 │
10. │ otus3S2R │         2 │           1 │ clickhouse-3 │ 172.18.0.7   │ 9000 │        0 │
11. │ otus3S2R │         2 │           2 │ clickhouse-4 │ 172.18.0.9   │ 9000 │        0 │
12. │ otus3S2R │         3 │           1 │ clickhouse-5 │ 172.18.0.4   │ 9000 │        0 │
13. │ otus3S2R │         3 │           2 │ clickhouse-6 │ 172.18.0.8   │ 9000 │        0 │
    └──────────┴───────────┴─────────────┴──────────────┴──────────────┴──────┴──────────┘

13 rows in set. Elapsed: 0.001 sec. 

clickhouse :) 
```

## Distributed таблицы
Создадим таблицу на кластере о двух шардах с целевой таблицей system.one. Запрос к ней вернёт два значения, т.к. шардов два.
```sql
CREATE TABLE otus2S3R ON CLUSTER 'otus2S3R'
ENGINE = Distributed('otus2S3R', 'system', 'one', rand());

   ┌─host─────────┬─port─┬─status─┬─error─┬─num_hosts_remaining─┬─num_hosts_active─┐
1. │ clickhouse-2 │ 9000 │      0 │       │                   5 │                0 │
2. │ clickhouse   │ 9000 │      0 │       │                   4 │                0 │
3. │ clickhouse-6 │ 9000 │      0 │       │                   3 │                0 │
4. │ clickhouse-4 │ 9000 │      0 │       │                   2 │                0 │
5. │ clickhouse-5 │ 9000 │      0 │       │                   1 │                0 │
6. │ clickhouse-3 │ 9000 │      0 │       │                   0 │                0 │
   └──────────────┴──────┴────────┴───────┴─────────────────────┴──────────────────┘

6 rows in set. Elapsed: 0.069 sec. 

clickhouse :) SELECT *, hostName(), _shard_num FROM otus2S3R;

   ┌─dummy─┬─hostName()───┬─_shard_num─┐
1. │     0 │ clickhouse   │          1 │
2. │     0 │ clickhouse-4 │          2 │
   └───────┴──────────────┴────────────┘

2 rows in set. Elapsed: 0.012 sec. 

clickhouse :)  
```
Создадим таблицу на кластере о трёх шардах с такой же целевой таблицей system.one. Запрос к ней вернёт уже три значения, т.к. шардов три.
```sql
clickhouse :) CREATE TABLE otus3S2R ON CLUSTER 'otus3S2R'
ENGINE = Distributed('otus3S2R', 'system', 'one', rand());

   ┌─host─────────┬─port─┬─status─┬─error─┬─num_hosts_remaining─┬─num_hosts_active─┐
1. │ clickhouse-2 │ 9000 │      0 │       │                   5 │                0 │
2. │ clickhouse   │ 9000 │      0 │       │                   4 │                0 │
3. │ clickhouse-6 │ 9000 │      0 │       │                   3 │                0 │
4. │ clickhouse-4 │ 9000 │      0 │       │                   2 │                0 │
5. │ clickhouse-3 │ 9000 │      0 │       │                   1 │                0 │
6. │ clickhouse-5 │ 9000 │      0 │       │                   0 │                0 │
   └──────────────┴──────┴────────┴───────┴─────────────────────┴──────────────────┘

6 rows in set. Elapsed: 0.073 sec. 

clickhouse :) SELECT *, hostName(), _shard_num FROM otus3S2R;

   ┌─dummy─┬─hostName()───┬─_shard_num─┐
1. │     0 │ clickhouse   │          1 │
2. │     0 │ clickhouse-4 │          2 │
3. │     0 │ clickhouse-5 │          3 │
   └───────┴──────────────┴────────────┘

3 rows in set. Elapsed: 0.008 sec. 

clickhouse :) 
```
