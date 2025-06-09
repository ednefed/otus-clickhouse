# Работа с SQL в ClickHouse
Создайте новую базу данных и перейдите в неё.
Разработайте таблицу для бизнес-кейса "Меню ресторана" с минимум пятью полями. Наполните таблицу данными, используя модификаторы (например, Nullable, LowCardinality), где это необходимо. Не забудьте добавить комментарии к полям.
Протестируйте выполнение операций CRUD на созданной таблице.
Добавьте несколько новых полей в таблицу и удалите два-три существующих.
Выполните выборку данных (select) из любой таблицы из sample dataset
Материализуйте выбранную таблицу, создав её копию в виде отдельной таблицы.
Попрактикуйтесь с партициями: выполните операции ATTACH, DETACH и DROP. После этого добавьте новые данные в первоначально созданную таблицу.

## Создайте новую базу данных, разработайте таблицу для бизнес-кейса "Меню ресторана", наполните таблицу данными
```sql
ednefed@nfd-vm-ubuntu:/opt/Works/otus/clickhouse$ docker compose -f infrastructure/docker-compose.yml -p otus exec -t clickhouse bash
root@clickhouse:/# clickhouse-client
ClickHouse client version 25.4.5.24 (official build).
Connecting to localhost:9000 as user default.
Connected to ClickHouse server version 25.4.5.

Warnings:
 * Delay accounting is not enabled, OSIOWaitMicroseconds will not be gathered. You can enable it using `echo 1 > /proc/sys/kernel/task_delayacct` or by using sysctl.

clickhouse :) CREATE DATABASE IF NOT EXISTS restaurant;

Ok.

0 rows in set. Elapsed: 0.014 sec. 

clickhouse :) CREATE TABLE restaurant.menu (
    id UInt32 COMMENT 'Уникальный идентификатор блюда',
    category LowCardinality(String) COMMENT 'Категория блюда (например, салаты, супы, горячее)',
    dish_name String COMMENT 'Название блюда',
    price Decimal(10, 2) COMMENT 'Цена блюда',
    is_vegetarian Boolean DEFAULT false COMMENT 'Флаг, обозначающий, является ли блюдо вегетарианским',
    has_allergens Array(String) DEFAULT [] COMMENT 'Список возможных аллергенов (молоко, орехи, глютен и др.)',
    description Nullable(String) COMMENT 'Описание блюда (может отсутствовать)'
) ENGINE = MergeTree()
ORDER BY id;

Ok.

0 rows in set. Elapsed: 0.005 sec. 

clickhouse :) INSERT INTO restaurant.menu VALUES
(1, 'Салаты', 'Салат Цезарь', 450.00, false, ['яйца'], NULL),
(2, 'Салаты', 'Оливье', 370.00, false, [], 'Классический салат с курицей'),
(3, 'Супы', 'Борщ', 300.00, true, [], 'Украинский борщ с говядиной'),
(4, 'Супы', 'Щи', 280.00, true, [], 'Русские щи со свежей капустой'),
(5, 'Горячие блюда', 'Стейк Рибай', 1200.00, false, [], 'Мраморная говядина средней прожарки'),
(6, 'Горячие блюда', 'Куриная грудка гриль', 650.00, false, [], 'Запечённая курица с травами'),
(7, 'Закуски', 'Карпаччо из лосося', 800.00, false, ['лосось'], 'Нежное карпаччо с лимонным соком'),
(8, 'Закуски', 'Закуска ассорти', 550.00, false, [], 'Ассорти мясных нарезок'),
(9, 'Десерты', 'Шоколадный торт', 350.00, false, ['шоколад', 'сахар'], 'Традиционный шоколадный десерт'),
(10, 'Десерты', 'Пирожное эклер', 200.00, false, ['молоко'], 'Эклеры с заварным кремом');

Ok.

10 rows in set. Elapsed: 0.004 sec. 

clickhouse :)
```

## Операции CRUD
### Create
Была продемонстрирована в конце предыдущего шага.

### Read

