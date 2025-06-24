# Проекции и материализованные представления
## Создание таблицы
```sql
clickhouse :) CREATE TABLE sales (
    id UInt32,
    product_id UInt32,
    quantity UInt32,
    price Decimal64(2),
    sale_date DateTime
)
ENGINE = MergeTree
ORDER BY (product_id, sale_date);

Ok.

0 rows in set. Elapsed: 0.016 sec. 

clickhouse :) INSERT INTO sales
SELECT id, product_id, quantity, abs(price) / 1000, sale_date
FROM generateRandom('
        id UInt32,
        product_id UInt8,
        quantity UInt8,
        price Decimal32(2),
        sale_date DateTime
    ') LIMIT 1000000;

Ok.

0 rows in set. Elapsed: 0.106 sec. Processed 1.11 million rows, 15.57 MB (10.45 million rows/s., 146.27 MB/s.)
Peak memory usage: 45.91 MiB.

clickhouse :) 
```

## Создание проекции
```sql
clickhouse :) ALTER TABLE sales ADD PROJECTION sales_by_product (
    SELECT product_id,
        sum(multiplyDecimal(toDecimal64(quantity, 0), toDecimal64(price, 2))) as total
    GROUP BY product_id
);

Ok.

0 rows in set. Elapsed: 0.006 sec. 

clickhouse :) ALTER TABLE sales MATERIALIZE PROJECTION sales_by_product;

Ok.

0 rows in set. Elapsed: 0.013 sec. 

clickhouse :) 
```

## Создание материализованного представления
Создадим AggregatingMergeTree таблицу для хранения данных и само матвью.
```sql
clickhouse :) CREATE TABLE sales_agg (
    product_id UInt32,
    total_quantity AggregateFunction(sum, UInt32),
    total_sales AggregateFunction(count, UInt32)
)
ENGINE = AggregatingMergeTree()
ORDER BY product_id;

Ok.

0 rows in set. Elapsed: 0.006 sec. 

clickhouse :) CREATE MATERIALIZED VIEW sales_mv
TO sales_agg
AS SELECT
    product_id,
    sumState(quantity) as total_quantity,
    countState(id) as total_sales
FROM sales
GROUP BY product_id;

Ok.

0 rows in set. Elapsed: 0.020 sec. 

clickhouse :) 
```
## Запросы к данным
### Проекция
```sql
clickhouse :) SELECT
    product_id,
    sum(multiplyDecimal(toDecimal64(quantity, 0), toDecimal64(price, 2))) as total
FROM sales
GROUP BY product_id

Query id: e4267646-0488-401f-bb7e-2cd7d5c8d280

     ┌─product_id─┬─────────total─┐
  1. │          0 │ 2373058899.08 │
  2. │        198 │ 2348078511.77 │
  3. │        116 │    2351951426 │
  4. │         66 │ 2237208443.28 │
  5. │        240 │ 2368151638.55 │
    ...          ...             ...
256. │        102 │ 2331664505.02 │
     └─product_id─┴─────────total─┘

256 rows in set. Elapsed: 0.004 sec. 
```

Проверим, что запрос действительно использовал проекцию:
```sql
clickhouse :) SELECT query, projections
FROM system.query_log
WHERE type = 'QueryFinish'
    AND query_id = 'e4267646-0488-401f-bb7e-2cd7d5c8d280';

   ┌─query──────────────────────────────────────────────────────────────────────────────┬─projections────────────────────────┐
1. │ SELECT                                                                            ↴│ ['default.sales.sales_by_product'] │
   │↳    product_id,                                                                   ↴│                                    │
   │↳    sum(multiplyDecimal(toDecimal64(quantity, 0), toDecimal64(price, 2))) as total↴│                                    │
   │↳FROM sales                                                                        ↴│                                    │
   │↳GROUP BY product_id                                                                │                                    │
   └────────────────────────────────────────────────────────────────────────────────────┴────────────────────────────────────┘

1 row in set. Elapsed: 0.015 sec. Processed 269.30 thousand rows, 12.39 MB (17.84 million rows/s., 820.50 MB/s.)
Peak memory usage: 52.29 KiB.

clickhouse :) 
```

План запроса тоже покажет использование материализованной проекции:
```sql
clickhouse :) EXPLAIN SELECT
    product_id,
    sum(multiplyDecimal(toDecimal64(quantity, 0), toDecimal64(price, 2))) as total
FROM sales
GROUP BY product_id

   ┌─explain────────────────────────────────────┐
1. │ Expression ((Project names + Projection))  │
2. │   Aggregating                              │
3. │     Expression                             │
4. │       ReadFromMergeTree (sales_by_product) │
   └────────────────────────────────────────────┘

4 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

### Матвью
В нём пусто, т.к. при создании уже имеющиеся в sales данные им не обрабатываются.
```sql
clickhouse :) SELECT
    product_id,
    sumMerge(total_quantity) AS total_quantity,
    countMerge(total_sales) AS total_sales
FROM sales_mv
GROUP BY product_id
ORDER BY product_id;

Ok.

0 rows in set. Elapsed: 0.002 sec. 

clickhouse :)
```
Для наполнения данными надо предварительно однократно выполнить вручную вставку в целевую таблицу результата запроса из матвью:
```sql
clickhouse :) INSERT INTO sales_agg
SELECT
    product_id,
    sumState(quantity) as total_quantity,
    countState(id) as total_sales
FROM sales
GROUP BY product_id

Ok.

0 rows in set. Elapsed: 0.010 sec. Processed 1.00 million rows, 12.00 MB (100.53 million rows/s., 1.21 GB/s.)
Peak memory usage: 56.69 KiB.

clickhouse :) SELECT
    product_id,
    sumMerge(total_quantity) AS total_quantity,
    countMerge(total_sales) AS total_sales
