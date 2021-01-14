# mysql-\g和\G的作用

\g 的作用是分号和在sql语句中写’;’是等效的
\G 的作用是将查到的结构旋转90度变成纵向

\g的使用例子：查找一个表的创建语句

```sql
mysql> create table mytable(id int)\g
Query OK, 0 rows affected (0.21 sec)

mysql> show create table mytable \g
+---------+-------------------------------------------------------------------------------------------+
| Table   | Create Table                                                                              |
+---------+-------------------------------------------------------------------------------------------+
| mytable | CREATE TABLE `mytable` (
  `id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 |
+---------+-------------------------------------------------------------------------------------------+
1 row in set (0.04 sec)

```

上面的查找的表的创建语句看着很别扭，那么可以使用\G,试一下就知道它的用途了

```sql
mysql> show create table mytable \G
*************************** 1. row ***************************
       Table: mytable
Create Table: CREATE TABLE `mytable` (
  `id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8
1 row in set (0.00 sec)
```

这个时候用着\G感觉使结果很清晰

```sql
mysql> show variables like 'innodb_version';
+----------------+--------+
| Variable_name  | Value  |
+----------------+--------+
| innodb_version | 8.0.19 |
+----------------+--------+
1 row in set (0.09 sec)

mysql> show variables like 'innodb_version'\g;
+----------------+--------+
| Variable_name  | Value  |
+----------------+--------+
| innodb_version | 8.0.19 |
+----------------+--------+
1 row in set (0.00 sec)

ERROR: 
No query specified

mysql> show variables like 'innodb_version'\G;
*************************** 1. row ***************************
Variable_name: innodb_version
        Value: 8.0.19
1 row in set (0.00 sec)

ERROR: 
No query specified

```