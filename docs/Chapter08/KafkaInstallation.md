# Kafka 安装

[http://kafka.apache.org/quickstart](http://kafka.apache.org/quickstart)
* 测试
* 配置端口：2182
* 管理目录： /opt/soft/kafka/kafka_2.12-2.3.0
* 启动命令：/opt/soft/kafka/kafka_2.12-2.3.0/bin/kafka-server-start.sh /opt/soft/kafka/kafka_2.12-2.3.0/config/server.properties &

###### 异常
```log
Exception in thread "main" java.lang.UnsupportedClassVersionError: kafka/Kafka : Unsupported major.minor version 52.0
	at java.lang.ClassLoader.defineClass1(Native Method)
	at java.lang.ClassLoader.defineClassCond(ClassLoader.java:631)
	at java.lang.ClassLoader.defineClass(ClassLoader.java:615)
	at java.security.SecureClassLoader.defineClass(SecureClassLoader.java:141)
	at java.net.URLClassLoader.defineClass(URLClassLoader.java:283)
	at java.net.URLClassLoader.access$000(URLClassLoader.java:58)
	at java.net.URLClassLoader$1.run(URLClassLoader.java:197)
	at java.security.AccessController.doPrivileged(Native Method)
	at java.net.URLClassLoader.findClass(URLClassLoader.java:190)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:306)
	at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:301)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:247)
Could not find the main class: kafka.Kafka.  Program will exit.
```
原因很明显是jdk版本不对

修改/opt/soft/kafka/kafka_2.12-2.3.0/bin/kafka-server-start.sh

在顶部添加如下值：
```shell script
export JAVA_HOME="/opt/soft/jdk/jdk1.8.0_65/"
```


###### 单机模式
Kafka使用ZooKeeper，因此如果您还没有ZooKeeper服务器，则需要先启动它。
您可以使用与kafka一起打包的便捷脚本来获得快速且脏的单节点ZooKeeper实例
```shell script
> bin/zookeeper-server-start.sh config/zookeeper.properties
[2013-04-22 15:01:37,495] INFO Reading configuration from: config/zookeeper.properties (org.apache.zookeeper.server.quorum.QuorumPeerConfig)
...
```
现在启动Kafka服务器
```shell script
> bin/kafka-server-start.sh config/server.properties
[2013-04-22 15:01:47,028] INFO Verifying properties (kafka.utils.VerifiableProperties)
[2013-04-22 15:01:47,051] INFO Property socket.send.buffer.bytes is overridden to 1048576 (kafka.utils.VerifiableProperties)
```

###### 集群模式

修改zookeeper配置

    /opt/soft/kafka/kafka_2.12-2.3.0/config/server.properties
    
旧值
```properties
zookeeper.connect=localhost:2181

# Timeout in ms for connecting to zookeeper
zookeeper.connection.timeout.ms=6000
```
新值
```properties
# Zookeeper connection string (see zookeeper docs for details).
# This is a comma separated host:port pairs, each corresponding to a zk
# server. e.g. "127.0.0.1:3000,127.0.0.1:3001,127.0.0.1:3002".
# You can also append an optional chroot string to the urls to specify the
# root directory for all kafka znodes.
zookeeper.connect=192.168.66.8:2182

# Timeout in ms for connecting to zookeeper
zookeeper.connection.timeout.ms=6000
```

    注意 server.properties里broker.id的值;不同的实例应该设置不同的值


