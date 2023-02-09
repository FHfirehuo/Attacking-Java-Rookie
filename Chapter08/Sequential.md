# 消息队列的顺序性

一、为什么出现顺序错乱？

在生产中经常会有一些类似报表系统这样的系统，需要做 MySQL 的 binlog 同步。比如订单系统要同步订单表的数据到[大数据](https://so.csdn.net/so/search?q=大数据&spm=1001.2101.3001.7020)部门的 MySQL 库中用于报表统计分析，通常的做法是基于 Canal 这样的中间件去监听订单数据库的 binlog，然后把这些 binlog 发送到 MQ 中，再由消费者从 MQ 中获取 binlog 落地到大数据部门的 MySQL 中。

在这个过程中，可能会有对某个订单的增删改操作，比如有三条 binlog 执行顺序是增加、修改、删除；消费者愣是换了顺序给执行成删除、修改、增加，这样能行吗？肯定是不行的
1、RabbitMQ 消息顺序错乱

对于 RabbitMQ 来说，导致上面顺序错乱的原因通常是消费者是集群部署，不同的消费者消费到了同一订单的不同的消息，如消费者 A 执行了增加，消费者 B 执行了修改，消费者 C 执行了删除，但是消费者 C 执行比消费者 B 快，消费者 B 又比消费者 A 快，就会导致消费 binlog 执行到数据库的时候顺序错乱，本该顺序是增加、修改、删除，变成了删除、修改、增加。

如下图是 RabbitMQ 可能出现顺序错乱的问题示意图：

![在这里插入图片描述](https://img-blog.csdnimg.cn/a746b5ff7ec24864b14bd77021c03aa2.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5aSp6ams6KGM56m65rOi,size_20,color_FFFFFF,t_70,g_se,x_16)

2、Kafka 消息顺序错乱

对于 Kafka 来说，一个 topic 下同一个 partition 中的消息肯定是有序的，生产者在写的时候可以指定一个 key，通过我们会用订单号作为 key，这个 key 对应的消息都会发送到同一个 partition 中，所以消费者消费到的消息也一定是有序的。

那么为什么 Kafka 还会存在消息错乱的问题呢？问题就出在消费者身上。通常我们消费到同一个 key 的多条消息后，会使用多线程技术去并发处理来提高消息处理速度，否则一条消息的处理需要耗时几十 ms，1 秒也就只能处理几十条消息，吞吐量就太低了。而多线程并发处理的话，binlog 执行到数据库的时候就不一定还是原来的顺序了。

如下图是 Kafka 可能出现乱序现象的示意图：

![在这里插入图片描述](https://img-blog.csdnimg.cn/af394a719fc941569ec87e1d33348135.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5aSp6ams6KGM56m65rOi,size_20,color_FFFFFF,t_70,g_se,x_16)

3、RocketMQ 消息顺序错乱

对于 RocketMQ 来说，每个 Topic 可以指定多个 MessageQueue，当我们写入消息的时候，会把消息均匀地分发到不同的 MessageQueue 中，比如同一个订单号的消息，增加 binlog 写入到 MessageQueue1 中，修改 binlog 写入到 MessageQueue2 中，删除 binlog 写入到 MessageQueue3 中。

但是当消费者有多台机器的时候，会组成一个 Consumer Group，Consumer Group 中的每台机器都会负责消费一部分 MessageQueue 的消息，所以可能消费者 A 消费了 MessageQueue1 的消息执行增加操作，消费者 B 消费了 MessageQueue2 的消息执行修改操作，消费者 C 消费了 MessageQueue3 的消息执行删除操作，但是此时消费 binlog 执行到数据库的时候就不一定是消费者 A 先执行了，有可能消费者 C 先执行删除操作，因为几台消费者是并行执行，是不能够保证他们之间的执行顺序的。

如下图是 RocketMQ 可能出现乱序现象的示意图：
![在这里插入图片描述](https://img-blog.csdnimg.cn/8f6772b30f41411db3752227a4dd2086.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5aSp6ams6KGM56m65rOi,size_20,color_FFFFFF,t_70,g_se,x_16)

二、如何保证消息的顺序性？

知道了为什么会出现顺序错乱之后，就要想办法保证消息的顺序性了。从前面可以知道，顺序错乱要么是由于多个消费者消费到了同一个订单号的不同消息，要么是由于同一个订单号的消息分发到了 MQ 中的不同机器中。不同的[消息队列](https://so.csdn.net/so/search?q=消息队列&spm=1001.2101.3001.7020)保证消息顺序性的方案也各不相同。
1、RabbitMQ 保证消息的顺序性

RabbitMQ 的问题是由于不同的消息都发送到了同一个 queue 中，多个消费者都消费同一个 queue 的消息。解决这个问题，我们可以给 RabbitMQ 创建多个 queue，每个消费者固定消费一个 queue 的消息，生产者发送消息的时候，同一个订单号的消息发送到同一个 queue 中，由于同一个 queue 的消息是一定会保证有序的，那么同一个订单号的消息就只会被一个消费者顺序消费，从而保证了消息的顺序性。

如下图是 RabbitMQ 保证消息顺序性的方案：![在这里插入图片描述](https://img-blog.csdnimg.cn/8b402e5a193548c79d9b4778e3636e32.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5aSp6ams6KGM56m65rOi,size_20,color_FFFFFF,t_70,g_se,x_16)

2、Kafka 保证消息的顺序性

Kafka 从生产者到消费者消费消息这一整个过程其实都是可以保证有序的，导致最终乱序是由于消费者端需要使用多线程并发处理消息来提高吞吐量，比如消费者消费到了消息以后，开启 32 个线程处理消息，每个线程线程处理消息的快慢是不一致的，所以才会导致最终消息有可能不一致。

所以对于 Kafka 的消息顺序性保证，其实我们只需要保证同一个订单号的消息只被同一个线程处理的就可以了。由此我们可以在线程处理前增加个内存队列，每个线程只负责处理其中一个内存队列的消息，同一个订单号的消息发送到同一个内存队列中即可。

如下图是 Kafka 保证消息顺序性的方案：![在这里插入图片描述](https://img-blog.csdnimg.cn/860f63c70b944f73a30925bf288d2f6f.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5aSp6ams6KGM56m65rOi,size_20,color_FFFFFF,t_70,g_se,x_16)

3、RocketMQ 保证消息的顺序性

RocketMQ 的消息乱序是由于同一个订单号的 binlog 进入了不同的 MessageQueue，进而导致一个订单的 binlog 被不同机器上的 Consumer 处理。

要解决 RocketMQ 的乱序问题，我们只需要想办法让同一个订单的 binlog 进入到同一个 MessageQueue 中就可以了。因为同一个 MessageQueue 内的消息是一定有序的，一个 MessageQueue 中的消息只能交给一个 Consumer 来进行处理，所以 Consumer 消费的时候就一定会是有序的。

如下图是 RocketMQ 保证消息顺序性的方案：![在这里插入图片描述](https://img-blog.csdnimg.cn/6dc6baf2c9324d2c9d67af17527edb67.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5aSp6ams6KGM56m65rOi,size_20,color_FFFFFF,t_70,g_se,x_16)

三、总结

本文介绍了不同的消息队列出现顺序错乱问题的原因，也分别给出了常用消息队列保证消息顺序性的解决方案。消息的顺序性其实是 MQ 中比较值得注意的一个常见问题，特别是对于同一订单存在多条消息的这种情况，不同的执行顺序可能导致完全不同的结果，顺序的错乱可能会导致业务上的很多问题，而且往往这些问题还是比较难排查的。不过也不是所有消息都需要考虑它的全局顺序性，不相关的消息就算顺序错乱对业务也是毫无影响的，需要根据具体问题来看。