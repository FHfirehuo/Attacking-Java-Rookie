# 查看Topic列表、消息消费情况

### 查看所有topic

```
./kafka-topics.sh --zookeeper localhost:2181 --list
```

### 查看kafka指定topic的详情

```
./kafka-topics.sh --zookeeper localhost:2181 --topic topic1 --describe
```

### 查看消费者consumer group列表

```
./kafka-consumer-groups.sh  --bootstrap-server localhost:9092 --list
```

### 查看消费者consumer group详情

```
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group fooGroup --describe
```

### 创建主题

```
kafka-console-producer.sh --topic quickstart-events --bootstrap-server localhost:9092
```

### 从头读取消息

```
./kafka-console-consumer.sh --topic topic1 --from-beginning --bootstrap-server localhost:9092 
```

### 删除本地Kafka环境的任何数据，包括创建的所有事件

```
	rm -rf /tmp/kafka-logs /tmp/zookeeper
```

### 删除组

```
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --delete --group fooGroup
```

### 验证组的状态

```
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group fooGroup --state
```



GROUP           COORDINATOR (ID)     ASSIGNMENT-STRATEGY STATE      #MEMBERS

fooGroup         10.129.34.166:9092 (0)  range        Stable     1



如果 #MEMBERS 不为0则**删除**组不可执行

