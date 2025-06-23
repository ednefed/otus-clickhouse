# Джоины и агрегации

## 1 Создать БД и таблицы
```sql
clickhouse :) CREATE DATABASE imdb;

Ok.

0 rows in set. Elapsed: 0.004 sec. 

clickhouse :) CREATE TABLE imdb.actors
(
    id         UInt32,
    first_name String,
    last_name  String,
    gender     FixedString(1)
) ENGINE = MergeTree ORDER BY (id, first_name, last_name, gender);

Ok.

0 rows in set. Elapsed: 0.006 sec. 

clickhouse :) CREATE TABLE imdb.genres
(
    movie_id UInt32,
    genre    String
) ENGINE = MergeTree ORDER BY (movie_id, genre);

Ok.

0 rows in set. Elapsed: 0.016 sec. 

clickhouse :) CREATE TABLE imdb.movies
(
    id   UInt32,
    name String,
    year UInt32,
    rank Float32 DEFAULT 0
) ENGINE = MergeTree ORDER BY (id, name, year);

Ok.

0 rows in set. Elapsed: 0.018 sec. 

clickhouse :) CREATE TABLE imdb.roles
(
    actor_id   UInt32,
    movie_id   UInt32,
    role       String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree ORDER BY (actor_id, movie_id);

Ok.

0 rows in set. Elapsed: 0.014 sec. 

clickhouse :) 
```

## 2 Вставить тестовые данные, используя функцию S3
```sql
clickhouse :) INSERT INTO imdb.actors
SELECT *
FROM s3('https://datasets-documentation.s3.eu-west-3.amazonaws.com/imdb/imdb_ijs_actors.tsv.gz',
'TSVWithNames');

Ok.

0 rows in set. Elapsed: 5.480 sec. Processed 817.72 thousand rows, 26.16 MB (149.23 thousand rows/s., 4.77 MB/s.)
Peak memory usage: 44.68 MiB.

clickhouse :) INSERT INTO imdb.genres
SELECT *
FROM s3('https://datasets-documentation.s3.eu-west-3.amazonaws.com/imdb/imdb_ijs_movies_genres.tsv.gz',
'TSVWithNames');

Ok.

0 rows in set. Elapsed: 0.780 sec. Processed 395.12 thousand rows, 6.62 MB (506.52 thousand rows/s., 8.49 MB/s.)
Peak memory usage: 15.03 MiB.

clickhouse :) INSERT INTO imdb.movies
SELECT *
FROM s3('https://datasets-documentation.s3.eu-west-3.amazonaws.com/imdb/imdb_ijs_movies.tsv.gz',
'TSVWithNames');

Ok.

0 rows in set. Elapsed: 1.279 sec. Processed 388.27 thousand rows, 11.74 MB (303.62 thousand rows/s., 9.18 MB/s.)
Peak memory usage: 32.69 MiB.

clickhouse :) INSERT INTO imdb.roles(actor_id, movie_id, role)
SELECT actor_id, movie_id, role
FROM s3('https://datasets-documentation.s3.eu-west-3.amazonaws.com/imdb/imdb_ijs_roles.tsv.gz',
'TSVWithNames');

Ok.

0 rows in set. Elapsed: 5.253 sec. Processed 3.43 million rows, 85.09 MB (653.28 thousand rows/s., 16.20 MB/s.)
Peak memory usage: 99.43 MiB.

clickhouse :) 
```

