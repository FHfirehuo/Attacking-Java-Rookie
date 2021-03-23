# MySQL一次insert刷几次盘

工具：pt-tools

1. 先检查各个刷盘参数

2. 开启 pt-tools

3. 在 MySQL 中，任意表插入一行

4. 观察 pt-ioprofile 的结果


我们用 pt-ioprofile 跟踪 MySQL IO 的系统调用，统计了次数。

可以看到本次实验中：

1. MySQL 对 redo log 进行了 3 次刷盘(fsync)；

2. MySQL 对 binlog 进行了 1 次刷盘(fdatasync)；

3. 对 redo log 和 binlog 的刷盘的方法是不同的。

结果：
可以看到本次试验进行了一次 insert，会对 redo log 进行 3 次刷盘，对 binlog 进行 1 次刷盘。

但是需要注意以下事项：

1. 进行相同试验，会观察到不同结果：MySQL 有多个逻辑会引发刷盘，比如 InnoDB 主线程的刷脏等；

2. 每次 fsync，如果没有数据需要刷盘，不会对磁盘造成压力。对于 3 次刷盘不必过分担心；

3. 以后我们会进行试验，分析到底是什么导致了刷盘。


pt-ioprofile 是 pt-tools 中的一款性能分析工具，可以监听 MySQL 进程，输出 IO 操作的次数/总时间/平均时间。

其原理如下：pt-ioprofile 用 strace 监听 MySQL 的系统调用，筛选其中与 IO 相关的系统调用，进行统计。同时 pt-ioprofile 也获取 lsof 的输出，将其与 strace 的结果匹配，得知系统调用操作了哪个 MySQL 文件。