# Обработка данных
## Вариант 1 -- UDF
Создадим таблицу и наполним случайными данными, используя generateRandom():
```sql
clickhouse :) CREATE TABLE transactions (
    transaction_id UInt32,
    user_id UInt32,
    product_id UInt32,
    quantity UInt8,
    price Decimal32(2),
    transaction_date Date
) ENGINE = MergeTree()
ORDER BY (transaction_id);

Ok.

0 rows in set. Elapsed: 0.016 sec. 

clickhouse :) INSERT INTO transactions
SELECT transaction_id, user_id, product_id, quantity, abs(price), transaction_date
FROM (
    SELECT * FROM generateRandom('
        transaction_id UInt32,
        user_id UInt32,
        product_id UInt32,
        quantity UInt8,
        price Decimal32(2),
        transaction_date Date
    ') LIMIT 1000000
);

Ok.

0 rows in set. Elapsed: 0.121 sec. Processed 1.26 million rows, 24.00 MB (10.44 million rows/s., 198.31 MB/s.)
Peak memory usage: 40.42 MiB.

clickhouse :) SELECT count(1) FROM transactions;

   ┌─count(1)─┐
1. │  1000000 │
   └──────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

### 1.1 Рассчитайте общий доход от всех операций
В процессе выполнения задания я наткнулся на NaN при суммировании умножения количества на цену, поэтому переделал поле price в предлагаемой таблице на Decimal32(2), чтобы агрегирующие функции не падали.
Также, для того чтобы не получить DECIMAL_OVERFLOW я использовал multiplyDecimal для получения дохода от одной операции.
```sql
clickhouse :) SELECT sum(multiplyDecimal(toDecimal64(quantity, 0), toDecimal64(price, 2))) as total FROM transactions;

   ┌──────────────total─┐
1. │ 599841412317886.12 │ -- 599.84 trillion
   └────────────────────┘

1 row in set. Elapsed: 0.207 sec. Processed 1.00 million rows, 5.00 MB (4.83 million rows/s., 24.15 MB/s.)
Peak memory usage: 76.13 KiB.

clickhouse :) 
```

### 1.2 Найдите средний доход с одной сделки
```sql
clickhouse :) SELECT avg(multiplyDecimal(toDecimal64(quantity, 0), toDecimal64(price, 2))) as average FROM transactions;

   ┌───────────average─┐
1. │ 599841412.3178861 │ -- 599.84 million
   └───────────────────┘

1 row in set. Elapsed: 0.188 sec. Processed 1.00 million rows, 5.00 MB (5.33 million rows/s., 26.64 MB/s.)
Peak memory usage: 76.20 KiB.

clickhouse :) 
```

### 1.3 Определите общее количество проданной продукции
```sql
clickhouse :) SELECT sum(quantity) FROM transactions;

   ┌─sum(quantity)─┐
1. │     127451948 │ -- 127.45 million
   └───────────────┘

1 row in set. Elapsed: 0.003 sec. Processed 1.00 million rows, 1.00 MB (344.43 million rows/s., 344.43 MB/s.)
Peak memory usage: 75.13 KiB.

clickhouse :) 
```

### 1.4 Подсчитайте количество уникальных пользователей, совершивших покупку
```sql
clickhouse :) SELECT count(DISTINCT user_id) FROM transactions;

   ┌─countDistinct(user_id)─┐
1. │                 999897 │
   └────────────────────────┘

1 row in set. Elapsed: 0.028 sec. Processed 1.00 million rows, 4.00 MB (35.59 million rows/s., 142.35 MB/s.)
Peak memory usage: 32.54 MiB.

clickhouse :) 
```

### 2.1 Преобразуйте 'transaction_date' в строку формата 'YYYY-MM-DD'
```sql
clickhouse :) SELECT transaction_date,
toString(transaction_date) as transaction_date_str
FROM transactions
LIMIT 5;

   ┌─transaction_date─┬─transaction_date_str─┐
1. │       2024-02-08 │ 2024-02-08           │
2. │       1977-09-07 │ 1977-09-07           │
3. │       1993-06-21 │ 1993-06-21           │
4. │       2140-11-12 │ 2140-11-12           │
5. │       2085-01-16 │ 2085-01-16           │
   └──────────────────┴──────────────────────┘

5 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

### 2.2 Извлеките год и месяц из 'transaction_date'
```sql
clickhouse :) SELECT transaction_date,
toYear(transaction_date) as year,
toMonth(transaction_date) as month
FROM transactions
LIMIT 5;

   ┌─transaction_date─┬─year─┬─month─┐
1. │       2024-02-08 │ 2024 │     2 │
2. │       1977-09-07 │ 1977 │     9 │
3. │       1993-06-21 │ 1993 │     6 │
4. │       2140-11-12 │ 2140 │    11 │
5. │       2085-01-16 │ 2085 │     1 │
   └──────────────────┴──────┴───────┘

5 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

### Округлите 'price' до ближайшего целого числа
```sql
clickhouse :) SELECT price,
round(price, 0)
FROM transactions
LIMIT 5;

   ┌──────price─┬─round(price, 0)─┐
1. │ 7175966.56 │         7175967 │
2. │ 3200669.17 │         3200669 │
3. │ 1526816.09 │         1526816 │
4. │ 5518182.47 │         5518182 │
5. │ 8323502.87 │         8323503 │
   └────────────┴─────────────────┘

5 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