```sql
clickhouse :) SELECT * FROM restaurant.menu WHERE category = 'Закуски';

   ┌─id─┬─category─┬─dish_name──────────┬─price─┬─is_vegetarian─┬─has_allergens─┬─description──────────────────────┐
1. │  7 │ Закуски  │ Карпаччо из лосося │   800 │ false         │ ['лосось']    │ Нежное карпаччо с лимонным соком │
2. │  8 │ Закуски  │ Закуска ассорти    │   550 │ false         │ []            │ Ассорти мясных нарезок           │
   └────┴──────────┴────────────────────┴───────┴───────────────┴───────────────┴──────────────────────────────────┘

2 rows in set. Elapsed: 0.002 sec. 

clickhouse :)
```

### Update
Обновим цену на стейк рибай, увеличив её на 200 рублей:
```sql
clickhouse :) SELECT * FROM restaurant.menu WHERE dish_name = 'Стейк Рибай'

   ┌─id─┬─category──────┬─dish_name───┬─price─┬─is_vegetarian─┬─has_allergens─┬─description─────────────────────────┐
1. │  5 │ Горячие блюда │ Стейк Рибай │  1200 │ false         │ []            │ Мраморная говядина средней прожарки │
   └────┴───────────────┴─────────────┴───────┴───────────────┴───────────────┴─────────────────────────────────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) ALTER TABLE restaurant.menu UPDATE price = price + 200 WHERE dish_name = 'Стейк Рибай';

Ok.

0 rows in set. Elapsed: 0.004 sec. 

clickhouse :) SELECT * FROM restaurant.menu WHERE dish_name = 'Стейк Рибай'

   ┌─id─┬─category──────┬─dish_name───┬─price─┬─is_vegetarian─┬─has_allergens─┬─description─────────────────────────┐
1. │  5 │ Горячие блюда │ Стейк Рибай │  1400 │ false         │ []            │ Мраморная говядина средней прожарки │
   └────┴───────────────┴─────────────┴───────┴───────────────┴───────────────┴─────────────────────────────────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

### Delete
Удалим все десерты:
```sql
clickhouse :) SELECT count(1) FROM restaurant.menu WHERE category = 'Десерты';

   ┌─count(1)─┐
1. │        2 │
   └──────────┘

1 row in set. Elapsed: 0.004 sec. 

clickhouse :) DELETE FROM restaurant.menu WHERE category = 'Десерты';

Ok.

0 rows in set. Elapsed: 0.018 sec. 

clickhouse :) SELECT count(1) FROM restaurant.menu WHERE category = 'Десерты';

   ┌─count(1)─┐
1. │        0 │
   └──────────┘

1 row in set. Elapsed: 0.016 sec. 

clickhouse :) 
```

## Добавьте несколько новых полей в таблицу и удалите два-три существующих
Станем менее клиентоориентированными и удалим столбцы is_vegetarian и has_allergens:
```sql
clickhouse :) ALTER TABLE restaurant.menu DROP COLUMN is_vegetarian;

Ok.

0 rows in set. Elapsed: 0.016 sec. 

clickhouse :) ALTER TABLE restaurant.menu DROP COLUMN has_allergens;

Ok.

0 rows in set. Elapsed: 0.016 sec. 

clickhouse :) SELECT * FROM restaurant.menu;

   ┌─id─┬─category──────┬─dish_name────────────┬─price─┬─description─────────────────────────┐
1. │  1 │ Салаты        │ Салат Цезарь         │   450 │ ᴺᵁᴸᴸ                                │
2. │  2 │ Салаты        │ Оливье               │   370 │ Классический салат с курицей        │
3. │  3 │ Супы          │ Борщ                 │   300 │ Украинский борщ с говядиной         │
4. │  4 │ Супы          │ Щи                   │   280 │ Русские щи со свежей капустой       │
5. │  5 │ Горячие блюда │ Стейк Рибай          │  1400 │ Мраморная говядина средней прожарки │
6. │  6 │ Горячие блюда │ Куриная грудка гриль │   650 │ Запечённая курица с травами         │
7. │  7 │ Закуски       │ Карпаччо из лосося   │   800 │ Нежное карпаччо с лимонным соком    │
8. │  8 │ Закуски       │ Закуска ассорти      │   550 │ Ассорти мясных нарезок              │
   └────┴───────────────┴──────────────────────┴───────┴─────────────────────────────────────┘

