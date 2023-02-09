# doker中使用mysql



```shell
docker run -p 3307:3306 --name mysql  -v /Users/apple/DockerFile/mysql/log:/var/log/mysql  -v /Users/apple/DockerFile/mysql/data:/var/lib/mysql  -v /Users/apple/DockerFile/mysql/conf:/etc/mysql  -e MYSQL_ROOT_PASSWORD=root  -d mysql:5.7


sudo docker run --privileged=true -p 3307:3306 --name mysqldc  -v /Users/apple/DockerFile/mysql/log:/var/log/mysql  -v /Users/apple/DockerFile/mysql/data:/var/lib/mysql  -e MYSQL_ROOT_PASSWORD=root  -d mysql:8.0.30
```



2022-12-28 15:59:23+00:00 [ERROR] [Entrypoint]: Database is uninitialized and password option is not specified
    You need to specify one of the following:

```mysql
- MYSQL_ROOT_PASSWORD

select host, user, authentication_string, plugin from user;



alter user 'canal'@'%' identified with mysql_native_password by 'canal';

GRANT all privileges on.to 'root'@'%' indentified by 'root' with grant option;

FLUSH PRIVILEGES;



mysql> show variables like 'slow%';
+---------------------+--------------------------------------+
| Variable_name       | Value                                |
+---------------------+--------------------------------------+
| slow_launch_time    | 2                                    |
| slow_query_log      | OFF                                  |
| slow_query_log_file | /var/lib/mysql/2ce69a55adc9-slow.log |
+---------------------+--------------------------------------+
3 rows in set (0.01 sec)

mysql> set global slow_query_log = ON;
Query OK, 0 rows affected (0.01 sec)

mysql> show variables like 'slow%';
+---------------------+--------------------------------------+
| Variable_name       | Value                                |
+---------------------+--------------------------------------+
| slow_launch_time    | 2                                    |
| slow_query_log      | ON                                   |
| slow_query_log_file | /var/lib/mysql/2ce69a55adc9-slow.log |
+---------------------+--------------------------------------+
3 rows in set (0.00 sec)

mysql> 
```