## 3 Используя изученные материалы, построить запросы
### a Найти жанры для каждого фильма
Нам нужен LEFT JOIN, т.к. жанр может быть не указан. И т.к. жанров может быть несколько, то можно воспользоваться агрегирующей функцией groupConcat, чтобы "склеить" все жанры в строку через запятую.
```sql
clickhouse :) SELECT m.id, m.name, m.`year`, groupConcat(g.genre, ', ') as genre
FROM imdb.movies m
LEFT JOIN imdb.genres g
ON m.id = g.movie_id
GROUP BY m.id, m.name, m.`year`
ORDER BY m.id
LIMIT 10

    ┌─id─┬─name────────────────────────────────┬─year─┬─genre────────────────────┐
 1. │  0 │ #28                                 │ 2002 │                          │
 2. │  1 │ #7 Train: An Immigrant Journey, The │ 2000 │ Documentary, Short       │
 3. │  2 │ $                                   │ 1971 │ Comedy, Crime            │
 4. │  3 │ $1,000 Reward                       │ 1913 │                          │
 5. │  4 │ $1,000 Reward                       │ 1915 │                          │
 6. │  5 │ $1,000 Reward                       │ 1923 │ Western                  │
 7. │  6 │ $1,000,000 Duck                     │ 1971 │ Comedy, Family           │
 8. │  7 │ $1,000,000 Reward, The              │ 1920 │                          │
 9. │  8 │ $10,000 Under a Pillow              │ 1921 │ Animation, Comedy, Short │
10. │  9 │ $100,000                            │ 1915 │ Drama                    │
    └────┴─────────────────────────────────────┴──────┴──────────────────────────┘

10 rows in set. Elapsed: 0.179 sec. Processed 783.39 thousand rows, 21.50 MB (4.37 million rows/s., 120.04 MB/s.)
Peak memory usage: 146.14 MiB.

clickhouse :) 
```

### b Запросить все фильмы, у которых нет жанра
По большому счёту нам нужен результат, обратный предыдущему запросу. Для этого есть LEFT ANTI JOIN.
```sql
clickhouse :) SELECT m.id, m.name, m.`year`, g.genre
FROM imdb.movies m
LEFT ANTI JOIN imdb.genres g
ON m.id = g.movie_id
ORDER BY m.id
LIMIT 10;

    ┌─id─┬─name─────────────────────────────┬─year─┬─genre─┐
 1. │  0 │ #28                              │ 2002 │       │
 2. │  3 │ $1,000 Reward                    │ 1913 │       │
 3. │  4 │ $1,000 Reward                    │ 1915 │       │
 4. │  7 │ $1,000,000 Reward, The           │ 1920 │       │
 5. │ 16 │ $30,000                          │ 1920 │       │
 6. │ 23 │ $50,000 Challenge, The           │ 1989 │       │
 7. │ 39 │ '42                              │ 1951 │       │
 8. │ 48 │ '93 jie tou ba wang              │ 1993 │       │
 9. │ 49 │ '94 du bi dao zhi qing           │ 1994 │       │
10. │ 54 │ 'Abbot' and 'Cresceus' Race, The │ 1901 │       │
    └────┴──────────────────────────────────┴──────┴───────┘

10 rows in set. Elapsed: 0.022 sec. Processed 783.39 thousand rows, 21.50 MB (35.68 million rows/s., 979.27 MB/s.)
Peak memory usage: 28.52 MiB.

clickhouse :) 
```

### c Объединить каждую строку из таблицы “Фильмы” с каждой строкой из таблицы “Жанры”
Каждую с каждой это декартово произведение, т.е. CROSS JOIN. На используемом датасете это будет 153 413 242 400 строк (395.12k жанров * 388.27k фильмов).
```sql
clickhouse :) SELECT m.id, m.name, m.`year`, g.genre
FROM imdb.movies m
CROSS JOIN imdb.genres g
LIMIT 10;

    ┌─────id─┬─name───────┬─year─┬─genre───────┐
 1. │ 141055 │ Headmaster │ 1958 │ Documentary │
 2. │ 141055 │ Headmaster │ 1958 │ Short       │
 3. │ 141055 │ Headmaster │ 1958 │ Comedy      │
 4. │ 141055 │ Headmaster │ 1958 │ Crime       │
 5. │ 141055 │ Headmaster │ 1958 │ Western     │
 6. │ 141055 │ Headmaster │ 1958 │ Comedy      │
 7. │ 141055 │ Headmaster │ 1958 │ Family      │
 8. │ 141055 │ Headmaster │ 1958 │ Animation   │
 9. │ 141055 │ Headmaster │ 1958 │ Comedy      │
10. │ 141055 │ Headmaster │ 1958 │ Short       │
    └────────┴────────────┴──────┴─────────────┘

10 rows in set. Elapsed: 0.029 sec. Processed 640.88 thousand rows, 14.77 MB (22.19 million rows/s., 511.44 MB/s.)
Peak memory usage: 24.12 MiB.

clickhouse :) SELECT count(1)
FROM 
(SELECT m.id, m.name, m.`year`, g.genre
    FROM imdb.movies m
    CROSS JOIN imdb.genres g)

   ┌─────count(1)─┐
1. │ 153412459011 │ -- 153.41 billion
   └──────────────┘

1 row in set. Elapsed: 48.434 sec. Processed 783.39 thousand rows, 3.13 MB (16.17 thousand rows/s., 64.70 KB/s.)
Peak memory usage: 20.24 MiB.

clickhouse :) 
```

