# Словари
## Создайте таблицу с полями
```sql
clickhouse :) CREATE TABLE user_actions (
    user_id UInt64,
    action String,
    expense UInt64
)
ENGINE = MergeTree()
ORDER BY user_id;

Ok.

0 rows in set. Elapsed: 0.017 sec. 

clickhouse :)
```

## Создайте словарь
Файл для словаря: [users.tsv](../infrastructure/user_files/users.tsv)
```sql
clickhouse :) CREATE DICTIONARY users_dict
(
    user_id UInt64,
    email String
)
PRIMARY KEY user_id
SOURCE(FILE(path '/var/lib/clickhouse/user_files/users.tsv' format 'TabSeparated'))
LAYOUT(HASHED())
LIFETIME(MIN 1 MAX 10);

Ok.

0 rows in set. Elapsed: 0.014 sec. 

clickhouse :) 
```

## Наполните таблицу и источник данными
```sql
clickhouse :) INSERT INTO user_actions VALUES
(1, 'buy', 100),
(1, 'sell', 50),
(2, 'buy', 200),
(2, 'sell', 100),
(3, 'buy', 300),
(3, 'sell', 150),
(4, 'buy', 400),
(4, 'sell', 200),
(5, 'buy', 500),
(5, 'sell', 250),
(1, 'buy', 100),
(2, 'sell', 50),
(3, 'buy', 200),
(4, 'sell', 100),
(5, 'buy', 300),
(1, 'buy', 150),
(1, 'sell', 75),
(2, 'buy', 250),
(2, 'sell', 125),
(3, 'buy', 350),
(3, 'sell', 175),
(4, 'buy', 450),
(4, 'sell', 225),
(5, 'buy', 550),
(5, 'sell', 275),
(1, 'buy', 175),
(2, 'sell', 85),
(3, 'buy', 375),
(4, 'sell', 190),
(5, 'buy', 600),
(1, 'sell', 90),
(2, 'buy', 275),
(3, 'sell', 140),
(4, 'buy', 500),
(5, 'sell', 250);

Ok.

35 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```

## Напишите SELECT
Используем агрегрирующую функцию sum() с окном по email, action и строками от начала окна до текущей.
```sql
clickhouse :) SELECT
    user_id,
    dictGet('users_dict', 'email', user_id) AS email,
    action,
    expense,
    sum(expense) OVER (
        PARTITION BY email, action 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_expense
FROM user_actions
ORDER BY email, action;

    ┌─user_id─┬─email────────────┬─action─┬─expense─┬─cumulative_expense─┐
 1. │       3 │ anna@yandex.ru   │ buy    │     350 │                350 │
 2. │       3 │ anna@yandex.ru   │ buy    │     375 │                725 │
 3. │       3 │ anna@yandex.ru   │ buy    │     300 │               1025 │
 4. │       3 │ anna@yandex.ru   │ buy    │     200 │               1225 │
 5. │       3 │ anna@yandex.ru   │ sell   │     175 │                175 │
 6. │       3 │ anna@yandex.ru   │ sell   │     140 │                315 │
 7. │       3 │ anna@yandex.ru   │ sell   │     150 │                465 │
 8. │       4 │ eugene@yandex.ru │ buy    │     450 │                450 │
 9. │       4 │ eugene@yandex.ru │ buy    │     500 │                950 │
10. │       4 │ eugene@yandex.ru │ buy    │     400 │               1350 │
11. │       4 │ eugene@yandex.ru │ sell   │     225 │                225 │
12. │       4 │ eugene@yandex.ru │ sell   │     190 │                415 │
13. │       4 │ eugene@yandex.ru │ sell   │     200 │                615 │
14. │       4 │ eugene@yandex.ru │ sell   │     100 │                715 │
15. │       1 │ ivan@yandex.ru   │ buy    │     150 │                150 │
16. │       1 │ ivan@yandex.ru   │ buy    │     175 │                325 │
17. │       1 │ ivan@yandex.ru   │ buy    │     100 │                425 │
18. │       1 │ ivan@yandex.ru   │ buy    │     100 │                525 │
19. │       1 │ ivan@yandex.ru   │ sell   │      75 │                 75 │
20. │       1 │ ivan@yandex.ru   │ sell   │      90 │                165 │
21. │       1 │ ivan@yandex.ru   │ sell   │      50 │                215 │
22. │       5 │ kate@yandex.ru   │ buy    │     550 │                550 │
23. │       5 │ kate@yandex.ru   │ buy    │     600 │               1150 │
24. │       5 │ kate@yandex.ru   │ buy    │     500 │               1650 │
25. │       5 │ kate@yandex.ru   │ buy    │     300 │               1950 │
26. │       5 │ kate@yandex.ru   │ sell   │     275 │                275 │
27. │       5 │ kate@yandex.ru   │ sell   │     250 │                525 │
28. │       5 │ kate@yandex.ru   │ sell   │     250 │                775 │
29. │       2 │ petr@yandex.ru   │ buy    │     250 │                250 │
30. │       2 │ petr@yandex.ru   │ buy    │     275 │                525 │
31. │       2 │ petr@yandex.ru   │ buy    │     200 │                725 │
32. │       2 │ petr@yandex.ru   │ sell   │     125 │                125 │
33. │       2 │ petr@yandex.ru   │ sell   │      85 │                210 │
34. │       2 │ petr@yandex.ru   │ sell   │     100 │                310 │
35. │       2 │ petr@yandex.ru   │ sell   │      50 │                360 │
    └─────────┴──────────────────┴────────┴─────────┴────────────────────┘

35 rows in set. Elapsed: 0.003 sec. 

clickhouse :) 
```