8 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

Взамен добавим поля с флагом доступности блюда в меню и с указанием калорийности:
```sql
clickhouse :) ALTER TABLE restaurant.menu
ADD COLUMN availability BOOLEAN DEFAULT true,
ADD COLUMN calories Decimal(10,2) DEFAULT 0.0;

Ok.

0 rows in set. Elapsed: 0.004 sec. 

clickhouse :) SELECT * FROM restaurant.menu;

   ┌─id─┬─category──────┬─dish_name────────────┬─price─┬─description─────────────────────────┬─availability─┬─calories─┐
1. │  1 │ Салаты        │ Салат Цезарь         │   450 │ ᴺᵁᴸᴸ                                │ true         │        0 │
2. │  2 │ Салаты        │ Оливье               │   370 │ Классический салат с курицей        │ true         │        0 │
3. │  3 │ Супы          │ Борщ                 │   300 │ Украинский борщ с говядиной         │ true         │        0 │
4. │  4 │ Супы          │ Щи                   │   280 │ Русские щи со свежей капустой       │ true         │        0 │
5. │  5 │ Горячие блюда │ Стейк Рибай          │  1400 │ Мраморная говядина средней прожарки │ true         │        0 │
6. │  6 │ Горячие блюда │ Куриная грудка гриль │   650 │ Запечённая курица с травами         │ true         │        0 │
7. │  7 │ Закуски       │ Карпаччо из лосося   │   800 │ Нежное карпаччо с лимонным соком    │ true         │        0 │
8. │  8 │ Закуски       │ Закуска ассорти      │   550 │ Ассорти мясных нарезок              │ true         │        0 │
   └────┴───────────────┴──────────────────────┴───────┴─────────────────────────────────────┴──────────────┴──────────┘

8 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

## Выполните выборку данных из любой таблицы из sample dataset, материализуйте её в виде отдельной копии, попрактикуйтесь с партициями
### Таблица и матвью
Для экспериментов воспользуюсь таблицей lineitem из датасета TPC-H. Для начала создам её партиционированную до месяца по l_shipdate копию и матвью на исходную таблицу.
```sql
clickhouse :) SELECT count(1) FROM tpch.lineitem;

   ┌─count(1)─┐
1. │ 59986052 │ -- 59.99 million
   └──────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) CREATE TABLE tpch.lineitem_partitioned (
    l_orderkey       Int32,
    l_partkey        Int32,
    l_suppkey        Int32,
    l_linenumber     Int32,
    l_quantity       Decimal(15,2),
    l_extendedprice  Decimal(15,2),
    l_discount       Decimal(15,2),
    l_tax            Decimal(15,2),
    l_returnflag     String,
    l_linestatus     String,
    l_shipdate       Date,
    l_commitdate     Date,
    l_receiptdate    Date,
    l_shipinstruct   String,
    l_shipmode       String,
    l_comment        String)
PARTITION BY toYYYYMM(l_shipdate)
ORDER BY (l_orderkey, l_linenumber);

Ok.

0 rows in set. Elapsed: 0.006 sec. 

clickhouse :) CREATE MATERIALIZED VIEW tpch.lineitem_partitioned_mv
TO tpch.lineitem_partitioned
AS
SELECT * FROM tpch.lineitem;

Ok.

0 rows in set. Elapsed: 0.004 sec. 

clickhouse :) SELECT count(1) FROM tpch.lineitem_partitioned;

   ┌─count(1)─┐
1. │        0 │
   └──────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

