# Профилирование запросов
Используем уже загруженную в ДЗ №2 [homework-2.md](./homework-2.md) таблицу tpch.orders с ключом из o_orderkey:
```sql
clickhouse :) SET send_logs_level='trace';

[clickhouse] 2025.07.14 21:27:46.559614 [ 87 ] {2b85d91d-8c32-4904-b91e-9a6fc5e08248} <Debug> executeQuery: (from 127.0.0.1:36574) (query 1, line 1) SET send_logs_level='trace'; (stage: Complete)
Ok.

0 rows in set. Elapsed: 0.002 sec. 

clickhouse :) SELECT * FROM tpch.orders WHERE o_clerk = 'Clerk#000003119' LIMIT 5;

[clickhouse] 2025.07.14 21:27:31.800944 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> executeQuery: (from 127.0.0.1:36574) (query 1, line 1) SELECT * FROM tpch.orders WHERE o_clerk = 'Clerk#000003119' LIMIT 5; (stage: Complete)
[clickhouse] 2025.07.14 21:27:31.801644 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> Planner: Query to stage Complete
[clickhouse] 2025.07.14 21:27:31.801790 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> Planner: Query from stage FetchColumns to stage Complete
[clickhouse] 2025.07.14 21:27:31.802118 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> QueryPlanOptimizePrewhere: The min valid primary key position for moving to the tail of PREWHERE is -1
[clickhouse] 2025.07.14 21:27:31.802142 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> QueryPlanOptimizePrewhere: Moved 1 conditions to PREWHERE
[clickhouse] 2025.07.14 21:27:31.802214 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Key condition: unknown
[clickhouse] 2025.07.14 21:27:31.802247 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Filtering marks by primary and secondary keys
[clickhouse] 2025.07.14 21:27:31.802752 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): PK index has dropped 0/1832 granules, it took 0ms across 4 threads.
[clickhouse] 2025.07.14 21:27:31.802810 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> QueryConditionCache: Could not find entry for table_uuid: 764b80d3-3490-4068-ba4f-d12236bc1a12, part: all_1_1_0, condition_hash: 1990966411690609187
[clickhouse] 2025.07.14 21:27:31.802842 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> QueryConditionCache: Could not find entry for table_uuid: 764b80d3-3490-4068-ba4f-d12236bc1a12, part: all_2_2_0, condition_hash: 1990966411690609187
[clickhouse] 2025.07.14 21:27:31.802868 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> QueryConditionCache: Could not find entry for table_uuid: 764b80d3-3490-4068-ba4f-d12236bc1a12, part: all_3_3_0, condition_hash: 1990966411690609187
[clickhouse] 2025.07.14 21:27:31.802944 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> QueryConditionCache: Could not find entry for table_uuid: 764b80d3-3490-4068-ba4f-d12236bc1a12, part: all_4_4_0, condition_hash: 1990966411690609187
[clickhouse] 2025.07.14 21:27:31.802967 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Query condition cache has dropped 0/1832 granules for PREWHERE condition equals(__table1.o_clerk, 'Clerk#000003119'_String).
[clickhouse] 2025.07.14 21:27:31.802992 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> QueryConditionCache: Could not find entry for table_uuid: 764b80d3-3490-4068-ba4f-d12236bc1a12, part: all_1_1_0, condition_hash: 16959170025106318050
[clickhouse] 2025.07.14 21:27:31.803095 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> QueryConditionCache: Could not find entry for table_uuid: 764b80d3-3490-4068-ba4f-d12236bc1a12, part: all_2_2_0, condition_hash: 16959170025106318050
[clickhouse] 2025.07.14 21:27:31.803150 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> QueryConditionCache: Could not find entry for table_uuid: 764b80d3-3490-4068-ba4f-d12236bc1a12, part: all_3_3_0, condition_hash: 16959170025106318050
[clickhouse] 2025.07.14 21:27:31.803192 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> QueryConditionCache: Could not find entry for table_uuid: 764b80d3-3490-4068-ba4f-d12236bc1a12, part: all_4_4_0, condition_hash: 16959170025106318050
[clickhouse] 2025.07.14 21:27:31.803279 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Query condition cache has dropped 0/1832 granules for WHERE condition equals(o_clerk, 'Clerk#000003119'_String).
[clickhouse] 2025.07.14 21:27:31.803326 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Selected 4/4 parts by partition key, 4 parts by primary key, 1832/1832 marks by primary key, 1832 marks to read from 4 ranges
[clickhouse] 2025.07.14 21:27:31.803356 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Spreading mark ranges among streams (default reading)
[clickhouse] 2025.07.14 21:27:31.803492 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Reading approx. 15000000 rows with 8 streams
[clickhouse] 2025.07.14 21:27:31.803626 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> MergeTreeSelectProcessor: PREWHERE condition was split into 1 steps
[clickhouse] 2025.07.14 21:27:31.803670 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> MergeTreeSelectProcessor: PREWHERE condition was split into 1 steps
[clickhouse] 2025.07.14 21:27:31.803720 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> MergeTreeSelectProcessor: PREWHERE condition was split into 1 steps
[clickhouse] 2025.07.14 21:27:31.803779 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> MergeTreeSelectProcessor: PREWHERE condition was split into 1 steps
[clickhouse] 2025.07.14 21:27:31.803810 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> MergeTreeSelectProcessor: PREWHERE condition was split into 1 steps
[clickhouse] 2025.07.14 21:27:31.803890 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> MergeTreeSelectProcessor: PREWHERE condition was split into 1 steps
[clickhouse] 2025.07.14 21:27:31.803982 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> MergeTreeSelectProcessor: PREWHERE condition was split into 1 steps
[clickhouse] 2025.07.14 21:27:31.804016 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> MergeTreeSelectProcessor: PREWHERE condition was split into 1 steps
[clickhouse] 2025.07.14 21:27:31.809946 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> executeQuery: Read 131072 rows, 9.33 MiB in 0.009003 sec., 14558702.654670665 rows/sec., 1.01 GiB/sec.
[clickhouse] 2025.07.14 21:27:31.810608 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> MemoryTracker: Query peak memory usage: 18.60 MiB.
   ┌─o_orderkey─┬─o_custkey─┬─o_orderstatus─┬─o_totalprice─┬─o_orderdate─┬─o_orderpriority─┬─o_clerk─────────┬─o_shippriority─┬─o_comment───────────────────────────────────────────────────────────┐
1. │   52263618 │    943144 │ F             │     79709.86 │  1992-12-10 │ 3-MEDIUM        │ Clerk#000003119 │              0 │ nts kindle carefully idl                                            │
2. │   52276452 │    727418 │ F             │     38015.29 │  1994-06-15 │ 1-URGENT        │ Clerk#000003119 │              0 │ ts cajole about the express, ironic requests. quickly quiet account │
3. │   26184323 │   1405886 │ O             │    183820.61 │  1997-08-29 │ 2-HIGH          │ Clerk#000003119 │              0 │ ages. furiously express packages sleep                              │
4. │   26190243 │    447898 │ F             │    187861.54 │  1993-05-31 │ 3-MEDIUM        │ Clerk#000003119 │              0 │ quickly final instructions are fluffily. slyl                       │
5. │   26199329 │   1425511 │ O             │    241024.94 │  1997-03-01 │ 1-URGENT        │ Clerk#000003119 │              0 │ gular courts sublate slyly bold deposi                              │
   └────────────┴───────────┴───────────────┴──────────────┴─────────────┴─────────────────┴─────────────────┴────────────────┴─────────────────────────────────────────────────────────────────────┘

5 rows in set. Elapsed: 0.009 sec. Processed 131.07 thousand rows, 9.78 MB (14.35 million rows/s., 1.07 GB/s.)
Peak memory usage: 18.60 MiB.

clickhouse :) SELECT * FROM tpch.orders WHERE o_orderkey >= 30035363 AND o_orderkey <= 30035373 LIMIT 5;

[clickhouse] 2025.07.14 21:29:08.358431 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> executeQuery: (from 127.0.0.1:36574) (query 1, line 1) SELECT * FROM tpch.orders WHERE o_orderkey >= 30035363 AND o_orderkey <= 30035373 LIMIT 5; (stage: Complete)
[clickhouse] 2025.07.14 21:29:08.359011 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> Planner: Query to stage Complete
[clickhouse] 2025.07.14 21:29:08.359139 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> Planner: Query from stage FetchColumns to stage Complete
[clickhouse] 2025.07.14 21:29:08.359574 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> QueryPlanOptimizePrewhere: The min valid primary key position for moving to the tail of PREWHERE is 0
[clickhouse] 2025.07.14 21:29:08.359614 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> QueryPlanOptimizePrewhere: Moved 2 conditions to PREWHERE
[clickhouse] 2025.07.14 21:29:08.359785 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Key condition: (column 0 in [30035363, +Inf)), (column 0 in (-Inf, 30035373]), and
[clickhouse] 2025.07.14 21:29:08.359845 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Filtering marks by primary and secondary keys
[clickhouse] 2025.07.14 21:29:08.360822 [ 775 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Running binary search on index range for part all_3_3_0 (134 marks)
[clickhouse] 2025.07.14 21:29:08.360846 [ 775 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found (LEFT) boundary mark: 132
[clickhouse] 2025.07.14 21:29:08.360871 [ 775 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found (RIGHT) boundary mark: 133
[clickhouse] 2025.07.14 21:29:08.360935 [ 768 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Running binary search on index range for part all_4_4_0 (105 marks)
[clickhouse] 2025.07.14 21:29:08.360907 [ 775 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found empty range in 8 steps
[clickhouse] 2025.07.14 21:29:08.360968 [ 799 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Running binary search on index range for part all_1_1_0 (800 marks)
[clickhouse] 2025.07.14 21:29:08.360964 [ 768 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found (LEFT) boundary mark: 103
[clickhouse] 2025.07.14 21:29:08.360985 [ 799 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found (LEFT) boundary mark: 798
[clickhouse] 2025.07.14 21:29:08.360998 [ 799 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found (RIGHT) boundary mark: 799
[clickhouse] 2025.07.14 21:29:08.360996 [ 768 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found (RIGHT) boundary mark: 104
[clickhouse] 2025.07.14 21:29:08.361011 [ 799 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found empty range in 10 steps
[clickhouse] 2025.07.14 21:29:08.360996 [ 744 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Running binary search on index range for part all_2_2_0 (797 marks)
[clickhouse] 2025.07.14 21:29:08.361024 [ 768 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found empty range in 7 steps
[clickhouse] 2025.07.14 21:29:08.361035 [ 744 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found (LEFT) boundary mark: 117
[clickhouse] 2025.07.14 21:29:08.361073 [ 744 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found (RIGHT) boundary mark: 118
[clickhouse] 2025.07.14 21:29:08.361097 [ 744 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found continuous range in 18 steps
[clickhouse] 2025.07.14 21:29:08.361245 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): PK index has dropped 1831/1832 granules, it took 3ms across 4 threads.
[clickhouse] 2025.07.14 21:29:08.361314 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> QueryConditionCache: Could not find entry for table_uuid: 764b80d3-3490-4068-ba4f-d12236bc1a12, part: all_2_2_0, condition_hash: 9300599522709644587
[clickhouse] 2025.07.14 21:29:08.361358 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Query condition cache has dropped 0/1 granules for PREWHERE condition and(greaterOrEquals(__table1.o_orderkey, 30035363_UInt32), lessOrEquals(__table1.o_orderkey, 30035373_UInt32)).
[clickhouse] 2025.07.14 21:29:08.361406 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> QueryConditionCache: Could not find entry for table_uuid: 764b80d3-3490-4068-ba4f-d12236bc1a12, part: all_2_2_0, condition_hash: 12281977492908580679
[clickhouse] 2025.07.14 21:29:08.361447 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Query condition cache has dropped 0/1 granules for WHERE condition and(greaterOrEquals(o_orderkey, 30035363_UInt32), lessOrEquals(o_orderkey, 30035373_UInt32)).
[clickhouse] 2025.07.14 21:29:08.361497 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Selected 4/4 parts by partition key, 1 parts by primary key, 1/1832 marks by primary key, 1 marks to read from 1 ranges
[clickhouse] 2025.07.14 21:29:08.361600 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Spreading mark ranges among streams (default reading)
[clickhouse] 2025.07.14 21:29:08.361813 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Reading 1 ranges in order from part all_2_2_0, approx. 8192 rows starting from 958464
[clickhouse] 2025.07.14 21:29:08.361924 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> MergeTreeSelectProcessor: PREWHERE condition was split into 1 steps
[clickhouse] 2025.07.14 21:29:08.366502 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> executeQuery: Read 8192 rows, 1014.81 KiB in 0.008106 sec., 1010609.4251171971 rows/sec., 122.26 MiB/sec.
[clickhouse] 2025.07.14 21:29:08.366863 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> MemoryTracker: Query peak memory usage: 4.60 MiB.
   ┌─o_orderkey─┬─o_custkey─┬─o_orderstatus─┬─o_totalprice─┬─o_orderdate─┬─o_orderpriority─┬─o_clerk─────────┬─o_shippriority─┬─o_comment─────────────────────────────────────────────────────────────────────┐
1. │   30035363 │    692935 │ F             │     16454.17 │  1994-08-03 │ 4-NOT SPECIFIED │ Clerk#000008452 │              0 │ gly across the slyly unusual deposits.                                        │
2. │   30035364 │    133009 │ O             │     40632.19 │  1996-05-12 │ 4-NOT SPECIFIED │ Clerk#000003119 │              0 │ courts haggle. carefully dogged p                                             │
3. │   30035365 │    466702 │ O             │    254262.88 │  1995-06-22 │ 3-MEDIUM        │ Clerk#000007586 │              0 │ re. furiously special packages atop the slyly even inst                       │
4. │   30035366 │    344002 │ F             │     275564.1 │  1994-08-24 │ 1-URGENT        │ Clerk#000002747 │              0 │ he express dependencies. pending, regular requests across the unusual, expres │
5. │   30035367 │    611146 │ O             │     44757.28 │  1997-03-14 │ 3-MEDIUM        │ Clerk#000002850 │              0 │ sleep fluffily. careful packages cajole car                                   │
   └────────────┴───────────┴───────────────┴──────────────┴─────────────┴─────────────────┴─────────────────┴────────────────┴───────────────────────────────────────────────────────────────────────────────┘

5 rows in set. Elapsed: 0.008 sec. Processed 8.19 thousand rows, 1.04 MB (984.60 thousand rows/s., 124.90 MB/s.)
Peak memory usage: 4.60 MiB.

clickhouse :) 
```
В первом запросе использовалось поле, не вхядящее в индекс первичного ключа, поэтому пробег по индексу не отсеял лишних гранул:
```
[clickhouse] 2025.07.14 21:27:31.802214 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Key condition: unknown
[clickhouse] 2025.07.14 21:27:31.802247 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Filtering marks by primary and secondary keys
[clickhouse] 2025.07.14 21:27:31.802752 [ 87 ] {d13877ca-ba69-44f7-91fd-8d6411d356af} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): PK index has dropped 0/1832 granules, it took 0ms across 4 threads.
```
Во втором запросе, индексное поле использовалось, и были отсеяны все гранулы, кроме одной:
```
[clickhouse] 2025.07.14 21:29:08.359785 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Key condition: (column 0 in [30035363, +Inf)), (column 0 in (-Inf, 30035373]), and
[clickhouse] 2025.07.14 21:29:08.359845 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Filtering marks by primary and secondary keys
[clickhouse] 2025.07.14 21:29:08.360822 [ 775 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Running binary search on index range for part all_3_3_0 (134 marks)
...
[clickhouse] 2025.07.14 21:29:08.361097 [ 744 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Trace> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): Found continuous range in 18 steps
[clickhouse] 2025.07.14 21:29:08.361245 [ 87 ] {9409c401-87f2-44d7-8962-6fdf867a3e2d} <Debug> tpch.orders (764b80d3-3490-4068-ba4f-d12236bc1a12) (SelectExecutor): PK index has dropped 1831/1832 granules, it took 3ms across 4 threads.
```
Планы запросов это тоже подтверждают. В первом случае PrimaryKey Condition: true и полное канирование таблицы. Во втором же случае идёт отбор по условию всего лишь однйо гранулы:
```sql
clickhouse :) EXPLAIN indexes = 1 SELECT * FROM tpch.orders WHERE o_clerk = 'Clerk#000003119' LIMIT 5;

   ┌─explain──────────────────────────────────────┐
1. │ Expression ((Project names + Projection))    │
2. │   Limit (preliminary LIMIT (without OFFSET)) │
3. │     Expression                               │
4. │       ReadFromMergeTree (tpch.orders)        │
5. │       Indexes:                               │
6. │         PrimaryKey                           │
7. │           Condition: true                    │
8. │           Parts: 4/4                         │
9. │           Granules: 1832/1832                │
   └──────────────────────────────────────────────┘

9 rows in set. Elapsed: 0.002 sec. 

clickhouse :) EXPLAIN indexes = 1 SELECT * FROM tpch.orders WHERE o_orderkey >= 30035363 AND o_orderkey <= 30035373 LIMIT 5;

    ┌─explain──────────────────────────────────────────────────────────────────────────────────────┐
 1. │ Expression ((Project names + Projection))                                                    │
 2. │   Limit (preliminary LIMIT (without OFFSET))                                                 │
 3. │     Expression                                                                               │
 4. │       ReadFromMergeTree (tpch.orders)                                                        │
 5. │       Indexes:                                                                               │
 6. │         PrimaryKey                                                                           │
 7. │           Keys:                                                                              │
 8. │             o_orderkey                                                                       │
 9. │           Condition: and((o_orderkey in (-Inf, 30035373]), (o_orderkey in [30035363, +Inf))) │
10. │           Parts: 1/4                                                                         │
11. │           Granules: 1/1832                                                                   │
    └──────────────────────────────────────────────────────────────────────────────────────────────┘

11 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```