### Преобразуйте 'transaction_id' в строку
```sql
clickhouse :) SELECT transaction_id,
toString(transaction_id) as transaction_id_str
FROM transactions
LIMIT 5;

   ┌─transaction_id─┬─transaction_id_str─┐
1. │           2527 │ 2527               │
2. │           6095 │ 6095               │
3. │           8777 │ 8777               │
4. │          12113 │ 12113              │
5. │          14390 │ 14390              │
   └────────────────┴────────────────────┘

5 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

### 3.1 Создайте простую UDF для расчета общей стоимости транзакции
```sql
clickhouse :) CREATE FUNCTION transactionTotal AS (a, b) -> multiplyDecimal(toDecimal64(a, 0), toDecimal64(b, 2));

Ok.

0 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

### 3.2 Используйте созданную UDF для расчета общей цены для каждой транзакции
```sql
clickhouse :) SELECT transaction_id,
quantity,
price,
multiplyDecimal(toDecimal64(quantity, 0), toDecimal64(price, 2)) AS common_total,
transactionTotal(quantity, price) as udf_total
FROM transactions
LIMIT 5;

   ┌─transaction_id─┬─quantity─┬──────price─┬─common_total─┬────udf_total─┐
1. │           2527 │       61 │ 7175966.56 │ 437733960.16 │ 437733960.16 │
2. │           6095 │      160 │ 3200669.17 │  512107067.2 │  512107067.2 │
3. │           8777 │       29 │ 1526816.09 │  44277666.61 │  44277666.61 │
4. │          12113 │      148 │ 5518182.47 │ 816691005.56 │ 816691005.56 │
5. │          14390 │       13 │ 8323502.87 │ 108205537.31 │ 108205537.31 │
   └────────────────┴──────────┴────────────┴──────────────┴──────────────┘

5 rows in set. Elapsed: 0.005 sec. 

clickhouse :) 
```

Значения, вычисленные напрямую и через UDF совпадают.

### 3.3 Создайте UDF для классификации транзакций на «высокоценные» и «малоценные» на основе порогового значения (например, 100)
Ранее в пункте 1.2 мы получили средний доход от транзакций равный 599.84 миллионам. Возьмём для порога значения в 600М, выше него -- транзакция классная (wow), ниже -- такая себе (meh).
```sql
clickhouse :) CREATE FUNCTION transactionCategory AS (a, b) -> if(transactionTotal(a, b) > 600000000, 'wow', 'meh');

Ok.

0 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

### 3.4 Примените UDF для категоризации каждой транзакции
```sql
clickhouse :) SELECT transactionTotal(quantity, price) as total,
transactionCategory(quantity, price) as category
FROM transactions
LIMIT 5;

   ┌────────total─┬─category─┐
1. │ 437733960.16 │ meh      │
2. │  512107067.2 │ meh      │
3. │  44277666.61 │ meh      │
4. │ 816691005.56 │ wow      │
5. │ 108205537.31 │ meh      │
   └──────────────┴──────────┘

5 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

## Вариант 2 -- EUDF
### 1 Настроить среду для использования EUDF
Местоположение конфигурационных файлов для EUDF я описал в [](../infrastructure/config.d/udf.xml).

### 2 EUDF для расчёта общей цены для каждой транзакции
В качестве движка я сипользовал простой bash-скрипт [](../infrastructure/user_scripts/transactionTotalEUDF.sh). Скрипт после запуска бесконечно принимает аргументы в STDIN и отдаёт результаты в STDOUT.
Этот скрипт размещается в контейнере с БД в каталоге /var/lib/clickhouse/user_scripts, см. [](../infrastructure/docker-compose.yml).
Путь к этому скрипту и описание самой EUDF находится в файле [](../infrastructure/eudf/transactions.xml).
Проверим EUDF и сравним результат с UDF из варианта 1:
```sql
clickhouse :) SELECT transactionTotal(quantity, price) as totalUDF, 
transactionTotalEUDF(quantity, price) as totalEUDF
FROM transactions
LIMIT 5;

   ┌─────totalUDF─┬────totalEUDF─┐
1. │ 437733960.16 │ 437733960.16 │
2. │  512107067.2 │  512107067.2 │
3. │  44277666.61 │  44277666.61 │
4. │ 816691005.56 │ 816691005.56 │
5. │ 108205537.31 │ 108205537.31 │
   └──────────────┴──────────────┘

5 rows in set. Elapsed: 0.006 sec. 

clickhouse :) 
```
Результа совпал.

### 3 EUDF для категоризации каждой транзакции
Аналогично, я использовал bash скрипт [](../infrastructure/user_scripts/transactionCategoryEUDF.sh).
Путь к этому скрипту и описание самой EUDF добавил в файл [](../infrastructure/eudf/transactions.xml).
Проверим EUDF и сравним результат с UDF из варианта 1:
```sql
clickhouse :) SELECT transactionTotal(quantity, price) as totalUDF,
transactionTotalEUDF(quantity, price) as totalEUDF,
transactionCategory(quantity, price) as categoryUDF,
transactionCategoryEUDF(quantity, price) as categoryEUDF
FROM transactions
LIMIT 5;

   ┌─────totalUDF─┬────totalEUDF─┬─categoryUDF─┬─categoryEUDF─┐
1. │ 437733960.16 │ 437733960.16 │ meh         │ meh          │
2. │  512107067.2 │  512107067.2 │ meh         │ meh          │
3. │  44277666.61 │  44277666.61 │ meh         │ meh          │
4. │ 816691005.56 │ 816691005.56 │ wow         │ wow          │
5. │ 108205537.31 │ 108205537.31 │ meh         │ meh          │
   └──────────────┴──────────────┴─────────────┴──────────────┘

5 rows in set. Elapsed: 0.010 sec. 

clickhouse :)  
```
Результат опять же успешно совпал.
