# mysql命令集

1. 显示密码策略
    ```sql
    mysql> SHOW VARIABLES LIKE 'validate_password%'; 
    +--------------------------------------+--------+
    | Variable_name                        | Value  |
    +--------------------------------------+--------+
    | validate_password.check_user_name    | ON     |
    | validate_password.dictionary_file    |        |
    | validate_password.length             | 8      |
    | validate_password.mixed_case_count   | 1      |
    | validate_password.number_count       | 1      |
    | validate_password.policy             | MEDIUM |
    | validate_password.special_char_count | 1      |
    +--------------------------------------+--------+
    7 rows in set (0.13 sec)
    
    /*修改密码策略*/
    mysql> set global validate_password.policy = LOW;
    Query OK, 0 rows affected (0.01 sec)
    
    ```

2. 修改密码
    ````sql
    mysql> set password for 'fire'@'%'= 'fire1234';
    Query OK, 0 rows affected (0.03 sec)
    
    mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';
    ````

3. 新建用户
    ```sql
    mysql->create user 'test'@'localhost' identified by '123456';
    
    mysql->create user 'test'@'192.168.1.11' identified by '123456'; 
    
    mysql->create user 'test'@'%' identified by '123456';
    ```

4. 把某给表授权个某个用户
    ```sql
    /*授予用户通过外网IP对于该数据库的全部权限*/
    mysql> grant all privileges on `activiti`.* to 'fire'@'%' ;
    Query OK, 0 rows affected (0.02 sec)
    
     /*授予用户在本地服务器对该数据库的全部权限*/
    mysql>grant select on test.* to 'user1'@'localhost';  /*给予查询权限*/
    
    mysql>grant insert on test.* to 'user1'@'localhost'; /*添加插入权限*/
    
    mysql>grant delete on test.* to 'user1'@'localhost'; /*添加删除权限*/
    
    mysql>grant update on test.* to 'user1'@'localhost'; /*添加权限*/
    
    mysql> flush privileges; /*刷新权限*/
    ```

5. 查询innodb版本
    ```sql
    mysql> show variables like 'innodb_version';
    +----------------+--------+
    | Variable_name  | Value  |
    +----------------+--------+
    | innodb_version | 8.0.19 |
    +----------------+--------+
    1 row in set (0.09 sec)
    ```

6. mysql 配置文件位置
    ```shell
    [fire@localhost ~]$ mysql --help | grep my.cnf
                          order of preference, my.cnf, $MYSQL_TCP_PORT,
    /etc/my.cnf /etc/mysql/my.cnf /usr/etc/my.cnf ~/.my.cnf 
    ```
   
7. 查询innodb IO Thread 线程数
    ```sql
    mysql> show variables like 'innodb_%io_threads';
    +-------------------------+-------+
    | Variable_name           | Value |
    +-------------------------+-------+
    | innodb_read_io_threads  | 4     |
    | innodb_write_io_threads | 4     |
    +-------------------------+-------+
    2 rows in set (0.01 sec)
    ```