FROM sales_mv
GROUP BY product_id
ORDER BY product_id;

     ┌─product_id─┬─total_quantity─┬─total_sales─┐
  1. │          0 │         505691 │        3898 │
  2. │          1 │         514545 │        3964 │
  3. │          2 │         479080 │        3761 │
  4. │          3 │         496173 │        3879 │
  5. │          4 │         478250 │        3794 │
    ...          ...              ...           ...
256. │        255 │         492664 │        3922 │
     └─product_id─┴─total_quantity─┴─total_sales─┘

256 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

## Задание со звездочкой
### INSERT
Добавим ещё 1М данных:
```sql
clickhouse :) INSERT INTO sales
SELECT id, product_id, quantity, abs(price) / 1000, sale_date
FROM generateRandom('
        id UInt32,
        product_id UInt8,
        quantity UInt8,
        price Decimal32(2),
        sale_date DateTime
    ') LIMIT 1000000;

Ok.

0 rows in set. Elapsed: 0.616 sec. Processed 3.31 million rows, 54.31 MB (5.37 million rows/s., 88.23 MB/s.)
Peak memory usage: 86.48 MiB.

clickhouse :) 
```
Посмотрим в проекцию по product_id 0 и сравним значение в total: 
```sql
clickhouse :) SELECT
    product_id,
    sum(multiplyDecimal(toDecimal64(quantity, 0), toDecimal64(price, 2))) as total
FROM sales
WHERE product_id = 0
GROUP BY product_id

   ┌─product_id─┬─────────total─┐
1. │          0 │ 4738176868.47 │
   └────────────┴───────────────┘

1 row in set. Elapsed: 0.004 sec. 

clickhouse :) 
```
Было 2373058899.08, стало 4738176868.47 -- почти в два раза больше, что ожидаемо, т.к. мы нагенерировали такой же объём таких же случайных данных.
Посмотрим в матвью тоже по product_id 0:
```sql
clickhouse :) SELECT
    product_id,
    sumMerge(total_quantity) AS total_quantity,
    countMerge(total_sales) AS total_sales
FROM sales_mv
WHERE product_id = 0
GROUP BY product_id;

   ┌─product_id─┬─total_quantity─┬─total_sales─┐
1. │          0 │        1004212 │        7805 │
   └────────────┴────────────────┴─────────────┘

1 row in set. Elapsed: 0.004 sec. 

clickhouse :) 
```
Тоже ожидаемый и логичный прирост в два раза.

### UPDATE
Обновим все данные по product_id 0 на 0 и посмотрим в проекцию и матвью:
```sql
clickhouse :) ALTER TABLE sales UPDATE quantity = 0, price = 0 WHERE product_id = 0;

Ok.

0 rows in set. Elapsed: 0.004 sec. 

clickhouse :) SELECT
    product_id,
    sum(multiplyDecimal(toDecimal64(quantity, 0), toDecimal64(price, 2))) as total
FROM sales
WHERE product_id = 0
GROUP BY product_id

   ┌─product_id─┬─total─┐
1. │          0 │     0 │
   └────────────┴───────┘

1 row in set. Elapsed: 0.007 sec. 

clickhouse :) SELECT
    product_id,
    sumMerge(total_quantity) AS total_quantity,
    countMerge(total_sales) AS total_sales
FROM sales_mv
WHERE product_id = 0
GROUP BY product_id;

   ┌─product_id─┬─total_quantity─┬─total_sales─┐
1. │          0 │        1004212 │        7805 │
   └────────────┴────────────────┴─────────────┘

1 row in set. Elapsed: 0.004 sec. 

clickhouse :) 
```
Проекция обновилась, а матвью нет, т.к. матвью реагирует только на события вставки строк в исходную таблицу.

### DELETE
Удалим все данные по product_id 0:
```sql
clickhouse :) DELETE FROM sales WHERE product_id = 0;

Elapsed: 0.002 sec. 

Received exception from server (version 25.4.5):
Code: 344. DB::Exception: Received from localhost:9000. DB::Exception: DELETE query is not allowed for table default.sales because as it has projections and setting lightweight_mutation_projection_mode is set to THROW. User should change lightweight_mutation_projection_mode OR drop all the projections manually before running the query. (SUPPORT_IS_DISABLED)

clickhouse :) 
```
БД не даёт этого сделать, т.к. у таблицы есть проекция и опция lightweight_mutation_projection_mode по умолчанию установлена в throw (выброс эксепшна).

### TRUNCATE
Попробуем целиком очистить таблицу и посмотрим в проекцию и матвью:
```sql
clickhouse :) TRUNCATE TABLE sales;

Ok.

0 rows in set. Elapsed: 0.007 sec. 

clickhouse :) SELECT
    product_id,
    sum(multiplyDecimal(toDecimal64(quantity, 0), toDecimal64(price, 2))) as total
FROM sales
GROUP BY product_id;

Ok.

0 rows in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT
    product_id,
    sumMerge(total_quantity) AS total_quantity,
    countMerge(total_sales) AS total_sales
FROM sales_mv
GROUP BY product_id
ORDER BY product_id;

     ┌─product_id─┬─total_quantity─┬─total_sales─┐
  1. │          0 │        1004212 │        7805 │
  2. │          1 │        1014669 │        7897 │
  3. │          2 │         982624 │        7649 │
  4. │          3 │         986792 │        7719 │
    ...          ...              ...           ...
256. │        255 │         995012 │        7874 │
     └─product_id─┴─total_quantity─┴─total_sales─┘

256 rows in set. Elapsed: 0.004 sec. 

clickhouse :) 
```
Проекция пуста, т.к. таблица пуста, а матвью без изменений т.к. не реагирует на что-либо, отличное от INSERT.