В исходной таблице ~60М строк. После создания матвью в партиционированной 0 строк. Что ожидаемо, т.к. матвью создавалось без использования POPULATE, т.к. была явно указана итоговая таблица. Чтобы заполнить партиционированную таблицу, в данному случае нужно выполнить явную вставку запросом из матвью:
```sql
clickhouse :) INSERT INTO tpch.lineitem_partitioned SELECT * FROM tpch.lineitem;

Ok.

0 rows in set. Elapsed: 32.026 sec. Processed 59.99 million rows, 8.61 GB (1.87 million rows/s., 268.82 MB/s.)
Peak memory usage: 511.90 MiB.

clickhouse :) 
```

Интереса ради, параллельно будет выполнена вставка 10 новых строк в исходную таблицу, чтобы проверить автоматическую их обработку силами материализованного представления:
```sql
clickhouse :) INSERT INTO tpch.lineitem VALUES
(1001, 2001, 3001, 1, 10.00, 150.00, 0.05, 0.08, 'N', 'O', '2025-06-09', '2023-01-15', '2023-01-10', 'TAKE BACK RETURN', 'TRUCK', 'Comment for order #1001'),
(1002, 2002, 3002, 2, 20.00, 300.00, 0.03, 0.07, 'A', 'F', '2025-06-09', '2023-02-15', '2023-02-10', 'DELIVER IN PERSON', 'MAIL', 'Comment for order #1002'),
(1003, 2003, 3003, 3, 30.00, 450.00, 0.02, 0.06, 'R', 'P', '2025-06-09', '2023-03-15', '2023-03-10', 'NONE', 'REG AIR', 'Comment for order #1003'),
(1004, 2004, 3004, 4, 40.00, 600.00, 0.01, 0.05, 'C', 'I', '2025-06-09', '2023-04-15', '2023-04-10', 'COLLECT COD', 'SHIP', 'Comment for order #1004'),
(1005, 2005, 3005, 5, 50.00, 750.00, 0.04, 0.04, 'W', 'D', '2025-06-09', '2023-05-15', '2023-05-10', 'NONE', 'AIR', 'Comment for order #1005'),
(1006, 2006, 3006, 6, 60.00, 900.00, 0.06, 0.03, 'Y', 'S', '2025-06-09', '2023-06-15', '2023-06-10', 'NONE', 'RAIL', 'Comment for order #1006'),
(1007, 2007, 3007, 7, 70.00, 1050.00, 0.07, 0.02, 'X', 'Z', '2025-06-09', '2023-07-15', '2023-07-10', 'TAKE BACK RETURN', 'FOB', 'Comment for order #1007'),
(1008, 2008, 3008, 8, 80.00, 1200.00, 0.08, 0.01, 'Q', 'E', '2025-06-09', '2023-08-15', '2023-08-10', 'DELIVER IN PERSON', 'EXPRESS', 'Comment for order #1008'),
(1009, 2009, 3009, 9, 90.00, 1350.00, 0.09, 0.00, 'J', 'H', '2025-06-09', '2023-09-15', '2023-09-10', 'COLLECT COD', 'REG AIR', 'Comment for order #1009'),
(1010, 2010, 3010, 10, 100.00, 1500.00, 0.10, 0.09, 'K', 'G', '2025-06-09', '2023-10-15', '2023-10-10', 'NONE', 'MAIL', 'Comment for order #1010');

Ok.

10 rows in set. Elapsed: 0.005 sec. 

clickhouse :) 
```

