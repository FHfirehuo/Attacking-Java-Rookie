# mysql时区

###### 查看时区

```sql
mysql> show variables like '%time_zone%';
+------------------+--------+
| Variable_name | Value |
+------------------+--------+
| system_time_zone | EDT |
| time_zone  | SYSTEM |
+------------------+--------+
2 rows in set (0.00 sec)
```

    system_time_zone 表示系统使用的时区是 EDT即北美的东部夏令时(-4h)
    time_zone 表示 MySQL 采用的是系统的时区。也就是说，如果在连接时没有设置时区信息，就会采用这个时区配置。

###### 修改时区

```sql
# 仅修改当前会话的时区，停止会话失效
set time_zone = '+8:00';
 
# 修改全局的时区配置
set global time_zone = '+8:00';
flush privileges;
```

&emsp;当然，也可以通过修改配置文件(my.cnf)的方式来实现配置，不过需要重启服务。

```shell
# vim /etc/my.cnf ##在[mysqld]区域中加上
default-time_zone = '+8:00'
# /etc/init.d/mysqld restart ##重启mysql使新时区生效
```

#### 对于线上数据库不能操作怎么办?

```yaml
  datasource:
    url: jdbc:mysql://aaa:2600/test?useUnicode=true&characterEncoding=UTF-8&serverTimezone=GMT%2B8
```

关键点就是 **&serverTimezone=GMT%2B8**

当然也可以更换为 **&serverTimezone=Asia/Shanghai** 或者 **&serverTimezone=Asia/Chongqing** 

###### 解决了什么问题?

我们在用java代码插入到数据库时间时。
比如在java代码里面插入的时间为：2018-06-24 17:29:56
但是在数据库里面显示的时间却为：2018-06-24 09:29:56
有了8个小时的时差。这就是时区不同造成的。

    注意：虽然数据库显示是 2018-06-24 09:29:56 但是还用原来的java逻辑读取出来时间还会恢复正常及：2018-06-24 17:29:56
