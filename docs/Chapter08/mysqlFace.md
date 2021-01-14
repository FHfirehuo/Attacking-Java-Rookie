# mysql 面试

1. 事务四大特性（ACID）原子性、一致性、隔离性、持久性？
1. 事务的并发？事务隔离级别，每个级别会引发什么问题，MySQL默认是哪个级别？
1. MySQL常见的三种存储引擎（InnoDB、MyISAM、MEMORY）的区别？
1. MySQL的MyISAM与InnoDB两种存储引擎在，事务、锁级别，各自的适用场景？
1. 查询语句不同元素（where、jion、limit、group by、having等等）执行先后顺序？
1. 什么是临时表，临时表什么时候删除?
1. MySQL B+Tree索引和Hash索引的区别？
1. sql查询语句确定创建哪种类型的索引？如何优化查询？
1. 聚集索引和非聚集索引区别？
1. 有哪些锁（乐观锁悲观锁），select 时怎么加排它锁？
1. 非关系型数据库和关系型数据库区别，优势比较？
1. 数据库三范式，根据某个场景设计数据表？
1. 数据库的读写分离、主从复制，主从复制分析的 7 个问题？
1. 使用explain优化sql和索引？
1. MySQL慢查询怎么解决？
1. 什么是 内连接、外连接、交叉连接、笛卡尔积等？
1. mysql都有什么锁，死锁判定原理和具体场景，死锁怎么解决？
1. varchar和char的使用场景？
1. mysql 高并发环境解决方案？
1. 数据库崩溃时事务的恢复机制（REDO日志和UNDO日志）？
1. mysql 的快照读和当前读

## 21条MySQL性能调优经验
1. 为查询缓存优化你的查询
1. EXPLAIN你的SELECT查询
1. 当只要一行数据时使用LIMIT 1
1. 为搜索字段建索引
1. 在Join表的时候使用相当类型的例，并将其索引
1. 千万不要 ORDER BY RAND()
1. 避免 SELECT *
1. 永远为每张表设置一个 ID
1. 使用 ENUM 而不是 VARCHAR
1. 从 PROCEDURE ANALYSE() 取得建议
1. 尽可能的使用 NOT NULL
1. Prepared Statements
1. 无缓冲的查询
1. 把 IP 地址存成 UNSIGNED INT
1. 固定长度的表会更快
1. 垂直分割
1. 拆分大的 DELETE 或 INSERT 语句
1. 越小的列会越快
1. 选择正确的存储引擎
1. 使用一个对象关系映射器(Object Relational Mapper)
1. 小心“永久链接”