Сверим количество в обоих таблицах, заодно проверим явно наличие новых данных.
```sql
clickhouse :) SELECT count(1) FROM tpch.lineitem;

   ┌─count(1)─┐
1. │ 59986062 │ -- 59.99 million
   └──────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) SELECT count(1) FROM tpch.lineitem_partitioned;

   ┌─count(1)─┐
1. │ 59986062 │ -- 59.99 million
   └──────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) SELECT l_orderkey,l_partkey,l_suppkey,l_shipdate FROM tpch.lineitem_partitioned WHERE l_shipdate = '2025-06-09';

    ┌─l_orderkey─┬─l_partkey─┬─l_suppkey─┬─l_shipdate─┐
 1. │       1001 │      2001 │      3001 │ 2025-06-09 │
 2. │       1002 │      2002 │      3002 │ 2025-06-09 │
 3. │       1003 │      2003 │      3003 │ 2025-06-09 │
 4. │       1004 │      2004 │      3004 │ 2025-06-09 │
 5. │       1005 │      2005 │      3005 │ 2025-06-09 │
 6. │       1006 │      2006 │      3006 │ 2025-06-09 │
 7. │       1007 │      2007 │      3007 │ 2025-06-09 │
 8. │       1008 │      2008 │      3008 │ 2025-06-09 │
 9. │       1009 │      2009 │      3009 │ 2025-06-09 │
10. │       1010 │      2010 │      3010 │ 2025-06-09 │
    └────────────┴───────────┴───────────┴────────────┘

10 rows in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT name, partition, rows FROM system.parts WHERE database = 'tpch' AND table = 'lineitem_partitioned' AND active ORDER BY rows ASC LIMIT 10;

    ┌─name───────────────┬─partition─┬─rows─┐
 1. │ 202506_1176_1176_0 │ 202506    │   10 │
 2. │ 199812_84_4788_11  │ 199812    │  219 │
 3. │ 199201_4871_4871_0 │ 199201    │  233 │
 4. │ 199811_4860_4860_0 │ 199811    │  236 │
 5. │ 199810_4844_4844_0 │ 199810    │  640 │
 6. │ 199202_4865_4865_0 │ 199202    │  643 │
 7. │ 199809_4846_4846_0 │ 199809    │ 1025 │
 8. │ 199203_4863_4863_0 │ 199203    │ 1157 │
 9. │ 199204_4866_4866_0 │ 199204    │ 1445 │
10. │ 199802_4823_4823_0 │ 199802    │ 1451 │
    └────────────────────┴───────────┴──────┘

10 rows in set. Elapsed: 0.003 sec. 

clickhouse :)
```

Количество сошлось, на 10 больше значения до начала экспериментов, новые строки также присутствуют в полном составе, партиция с новыми данными содержит наши новые 10 строк.

### Партиции
#### Выборки
Во-первых, в относительно свежих версиях БД, партиции стали ускорять выборки. Ранее, документация прямым текстом говорила, что это так не работает и партиции помогают лишь в управлении данными. Проверим, посмотрев планы одного и того же запроса к разыми вариантам таблицы:
```sql
clickhouse :) EXPLAIN indexes = 1 SELECT * FROM tpch.lineitem WHERE l_shipdate = '2025-06-09';

   ┌─explain───────────────────────────────────┐
1. │ Expression ((Project names + Projection)) │
2. │   Expression                              │
3. │     ReadFromMergeTree (tpch.lineitem)     │
4. │     Indexes:                              │
5. │       PrimaryKey                          │
6. │         Condition: true                   │
7. │         Parts: 9/9                        │
8. │         Granules: 7369/7369               │
   └───────────────────────────────────────────┘

8 rows in set. Elapsed: 0.003 sec. 

clickhouse :) EXPLAIN indexes = 1 SELECT * FROM tpch.lineitem_partitioned WHERE l_shipdate = '2025-06-09';

    ┌─explain───────────────────────────────────────────────────────┐
 1. │ Expression ((Project names + Projection))                     │
 2. │   Expression                                                  │
 3. │     ReadFromMergeTree (tpch.lineitem_partitioned)             │
 4. │     Indexes:                                                  │
 5. │       MinMax                                                  │
 6. │         Keys:                                                 │
 7. │           l_shipdate                                          │
 8. │         Condition: (l_shipdate in [20248, 20248])             │
 9. │         Parts: 1/417                                          │
10. │         Granules: 1/8150                                      │
11. │       Partition                                               │
12. │         Keys:                                                 │
13. │           toYYYYMM(l_shipdate)                                │
14. │         Condition: (toYYYYMM(l_shipdate) in [202506, 202506]) │
15. │         Parts: 1/1                                            │
16. │         Granules: 1/1                                         │
17. │       PrimaryKey                                              │
18. │         Condition: true                                       │
19. │         Parts: 1/1                                            │
20. │         Granules: 1/1                                         │
    └───────────────────────────────────────────────────────────────┘

20 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

В базовом случае получается full scan всех 7369 гранул, в партиционированном -- всего лишь одной, содержащей данные с нашим значением.

#### ATTACH / DETACH / DROP
Выполним отключение, проверку, включение, проверку, удаление, проверку:
```sql
clickhouse :) SELECT count(1) FROM tpch.lineitem_partitioned WHERE l_shipdate = '2025-06-09';

   ┌─count(1)─┐