8. 查询innodb中的IO Thread
    ```sql
    mysql> show engine innodb status\G;
    *************************** 1. row ***************************
      Type: InnoDB
      Name: 
    Status: 
    =====================================
    2020-03-16 10:54:55 0x7fe1f415e700 INNODB MONITOR OUTPUT
    =====================================
    Per second averages calculated from the last 8 seconds
    -----------------
    BACKGROUND THREAD
    -----------------
    srv_master_thread loops: 1 srv_active, 0 srv_shutdown, 3887 srv_idle
    srv_master_thread log flush and writes: 0
    ----------
    SEMAPHORES
    ----------
    OS WAIT ARRAY INFO: reservation count 0
    OS WAIT ARRAY INFO: signal count 0
    RW-shared spins 0, rounds 0, OS waits 0
    RW-excl spins 0, rounds 0, OS waits 0
    RW-sx spins 0, rounds 0, OS waits 0
    Spin rounds per wait: 0.00 RW-shared, 0.00 RW-excl, 0.00 RW-sx
    ------------
    TRANSACTIONS
    ------------
    Trx id counter 3592
    Purge done for trx's n:o < 3590 undo n:o < 0 state: running but idle
    History list length 3
    LIST OF TRANSACTIONS FOR EACH SESSION:
    ---TRANSACTION 422083477633640, not started
    0 lock struct(s), heap size 1136, 0 row lock(s)
    ---TRANSACTION 422083477632768, not started
    0 lock struct(s), heap size 1136, 0 row lock(s)
    --------
    FILE I/O
    --------
    I/O thread 0 state: waiting for completed aio requests (insert buffer thread)
    I/O thread 1 state: waiting for completed aio requests (log thread)
    I/O thread 2 state: waiting for completed aio requests (read thread)
    I/O thread 3 state: waiting for completed aio requests (read thread)
    I/O thread 4 state: waiting for completed aio requests (read thread)
    I/O thread 5 state: waiting for completed aio requests (read thread)
    I/O thread 6 state: waiting for completed aio requests (write thread)
    I/O thread 7 state: waiting for completed aio requests (write thread)
    I/O thread 8 state: waiting for completed aio requests (write thread)
    I/O thread 9 state: waiting for completed aio requests (write thread)
    Pending normal aio reads: [0, 0, 0, 0] , aio writes: [0, 0, 0, 0] ,
     ibuf aio reads:, log i/o's:, sync i/o's:
    Pending flushes (fsync) log: 0; buffer pool: 0
    824 OS file reads, 204 OS file writes, 34 OS fsyncs
    0.00 reads/s, 0 avg bytes/read, 0.00 writes/s, 0.00 fsyncs/s
    -------------------------------------
    INSERT BUFFER AND ADAPTIVE HASH INDEX
    -------------------------------------
    Ibuf: size 1, free list len 0, seg size 2, 0 merges
    merged operations:
     insert 0, delete mark 0, delete 0
    discarded operations:
     insert 0, delete mark 0, delete 0
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 1 buffer(s)
    Hash table size 34679, node heap has 3 buffer(s)
    0.00 hash searches/s, 0.00 non-hash searches/s
    ---
    LOG
    ---
    Log sequence number          20099986
    Log buffer assigned up to    20099986
    Log buffer completed up to   20099986
    Log written up to            20099986
    Log flushed up to            20099986
    Added dirty pages up to      20099986
    Pages flushed up to          20099986
    Last checkpoint at           20099986
    17 log i/o's done, 0.00 log i/o's/second
    ----------------------
    BUFFER POOL AND MEMORY
    ----------------------
    Total large memory allocated 137363456
    Dictionary memory allocated 397868
    Buffer pool size   8192
    Free buffers       7245
    Database pages     943
    Old database pages 368
    Modified db pages  0
    Pending reads      0
    Pending writes: LRU 0, flush list 0, single page 0
    Pages made young 0, not young 0
    0.00 youngs/s, 0.00 non-youngs/s
    Pages read 801, created 142, written 154
    0.00 reads/s, 0.00 creates/s, 0.00 writes/s
    No buffer pool page gets since the last printout
    Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
    LRU len: 943, unzip_LRU len: 0
    I/O sum[0]:cur[0], unzip sum[0]:cur[0]
    --------------
    ROW OPERATIONS
    --------------
    0 queries inside InnoDB, 0 queries in queue
    0 read views open inside InnoDB
    Process ID=1348, Main thread ID=140608058603264 , state=sleeping
    Number of rows inserted 0, updated 0, deleted 0, read 0
    0.00 inserts/s, 0.00 updates/s, 0.00 deletes/s, 0.00 reads/s
    Number of system rows inserted 0, updated 315, deleted 0, read 4479
    0.00 inserts/s, 0.00 updates/s, 0.00 deletes/s, 0.00 reads/s
    ----------------------------
    END OF INNODB MONITOR OUTPUT
    ============================
    
    1 row in set (0.00 sec)
    
    ERROR: 
    No query specified
    ```
    可以看到IO Thread 0 为 insert buffer thread. IO thread 1 为 log thread。
    之后就是根据innodb_read_io_threads 及 innodb_write_io_threads 来设置的读写线程。
    并且读线程的ID总是小于写线程

