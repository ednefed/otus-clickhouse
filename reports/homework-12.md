# Контроль доступа
Пользователь:
```sql
clickhouse :) CREATE USER jhon IDENTIFIED WITH plaintext_password BY 'qwerty';

Ok.

0 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```
Роль:
```sql
clickhouse :) CREATE ROLE devs;

Ok.

0 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```
Грант на роль:
```sql
clickhouse :) GRANT SELECT ON tpch.orders TO devs;

Ok.

0 rows in set. Elapsed: 0.002 sec. 

clickhouse :) 
```
Грант роли:
```sql
clickhouse :) GRANT devs to jhon;

GRANT devs TO jhon

0 rows in set. Elapsed: 0.001 sec. 

clickhouse :) 
```
Пруфы:
```sql
clickhouse :) SELECT name, id, storage, auth_type FROM system.users WHERE name = 'jhon';

   ┌─name─┬─id───────────────────────────────────┬─storage─────────┬─auth_type──────────────┐
1. │ jhon │ 334834fe-2209-5fe3-bd74-0f43c42456b3 │ local_directory │ ['plaintext_password'] │
   └──────┴──────────────────────────────────────┴─────────────────┴────────────────────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) SELECT * FROM system.roles WHERE name = 'devs';

   ┌─name─┬─id───────────────────────────────────┬─storage─────────┐
1. │ devs │ 6f4b1738-a2db-fa55-15f1-bf1e97eec4b9 │ local_directory │
   └──────┴──────────────────────────────────────┴─────────────────┘

1 row in set. Elapsed: 0.004 sec. 

clickhouse :) SELECT * FROM system.grants WHERE role_name = 'devs';

   ┌─user_name─┬─role_name─┬─access_type─┬─database─┬─table──┬─column─┬─is_partial_revoke─┬─grant_option─┐
1. │ ᴺᵁᴸᴸ      │ devs      │ SELECT      │ tpch     │ orders │ ᴺᵁᴸᴸ   │                 0 │            0 │
   └───────────┴───────────┴─────────────┴──────────┴────────┴────────┴───────────────────┴──────────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) SELECT * FROM system.role_grants WHERE granted_role_name = 'devs';

   ┌─user_name─┬─role_name─┬─granted_role_name─┬─granted_role_id──────────────────────┬─granted_role_is_default─┬─with_admin_option─┐
1. │ jhon      │ ᴺᵁᴸᴸ      │ devs              │ 6f4b1738-a2db-fa55-15f1-bf1e97eec4b9 │                       1 │                 0 │
   └───────────┴───────────┴───────────────────┴──────────────────────────────────────┴─────────────────────────┴───────────────────┘

1 row in set. Elapsed: 0.002 sec. 

clickhouse :) 
```