1. │       10 │
   └──────────┘

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT name, partition, rows, active FROM system.parts WHERE database = 'tpch' AND table = 'lineitem_partitioned' AND partition = '202506';

   ┌─name───────────────┬─partition─┬─rows─┬─active─┐
1. │ 202506_1176_1176_1 │ 202506    │    0 │      0 │
2. │ 202506_4872_4872_1 │ 202506    │    0 │      0 │
3. │ 202506_4873_4873_1 │ 202506    │    0 │      0 │
4. │ 202506_4874_4874_1 │ 202506    │    0 │      0 │
5. │ 202506_4875_4875_1 │ 202506    │    0 │      0 │
6. │ 202506_4876_4876_0 │ 202506    │   10 │      1 │
   └────────────────────┴───────────┴──────┴────────┘

6 rows in set. Elapsed: 0.003 sec. 

clickhouse :) ALTER TABLE tpch.lineitem_partitioned DETACH PARTITION '202506';

Ok.

0 rows in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT count(1) FROM tpch.lineitem_partitioned WHERE l_shipdate = '2025-06-09';

   ┌─count(1)─┐
1. │        0 │
   └──────────┘

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT name, partition, rows, active FROM system.parts WHERE database = 'tpch' AND table = 'lineitem_partitioned' AND partition = '202506';

   ┌─name───────────────┬─partition─┬─rows─┬─active─┐
1. │ 202506_1176_1176_1 │ 202506    │    0 │      0 │
2. │ 202506_4872_4872_1 │ 202506    │    0 │      0 │
3. │ 202506_4873_4873_1 │ 202506    │    0 │      0 │
4. │ 202506_4874_4874_1 │ 202506    │    0 │      0 │
5. │ 202506_4875_4875_1 │ 202506    │    0 │      0 │
6. │ 202506_4876_4876_1 │ 202506    │    0 │      0 │
   └────────────────────┴───────────┴──────┴────────┘

6 rows in set. Elapsed: 0.003 sec. 

clickhouse :) ALTER TABLE tpch.lineitem_partitioned ATTACH PARTITION '202506';

Ok.

0 rows in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT count(1) FROM tpch.lineitem_partitioned WHERE l_shipdate = '2025-06-09';

   ┌─count(1)─┐
1. │       10 │
   └──────────┘

1 row in set. Elapsed: 0.006 sec. 

clickhouse :) SELECT name, partition, rows, active FROM system.parts WHERE database = 'tpch' AND table = 'lineitem_partitioned' AND partition = '202506';

   ┌─name───────────────┬─partition─┬─rows─┬─active─┐
1. │ 202506_4872_4872_1 │ 202506    │    0 │      0 │
2. │ 202506_4873_4873_1 │ 202506    │    0 │      0 │
3. │ 202506_4874_4874_1 │ 202506    │    0 │      0 │
4. │ 202506_4875_4875_1 │ 202506    │    0 │      0 │
5. │ 202506_4876_4876_1 │ 202506    │    0 │      0 │
6. │ 202506_4877_4877_0 │ 202506    │   10 │      1 │
   └────────────────────┴───────────┴──────┴────────┘

6 rows in set. Elapsed: 0.003 sec. 

clickhouse :) ALTER TABLE tpch.lineitem_partitioned DROP PARTITION '202506';

Ok.

0 rows in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT count(1) FROM tpch.lineitem_partitioned WHERE l_shipdate = '2025-06-09';

   ┌─count(1)─┐
1. │        0 │
   └──────────┘

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT name, partition, rows, active FROM system.parts WHERE database = 'tpch' AND table = 'lineitem_partitioned' AND partition = '202506';

   ┌─name───────────────┬─partition─┬─rows─┬─active─┐