9. 查询innodb缓存池大小
    ```sql
    mysql> show variables like 'innodb_buffer_pool_size';
    +-------------------------+-----------+
    | Variable_name           | Value     |
    +-------------------------+-----------+
    | innodb_buffer_pool_size | 134217728 |
    +-------------------------+-----------+
    1 row in set (0.09 sec)
    ```
   
10. 展示LRU算法的midpoint位置
    ```sql
    mysql> show variables like  'innodb_old_blocks_pct'\G;
    *************************** 1. row ***************************
    Variable_name: innodb_old_blocks_pct
            Value: 37
    1 row in set (0.13 sec)
    
    ERROR: 
    No query specified
    
    ```

11. 查看lRU列表及FREE列表的使用情况和运行状态
    ```sql
    mysql> show engine innodb status\G;
    *************************** 1. row ***************************
      Type: InnoDB
      Name: 
    Status: 
    =====================================
    2020-03-19 11:00:52 0x7f18440fe700 INNODB MONITOR OUTPUT
    =====================================
    Per second averages calculated from the last 23 seconds
    -----------------
    BACKGROUND THREAD
    -----------------
    srv_master_thread loops: 2 srv_active, 0 srv_shutdown, 190 srv_idle
    srv_master_thread log flush and writes: 0
    ----------
    SEMAPHORES
    ----------
    OS WAIT ARRAY INFO: reservation count 0
    OS WAIT ARRAY INFO: signal count 0
    RW-shared spins 0, rounds 0, OS waits 0
    RW-excl spins 0, rounds 0, OS waits 0
    RW-sx spins 0, rounds 0, OS waits 0
    Spin rounds per wait: 0.00 RW-shared, 0.00 RW-excl, 0.00 RW-sx
    ------------
    TRANSACTIONS
    ------------
    Trx id counter 4104
    Purge done for trx's n:o < 4102 undo n:o < 0 state: running but idle
    History list length 6
    LIST OF TRANSACTIONS FOR EACH SESSION:
    ---TRANSACTION 421217314507368, not started
    0 lock struct(s), heap size 1136, 0 row lock(s)
    ---TRANSACTION 421217314506496, not started
    0 lock struct(s), heap size 1136, 0 row lock(s)
    --------
    FILE I/O
    --------
    I/O thread 0 state: waiting for completed aio requests (insert buffer thread)
    I/O thread 1 state: waiting for completed aio requests (log thread)
    I/O thread 2 state: waiting for completed aio requests (read thread)
    I/O thread 3 state: waiting for completed aio requests (read thread)
    I/O thread 4 state: waiting for completed aio requests (read thread)
    I/O thread 5 state: waiting for completed aio requests (read thread)
    I/O thread 6 state: waiting for completed aio requests (write thread)
    I/O thread 7 state: waiting for completed aio requests (write thread)
    I/O thread 8 state: waiting for completed aio requests (write thread)
    I/O thread 9 state: waiting for completed aio requests (write thread)
    Pending normal aio reads: [0, 0, 0, 0] , aio writes: [0, 0, 0, 0] ,
     ibuf aio reads:, log i/o's:, sync i/o's:
    Pending flushes (fsync) log: 0; buffer pool: 0
    823 OS file reads, 212 OS file writes, 40 OS fsyncs
    0.00 reads/s, 0 avg bytes/read, 0.00 writes/s, 0.00 fsyncs/s
    -------------------------------------
    INSERT BUFFER AND ADAPTIVE HASH INDEX
    -------------------------------------
    Ibuf: size 1, free list len 0, seg size 2, 0 merges
    merged operations:
     insert 0, delete mark 0, delete 0
    discarded operations:
     insert 0, delete mark 0, delete 0
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 0 buffer(s)
    Hash table size 34679, node heap has 1 buffer(s)
    Hash table size 34679, node heap has 3 buffer(s)
    0.00 hash searches/s, 0.00 non-hash searches/s
    ---
    LOG
    ---
    Log sequence number          20128320
    Log buffer assigned up to    20128320
    Log buffer completed up to   20128320
    Log written up to            20128320
    Log flushed up to            20128320
    Added dirty pages up to      20128320
    Pages flushed up to          20128320
    Last checkpoint at           20128320
    18 log i/o's done, 0.00 log i/o's/second
    ----------------------
    BUFFER POOL AND MEMORY
    ----------------------
    Total large memory allocated 137363456
    Dictionary memory allocated 381493
    Buffer pool size   8192
    Free buffers       7257
    Database pages     931
    Old database pages 363
    Modified db pages  0
    Pending reads      0
    Pending writes: LRU 0, flush list 0, single page 0
    Pages made young 0, not young 0
    0.00 youngs/s, 0.00 non-youngs/s
    Pages read 789, created 142, written 157
    0.00 reads/s, 0.00 creates/s, 0.00 writes/s
    No buffer pool page gets since the last printout
    Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
    LRU len: 931, unzip_LRU len: 0
    I/O sum[0]:cur[0], unzip sum[0]:cur[0]
    --------------
    ROW OPERATIONS
    --------------
    0 queries inside InnoDB, 0 queries in queue
    0 read views open inside InnoDB
    Process ID=1432, Main thread ID=139741825779456 , state=sleeping
    Number of rows inserted 0, updated 0, deleted 0, read 0
    0.00 inserts/s, 0.00 updates/s, 0.00 deletes/s, 0.00 reads/s
    Number of system rows inserted 0, updated 315, deleted 0, read 4453
    0.00 inserts/s, 0.00 updates/s, 0.00 deletes/s, 0.00 reads/s
    ----------------------------
    END OF INNODB MONITOR OUTPUT
    ============================
    
    1 row in set (0.00 sec)
    
    ERROR: 
    No query specified
    ```