### d Найти жанры для каждого фильма, НЕ используя INNER JOIN
Первый запрос, только с LEFT OUTER JOIN, который вернёт несовпавшие строки из левой таблицы.
```sql
clickhouse :) SELECT m.id, m.name, m.`year`, groupConcat(g.genre, ', ') as genre
FROM imdb.movies m
LEFT OUTER JOIN imdb.genres g
ON m.id = g.movie_id
GROUP BY m.id, m.name, m.`year`
ORDER BY m.id
LIMIT 10;

    ┌─id─┬─name────────────────────────────────┬─year─┬─genre────────────────────┐
 1. │  0 │ #28                                 │ 2002 │                          │
 2. │  1 │ #7 Train: An Immigrant Journey, The │ 2000 │ Documentary, Short       │
 3. │  2 │ $                                   │ 1971 │ Comedy, Crime            │
 4. │  3 │ $1,000 Reward                       │ 1913 │                          │
 5. │  4 │ $1,000 Reward                       │ 1915 │                          │
 6. │  5 │ $1,000 Reward                       │ 1923 │ Western                  │
 7. │  6 │ $1,000,000 Duck                     │ 1971 │ Comedy, Family           │
 8. │  7 │ $1,000,000 Reward, The              │ 1920 │                          │
 9. │  8 │ $10,000 Under a Pillow              │ 1921 │ Animation, Comedy, Short │
10. │  9 │ $100,000                            │ 1915 │ Drama                    │
    └────┴─────────────────────────────────────┴──────┴──────────────────────────┘

10 rows in set. Elapsed: 0.174 sec. Processed 783.39 thousand rows, 21.50 MB (4.51 million rows/s., 123.80 MB/s.)
Peak memory usage: 162.44 MiB.

clickhouse :) 
```

### e Найти всех актеров и актрис, снявшихся в фильме в N году
Год съёмки актёра можем получить только из фильма через роль. Т.к. актёр мог снятся в одном году в нескольких фильмах, то добавим DISTINCT для получения списка уникальных имён.
```sql
clickhouse :) SELECT DISTINCT a.first_name, a.last_name
FROM imdb.actors a
LEFT JOIN imdb.roles r ON a.id = r.actor_id
LEFT JOIN imdb.movies m ON r.movie_id = m.id
WHERE m.`year` = 2000
ORDER BY a.first_name, a.last_name
LIMIT 10;

    ┌─first_name────────┬─last_name─┐
 1. │ !Nqate            │ Xqamxebe  │
 2. │ 'Browski' James   │ Reese     │
 3. │ 'Cousin Brucie'   │ Morrow    │
 4. │ 'Dutch' Amoa      │ Chester   │
 5. │ 'Gangsta' Terrell │ Anderson  │
 6. │ 'Jill Jack'       │ Golmany   │
 7. │ 'Karaoke Karl'    │ Detken    │
 8. │ 'Kmac' Kelly      │ Garmon    │
 9. │ 'Smokey Tom'      │ Hodgins   │
10. │ 'Stuttering' John │ Melendez  │
    └───────────────────┴───────────┘

10 rows in set. Elapsed: 0.218 sec. Processed 4.64 million rows, 59.34 MB (21.26 million rows/s., 272.00 MB/s.)
Peak memory usage: 215.92 MiB.

clickhouse :) 
```

### f Запросить все фильмы, у которых нет жанра, через ANTI JOIN
Я случайно сделал это в пункте b выше. =(
