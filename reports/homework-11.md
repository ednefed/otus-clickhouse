# Мутации данных и манипуляции с партициями
## Создание и заполнение таблицы
```sql
clickhouse :) CREATE TABLE user_activity (
  user_id UInt32,
  activity_type String,
  activity_date DateTime
)
ENGINE = MergeTree
ORDER BY user_id
PARTITION BY toYYYYMMDD(activity_date);

Ok.

0 rows in set. Elapsed: 0.005 sec. 

clickhouse :) INSERT INTO user_activity VALUES
(1, 'login', '2023-01-01 10:00:00'),
(1, 'purchase', '2023-01-01 10:15:00'),
(2, 'login', '2023-01-02 12:00:00'),
(2, 'logout', '2023-01-02 13:00:00'),
(3, 'login', '2023-01-03 09:30:00'),
(3, 'purchase', '2023-01-03 10:00:00'),
(1, 'logout', '2023-01-04 11:00:00'),
(2, 'login', '2023-01-05 14:00:00'),
(3, 'logout', '2023-01-06 16:00:00'),
(1, 'purchase', '2023-01-07 17:00:00'),
(4, 'login', '2023-01-08 09:00:00'),    
(4, 'purchase', '2023-01-08 09:30:00'),
(5, 'login', '2023-01-09 11:00:00'),
(5, 'logout', '2023-01-09 12:00:00'),
(6, 'login', '2023-01-10 13:00:00'),
(6, 'purchase', '2023-01-10 13:30:00'),
(4, 'logout', '2023-01-11 14:00:00'),
(5, 'login', '2023-01-12 15:00:00'),
(6, 'logout', '2023-01-13 16:00:00'),
(4, 'purchase', '2023-01-14 17:00:00'),
(7, 'login', '2023-01-15 08:00:00'),
(7, 'purchase', '2023-01-15 08:30:00'),
(8, 'login', '2023-01-16 10:00:00'),
(8, 'logout', '2023-01-16 11:00:00'),
(9, 'login', '2023-01-17 12:00:00'),
(9, 'purchase', '2023-01-17 12:30:00'),
(7, 'logout', '2023-01-18 13:00:00'),
(8, 'login', '2023-01-19 14:00:00'),
(9, 'logout', '2023-01-20 15:00:00'),
(7, 'purchase', '2023-01-21 16:00:00');

Ok.

30 rows in set. Elapsed: 0.013 sec. 

clickhouse :) 
```

## Выполнение мутаций
У пользователя 1 было 4 операции: login, purchase, logout, purchase. Изменим purchase на refund
```sql
clickhouse :) ALTER TABLE user_activity
UPDATE activity_type='refund'
WHERE user_id=1
  AND activity_type='purchase';

Ok.

0 rows in set. Elapsed: 0.006 sec. 

clickhouse :) 
```

## Проверка результатов
```sql
SELECT * FROM user_activity WHERE user_id = 1;

   ┌─user_id─┬─activity_type─┬───────activity_date─┐
1. │       1 │ refund        │ 2023-01-07 17:00:00 │
2. │       1 │ logout        │ 2023-01-04 11:00:00 │
3. │       1 │ login         │ 2023-01-01 10:00:00 │
4. │       1 │ refund        │ 2023-01-01 10:15:00 │
   └─────────┴───────────────┴─────────────────────┘

4 rows in set. Elapsed: 0.004 sec. 

clickhouse :) SELECT
    mutation_id,
    command,
    create_time,
    parts_to_do_names,
    is_done
FROM system.mutations
WHERE table = 'user_activity';

   ┌─mutation_id─────┬─command────────────────────────────────────────────────────────────────────────────────┬─────────create_time─┬─parts_to_do_names─┬─is_done─┐
1. │ mutation_22.txt │ (UPDATE activity_type = 'refund' WHERE (user_id = 1) AND (activity_type = 'purchase')) │ 2025-06-30 18:40:19 │ []                │       1 │
   └─────────────────┴────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────┴───────────────────┴─────────┘

1 row in set. Elapsed: 0.006 sec. 

clickhouse :) 
```

## Манипуляции с партициями
Удалим партицию 20230101:
```sql
clickhouse :) ALTER TABLE user_activity DROP PARTITION '20230101';

Ok.

0 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

## Проверка состояния таблицы
```
clickhouse :) SELECT *
FROM user_activity
WHERE user_id = 1;

   ┌─user_id─┬─activity_type─┬───────activity_date─┐
1. │       1 │ refund        │ 2023-01-07 17:00:00 │
2. │       1 │ logout        │ 2023-01-04 11:00:00 │
   └─────────┴───────────────┴─────────────────────┘

2 rows in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT partition, active, rows, remove_time
FROM system.parts
WHERE `table` = 'user_activity';

    ┌─partition─┬─active─┬─rows─┬─────────remove_time─┐
 1. │ 20230101  │      0 │    0 │ 2025-06-30 19:01:23 │
 2. │ 20230102  │      1 │    2 │ 1970-01-01 00:00:00 │
 3. │ 20230103  │      1 │    2 │ 1970-01-01 00:00:00 │
 4. │ 20230104  │      1 │    1 │ 1970-01-01 00:00:00 │
 5. │ 20230105  │      1 │    1 │ 1970-01-01 00:00:00 │
 6. │ 20230106  │      1 │    1 │ 1970-01-01 00:00:00 │
 7. │ 20230107  │      1 │    1 │ 1970-01-01 00:00:00 │
 8. │ 20230108  │      1 │    2 │ 1970-01-01 00:00:00 │
 9. │ 20230109  │      1 │    2 │ 1970-01-01 00:00:00 │