1. │ 202506_4873_4873_1 │ 202506    │    0 │      0 │
2. │ 202506_4874_4874_1 │ 202506    │    0 │      0 │
3. │ 202506_4875_4875_1 │ 202506    │    0 │      0 │
4. │ 202506_4876_4876_1 │ 202506    │    0 │      0 │
5. │ 202506_4877_4877_1 │ 202506    │    0 │      0 │
   └────────────────────┴───────────┴──────┴────────┘

5 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

При выключенной и удалённой партиции, таблица сообщает, что запрошенных строк нет. Относящийся к партиции парт становится неактивным. Разница между DETACH и DROP в том, что в первом случае данные физически не удаляются с диска.
Повторная вставка тех же строк создаст партицию заново с новым партом:
```sql
clickhouse :) INSERT INTO tpch.lineitem VALUES
(1001, 2001, 3001, 1, 10.00, 150.00, 0.05, 0.08, 'N', 'O', '2025-06-09', '2023-01-15', '2023-01-10', 'TAKE BACK RETURN', 'TRUCK', 'Comment for order #1001'),
(1002, 2002, 3002, 2, 20.00, 300.00, 0.03, 0.07, 'A', 'F', '2025-06-09', '2023-02-15', '2023-02-10', 'DELIVER IN PERSON', 'MAIL', 'Comment for order #1002'),
(1003, 2003, 3003, 3, 30.00, 450.00, 0.02, 0.06, 'R', 'P', '2025-06-09', '2023-03-15', '2023-03-10', 'NONE', 'REG AIR', 'Comment for order #1003'),
(1004, 2004, 3004, 4, 40.00, 600.00, 0.01, 0.05, 'C', 'I', '2025-06-09', '2023-04-15', '2023-04-10', 'COLLECT COD', 'SHIP', 'Comment for order #1004'),
(1005, 2005, 3005, 5, 50.00, 750.00, 0.04, 0.04, 'W', 'D', '2025-06-09', '2023-05-15', '2023-05-10', 'NONE', 'AIR', 'Comment for order #1005'),
(1006, 2006, 3006, 6, 60.00, 900.00, 0.06, 0.03, 'Y', 'S', '2025-06-09', '2023-06-15', '2023-06-10', 'NONE', 'RAIL', 'Comment for order #1006'),
(1007, 2007, 3007, 7, 70.00, 1050.00, 0.07, 0.02, 'X', 'Z', '2025-06-09', '2023-07-15', '2023-07-10', 'TAKE BACK RETURN', 'FOB', 'Comment for order #1007'),
(1008, 2008, 3008, 8, 80.00, 1200.00, 0.08, 0.01, 'Q', 'E', '2025-06-09', '2023-08-15', '2023-08-10', 'DELIVER IN PERSON', 'EXPRESS', 'Comment for order #1008'),
(1009, 2009, 3009, 9, 90.00, 1350.00, 0.09, 0.00, 'J', 'H', '2025-06-09', '2023-09-15', '2023-09-10', 'COLLECT COD', 'REG AIR', 'Comment for order #1009'),
(1010, 2010, 3010, 10, 100.00, 1500.00, 0.10, 0.09, 'K', 'G', '2025-06-09', '2023-10-15', '2023-10-10', 'NONE', 'MAIL', 'Comment for order #1010');

Ok.

10 rows in set. Elapsed: 0.013 sec. 

clickhouse :) SELECT name, partition, rows, active FROM system.parts WHERE database = 'tpch' AND table = 'lineitem_partitioned' AND partition = '202506';

   ┌─name───────────────┬─partition─┬─rows─┬─active─┐
1. │ 202506_4878_4878_0 │ 202506    │   10 │      1 │
   └────────────────────┴───────────┴──────┴────────┘

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT count(1) FROM tpch.lineitem_partitioned WHERE l_shipdate = '2025-06-09';

   ┌─count(1)─┐
1. │       10 │
   └──────────┘

1 row in set. Elapsed: 0.003 sec. 

clickhouse :) 
```
