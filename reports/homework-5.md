# Движки MergeTree
## VersionedCollapsingMergeTree
Судя по наличию полей Sign и Version. 
```sql
clickhouse :) CREATE TABLE tbl1
(
    UserID UInt64,
    PageViews UInt8,
    Duration UInt8,
    Sign Int8,
    Version UInt8
)
ENGINE = VersionedCollapsingMergeTree(Sign, Version)
ORDER BY UserID;

Ok.

0 rows in set. Elapsed: 0.013 sec. 

clickhouse :) INSERT INTO tbl1 VALUES (4324182021466249494, 5, 146, -1, 1);

Ok.

1 row in set. Elapsed: 0.004 sec. 

clickhouse :) INSERT INTO tbl1 VALUES (4324182021466249494, 5, 146, 1, 1),(4324182021466249494, 6, 185, 1, 2);

Ok.

2 rows in set. Elapsed: 0.004 sec. 

clickhouse :) SELECT * FROM tbl1;

   ┌──────────────UserID─┬─PageViews─┬─Duration─┬─Sign─┬─Version─┐
1. │ 4324182021466249494 │         5 │      146 │    1 │       1 │
2. │ 4324182021466249494 │         6 │      185 │    1 │       2 │
3. │ 4324182021466249494 │         5 │      146 │   -1 │       1 │
   └─────────────────────┴───────────┴──────────┴──────┴─────────┘

3 rows in set. Elapsed: 0.002 sec. 

clickhouse :) SELECT * FROM tbl1 final;

   ┌──────────────UserID─┬─PageViews─┬─Duration─┬─Sign─┬─Version─┐
1. │ 4324182021466249494 │         6 │      185 │    1 │       2 │
   └─────────────────────┴───────────┴──────────┴──────┴─────────┘

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

## SummingMergeTree
Судя по тому, что в value получается сумма по key.
```sql
clickhouse :) CREATE TABLE tbl2
(
    key UInt32,
    value UInt32
)
ENGINE = SummingMergeTree()
ORDER BY key;

Ok.

0 rows in set. Elapsed: 0.015 sec. 

clickhouse :) INSERT INTO tbl2 Values(1,1),(1,2),(2,1);

Ok.

3 rows in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT * FROM tbl2;

   ┌─key─┬─value─┐
1. │   1 │     3 │
2. │   2 │     1 │
   └─────┴───────┘

2 rows in set. Elapsed: 0.001 sec. 

clickhouse :) 
```

## ReplacingMergeTree
Судя по тому, что остаётся послежняя запись с одинаковым id.
```sql
clickhouse :) CREATE TABLE tbl3
(
    `id` Int32,
    `status` String,
    `price` String,
    `comment` String
)
ENGINE = ReplacingMergeTree
PRIMARY KEY (id)
ORDER BY (id, status);

Ok.

0 rows in set. Elapsed: 0.016 sec. 

clickhouse :) INSERT INTO tbl3 VALUES (23, 'success', '1000', 'Confirmed');

Ok.

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) INSERT INTO tbl3 VALUES (23, 'success', '2000', 'Cancelled');

Ok.

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT * from tbl3 WHERE id=23;

   ┌─id─┬─status──┬─price─┬─comment───┐
1. │ 23 │ success │ 2000  │ Cancelled │
2. │ 23 │ success │ 1000  │ Confirmed │
   └────┴─────────┴───────┴───────────┘

2 rows in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT * from tbl3 FINAL WHERE id=23;

   ┌─id─┬─status──┬─price─┬─comment───┐
1. │ 23 │ success │ 2000  │ Cancelled │
   └────┴─────────┴───────┴───────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

## MergeTree и AggregatingMergeTree
Так как в первой нет никаких признаков для чего-то иного.
```sql
clickhouse :) CREATE TABLE tbl4
(   CounterID UInt8,
    StartDate Date,
    UserID UInt64
) ENGINE = MergeTree
PARTITION BY toYYYYMM(StartDate) 
ORDER BY (CounterID, StartDate);

Ok.

0 rows in set. Elapsed: 0.004 sec. 

clickhouse :) INSERT INTO tbl4 VALUES(0, '2019-11-11', 1);

Ok.

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) INSERT INTO tbl4 VALUES(1, '2019-11-12', 1);

Ok.

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

А во второй используется агрегирующая функция.
```sql
clickhouse :) CREATE TABLE tbl5
(   CounterID UInt8,
    StartDate Date,
    UserID AggregateFunction(uniq, UInt64)
) ENGINE = AggregatingMergeTree
PARTITION BY toYYYYMM(StartDate) 
ORDER BY (CounterID, StartDate);

Ok.

0 rows in set. Elapsed: 0.006 sec. 

clickhouse :) INSERT INTO tbl5
SELECT CounterID, StartDate, uniqState(UserID)
FROM tbl4
GROUP BY CounterID, StartDate;

Ok.

0 rows in set. Elapsed: 0.004 sec. 

clickhouse :) INSERT INTO tbl5 VALUES (1,'2019-11-12',1);

Ok.
Error on processing query: Code: 53. DB::Exception: Cannot convert UInt64 to AggregateFunction(uniq, UInt64): While executing ValuesBlockInputFormat: data for INSERT was parsed from query. (TYPE_MISMATCH) (version 25.4.5.24 (official build))

clickhouse :) SELECT uniqMerge(UserID) AS state 
FROM tbl5 
GROUP BY CounterID, StartDate;

   ┌─state─┐
1. │     1 │
2. │     1 │
   └───────┘

2 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

## CollapsingMergeTree
По полю sign, т.к. в итоге остаётся псоледняя пришедшая запись с sign = 1.
```sql
clickhouse :) CREATE TABLE tbl6
(
    `id` Int32,
    `status` String,
    `price` String,
    `comment` String,
    `sign` Int8
)
ENGINE = CollapsingMergeTree(sign)
PRIMARY KEY (id)
ORDER BY (id, status);

Ok.

0 rows in set. Elapsed: 0.014 sec. 

clickhouse :) INSERT INTO tbl6 VALUES (23, 'success', '1000', 'Confirmed', 1);

Ok.

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) INSERT INTO tbl6 VALUES (23, 'success', '1000', 'Confirmed', -1), (23, 'success', '2000', 'Cancelled', 1);

Ok.

2 rows in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT * FROM tbl6;

   ┌─id─┬─status──┬─price─┬─comment───┬─sign─┐
1. │ 23 │ success │ 1000  │ Confirmed │    1 │
2. │ 23 │ success │ 1000  │ Confirmed │   -1 │
3. │ 23 │ success │ 2000  │ Cancelled │    1 │
   └────┴─────────┴───────┴───────────┴──────┘

3 rows in set. Elapsed: 0.002 sec. 

clickhouse :) SELECT * FROM tbl6 FINAL;

   ┌─id─┬─status──┬─price─┬─comment───┬─sign─┐
1. │ 23 │ success │ 2000  │ Cancelled │    1 │
   └────┴─────────┴───────┴───────────┴──────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) 
```