10. │ 20230110  │      1 │    2 │ 1970-01-01 00:00:00 │
11. │ 20230111  │      1 │    1 │ 1970-01-01 00:00:00 │
12. │ 20230112  │      1 │    1 │ 1970-01-01 00:00:00 │
13. │ 20230113  │      1 │    1 │ 1970-01-01 00:00:00 │
14. │ 20230114  │      1 │    1 │ 1970-01-01 00:00:00 │
15. │ 20230115  │      1 │    2 │ 1970-01-01 00:00:00 │
16. │ 20230116  │      1 │    2 │ 1970-01-01 00:00:00 │
17. │ 20230117  │      1 │    2 │ 1970-01-01 00:00:00 │
18. │ 20230118  │      1 │    1 │ 1970-01-01 00:00:00 │
19. │ 20230119  │      1 │    1 │ 1970-01-01 00:00:00 │
20. │ 20230120  │      1 │    1 │ 1970-01-01 00:00:00 │
21. │ 20230121  │      1 │    1 │ 1970-01-01 00:00:00 │
    └───────────┴────────┴──────┴─────────────────────┘

21 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```

## Бонус
### Исследуйте, как работают другие типы мутаций
Удалим записи по пользователю 1:
```sql
clickhouse :) ALTER TABLE user_activity DELETE WHERE user_id = 1;

Ok.

0 rows in set. Elapsed: 0.005 sec. 

clickhouse :) SELECT *
FROM user_activity
WHERE user_id = 1;

Ok.

0 rows in set. Elapsed: 0.003 sec. 

clickhouse :) SELECT
    mutation_id,
    command,
    create_time,
    parts_to_do_names,
    is_done
FROM system.mutations
WHERE table = 'user_activity';

   ┌─mutation_id─────┬─command────────────────────────────────────────────────────────────────────────────────┬─────────create_time─┬─parts_to_do_names─┬─is_done─┐
1. │ mutation_22.txt │ (UPDATE activity_type = 'refund' WHERE (user_id = 1) AND (activity_type = 'purchase')) │ 2025-06-30 18:40:19 │ []                │       1 │
2. │ mutation_23.txt │ (DELETE WHERE user_id = 1)                                                             │ 2025-06-30 19:06:32 │ []                │       1 │
   └─────────────────┴────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────┴───────────────────┴─────────┘

2 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

### Попробуйте создать новую партицию
Я не совсем понимаю суть задания. Партиции создаются путём вставки данных со значением ключа партиционировани, которого ранее не было в таблице. Мы это проедлали в самом начале задания.

### Изучите возможность использования TTL
Т.к. таблица партиционирована по дням (toYYYYMMDD), то можно использовать интервал в днях. Добавим предварительно несколько записей для релевантности.
```sql
clickhouse :) INSERT INTO user_activity VALUES
(1, 'login', '2025-06-29 10:00:00'),
(1, 'purchase', '2025-06-30 10:15:00'),
(1, 'purchase', '2025-07-01 10:15:00'),
(2, 'login', '2025-06-29 12:00:00'),
(2, 'logout', '2025-06-30 13:00:00'),
(2, 'purchase', '2025-07-01 10:15:00');

Ok.

6 rows in set. Elapsed: 0.005 sec. 

clickhouse :) SELECT * FROM user_activity WHERE user_id in (1, 2);

   ┌─user_id─┬─activity_type─┬───────activity_date─┐
1. │       1 │ purchase      │ 2025-07-01 10:15:00 │
2. │       2 │ purchase      │ 2025-07-01 10:15:00 │
3. │       1 │ purchase      │ 2025-06-30 10:15:00 │
4. │       2 │ logout        │ 2025-06-30 13:00:00 │
5. │       1 │ login         │ 2025-06-29 10:00:00 │
6. │       2 │ login         │ 2025-06-29 12:00:00 │
7. │       2 │ login         │ 2023-01-05 14:00:00 │
8. │       2 │ login         │ 2023-01-02 12:00:00 │
9. │       2 │ logout        │ 2023-01-02 13:00:00 │
   └─────────┴───────────────┴─────────────────────┘

9 rows in set. Elapsed: 0.005 sec. 

clickhouse :) ALTER TABLE user_activity MODIFY TTL activity_date + INTERVAL 1 DAY;

Ok.

0 rows in set. Elapsed: 1.082 sec. 

clickhouse :) SELECT * FROM user_activity WHERE user_id in (1, 2);

   ┌─user_id─┬─activity_type─┬───────activity_date─┐
1. │       1 │ purchase      │ 2025-07-01 10:15:00 │
2. │       2 │ purchase      │ 2025-07-01 10:15:00 │
3. │       1 │ purchase      │ 2025-06-30 10:15:00 │
4. │       2 │ logout        │ 2025-06-30 13:00:00 │
   └─────────┴───────────────┴─────────────────────┘

4 rows in set. Elapsed: 0.004 sec. 

clickhouse :) SELECT partition, active, rows, remove_time
FROM system.parts
WHERE `table` = 'user_activity'
  AND active;

   ┌─partition─┬─active─┬─rows─┬─────────remove_time─┐
1. │ 20250630  │      1 │    2 │ 1970-01-01 00:00:00 │
2. │ 20250701  │      1 │    2 │ 1970-01-01 00:00:00 │
   └───────────┴────────┴──────┴─────────────────────┘

2 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```
Остались только записи и активные партиции с activity_date меньше чем текущий день + 1 (2025-06-30 22:25:00)