12. 慢sql阈值
    ```sql
    mysql> show variables like 'long_query_time'\G;
    *************************** 1. row ***************************
    Variable_name: long_query_time
            Value: 10.000000
    1 row in set (0.00 sec)
    
    ERROR: 
    No query specified
    
    ```
13. 记录慢sql设置
    ```sql
    mysql> show variables like 'log_slow_queries'\G;
    Empty set (0.00 sec)
    
    ERROR: 
    No query specified
    
    ```

14. 无索引sql
    ```sql
    mysql> show variables like 'log_queries_not_using_indexes'\G;
    *************************** 1. row ***************************
    Variable_name: log_queries_not_using_indexes
            Value: OFF
    1 row in set (0.00 sec)
    
    ERROR: 
    No query specified
    ```

15. 每分钟允许记录到slow log 的且未使用索引的sql语句次数
    ```sql
    mysql> show variables like 'log_throttle_queries_not_using_indexes'\G;
    *************************** 1. row ***************************
    Variable_name: log_throttle_queries_not_using_indexes
            Value: 0
    1 row in set (0.01 sec)
    
    ERROR: 
    No query specified

    ```
    /*默认是0表示没有限制*/
    
16. 分析慢sql日志
    ```shell
    [root@localhost etc]# mysqldumpslow nh122-190-slow.log
    
    Reading mysql slow query log from nh122-190-slow.log

    ```

17. 执行时间最长的10条sql语句
    ```shell
    [root@localhost log]# mysqldumpslow -s al -n 10 david.log
    
    Reading mysql slow query log from david.log

    ```

18. 查询表独立空间开启
    ```sql
    mysql> show variables like 'innodb_file_per_table'\G;
    *************************** 1. row ***************************
    Variable_name: innodb_file_per_table
            Value: ON
    1 row in set (0.01 sec)
    
    ERROR: 
    No query specified

    ```
    开启表独立空间。用户可以将每个基于innodb存储引擎的表产生一个独立表空间
    。独立表空间的命名规则为：表明.ibd。
19. 自动提交
    ```sql
    /*关闭自动提交*/
    mysql> set autocommit = 0;
    Query OK, 0 rows affected (0.00 sec)
    /*打开自动提交*/
    mysql> set autocommit = 1;
    Query OK, 0 rows affected (0.00 sec)

    ```

20. 
    ```sql
           
    ```