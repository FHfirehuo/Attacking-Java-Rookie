# innodb线程

后台线程的主要作用是负责刷新内存池中的数据，保证缓冲池中的内存缓存是最近的数据。此外，将已修改的数据文件刷新到磁盘文件中，同时保证出现异常时能够恢复到正常状态

InnoDB是多线程的模型，后台的线程主要有几大类

## Master Thread
Master Thread是一个核心的后台线程，
主要负责将缓冲池中的数据异步刷新到磁盘，
保证数据的一致性，包括脏页的刷新，合并插入缓冲，undo页的回收

## IO Thread
在InnoDb存储引擎中大量使用Async IO来处理IO的请求，
可以极大提高数据库的性能。
而IO Thread的主要工作是负责IO请求的回调处理（call back）。
较早之前版本有4个IO Thread 分别是write , read ,
 insert buffer,log IO Thread

## Purge Thread

事务被提交后，其所使用的undolog可能不再需要，
因此需要Purge Thread来及时回收已经分配的undo页。
innodb 1.1 之前 purge操作仅在master thread 中完成。
innodb 1.2开始 innodb支持设置多个purge thread，这样做的目的
是为了加快undo页的回收。

注意：设置了purge thread 并不代表 master thread 不再回收undo页。

```mysql
[mysqld]
innodb_purge_threads = 1
```


## Page Cleaner Thread
Page Cleaner Thread为高版本InnoDB引擎引入，
其作用是将之前版本的脏页刷新操作都放入单独的线程来完成。
其目的为了减轻Master Thread的工作及对于用户查询线程的阻塞，
从而进一步提高InnoDB存储引擎的性能

注意：Page Cleaner Thread之后master thread 不在进行脏读页的刷新操作


# innodb 内存结构

![c9-1](../image/c9-1.png)

