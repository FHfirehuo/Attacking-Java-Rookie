# Redis

```shell
docker run --name redis -m 200m -p 6379:6379 \
-e TZ=Asiz/Shanghai \
--requirepass 123455
--privileged=true -d redis
```





## Redis删除过期key的策略

## 在Redis中，假如我们设置了100w个key，这些key设置了只能存活2个小时，那么在2个小时后，redis是如何来删除这些key的？

答案：定期删除 and 惰性删除。

## 那什么是定期删除？什么的惰性删除？靠这两种策略就可以删除掉redis中过期的key吗？

定期删除：redis默认每隔100ms随机抽取一些key，检查是否有过期的key，有过期的key则删除。需要注意的是redis不是每隔100ms就将所有的key检查一次，而是随机抽取一些key来检查是否过期的key。如果每100ms，就将redis的所有key（假设有1000w的key）都检查一遍，那么会给CPU带来很大的负载，redis就会卡死了。因此，如果只采用定期删除策略，会导致很多key到时间还没有被删除。

惰性删除：定期删除策略可能会导致很多过期的key到了时间也还没有被删除掉；为了解决这个问题，redis增加了惰性删除策略；对于那些过期的key，靠定期删除策略没有被删除掉，还保留在内存中，这时候如果系统去主动查询这个key，redis判断已经过期了，才会把这个过期的key删除掉。

靠这两种策略就可以删除掉redis中过期的key吗？

仅仅靠通过设置过期时间还是存在着问题的。由于定期删除策略是随机抽取的，因此很有可能漏掉很多过期的key，这时候我们也没有主动去查询这些过期的key，因此也就没有使用惰性删除策略了，这时候如果有大量的过期key堆积，会导致内存被消耗完。要解决这个问题：可以使用 redis 内存淘汰机制。

## Redis 内存淘汰策略：

1. noeviction：当内存不足以容纳新写入数据时，新写入操作会报错。
2. allkeys-lru：当内存不足以容纳新写入数据时，在键空间中，移除最近最少使用的key。（这个比较常用）
3. allkeys-random：当内存不足以容纳新写入数据时，在键空间中，随机移除某个key。
4. volatile-lru：当内存不足以容纳新写入数据时，在设置了过期时间的键空间中，移除最近最少使用的key。
5. volatile-random：当内存不足以容纳新写入数据时，在设置了过期时间的键空间中，随机移除某个key。
6. volatile-ttl：当内存不足以容纳新写入数据时，在设置了过期时间的键空间中，有更早过期时间的key优先移除


# Redis中删除过期Key的三种策略

Redis对于过期键有三种清除策略：

被动删除：当读/写一个已经过期的key时，会触发惰性删除策略，直接删除掉这个过期key
主动删除：由于惰性删除策略无法保证冷数据被及时删掉，所以Redis会定期主动淘汰一批已过期的key,当前已用内存超过maxmemory限定时，触发主动清理策略

被动删除

只有key被操作时(如GET)，REDIS才会被动检查该key是否过期，如果过期则删除之并且返回NIL。 1、这种删除策略对CPU是友好的，删除操作只有在不得不的情况下才会进行，不会对其他的expire key上浪费无谓的CPU时间。 2、但是这种策略对内存不友好，一个key已经过期，但是在它被操作之前不会被删除，仍然占据内存空间。如果有大量的过期键存在但是又很少被访问到，那会造成大量的内存空间浪费。expireIfNeeded(redisDb *db, robj *key)函数位于src/db.c。 但仅是这样是不够的，因为可能存在一些key永远不会被再次访问到，这些设置了过期时间的key也是需要在过期后被删除的，我们甚至可以将这种情况看作是一种内存泄露—-无用的垃圾数据占用了大量的内存，而服务器却不会自己去释放它们，这对于运行状态非常依赖于内存的Redis服务器来说，肯定不是一个好消息。

主动删除

先说一下时间事件，对于持续运行的服务器来说， 服务器需要定期对自身的资源和状态进行必要的检查和整理， 从而让服务器维持在一个健康稳定的状态， 这类操作被统称为常规操作（cron job）

在 Redis 中， 常规操作由 redis.c/serverCron 实现， 它主要执行以下操作

更新服务器的各类统计信息，比如时间、内存占用、数据库占用情况等。
清理数据库中的过期键值对。
对不合理的数据库进行大小调整。
关闭和清理连接失效的客户端。
尝试进行 AOF 或 RDB 持久化操作。
如果服务器是主节点的话，对附属节点进行定期同步。
如果处于集群模式的话，对集群进行定期同步和连接测试。
Redis 将 serverCron 作为时间事件来运行， 从而确保它每隔一段时间就会自动运行一次， 又因为 serverCron 需要在 Redis 服务器运行期间一直定期运行， 所以它是一个循环时间事件： serverCron 会一直定期执行，直到服务器关闭为止。

在 Redis 2.6 版本中， 程序规定 serverCron 每秒运行 10 次， 平均每 100 毫秒运行一次。 从 Redis 2.8 开始， 用户可以通过修改 hz选项来调整 serverCron 的每秒执行次数， 具体信息请参考 redis.conf 文件中关于 hz 选项的说明也叫定时删除，这里的“定期”指的是Redis定期触发的清理策略，由位于src/redis.c的activeExpireCycle(void)函数来完成。

serverCron是由redis的事件框架驱动的定位任务，这个定时任务中会调用activeExpireCycle函数，针对每个db在限制的时间REDIS_EXPIRELOOKUPS_TIME_LIMIT内迟可能多的删除过期key，之所以要限制时间是为了防止过长时间 的阻塞影响redis的正常运行。这种主动删除策略弥补了被动删除策略在内存上的不友好。

因此，Redis会周期性的随机测试一批设置了过期时间的key并进行处理。测试到的已过期的key将被删除。典型的方式为,Redis每秒做10次如下的步骤：

随机测试100个设置了过期时间的key
删除所有发现的已过期的key
若删除的key超过25个则重复步骤1
这是一个基于概率的简单算法，基本的假设是抽出的样本能够代表整个key空间，redis持续清理过期的数据直至将要过期的key的百分比降到了25%以下。这也意味着在任何给定的时刻已经过期但仍占据着内存空间的key的量最多为每秒的写操作量除以4.

Redis-3.0.0中的默认值是10，代表每秒钟调用10次后台任务。

除了主动淘汰的频率外，Redis对每次淘汰任务执行的最大时长也有一个限定，这样保证了每次主动淘汰不会过多阻塞应用请求，以下是这个限定计算公式：

#define ACTIVE_EXPIRE_CYCLE_SLOW_TIME_PERC 25 /* CPU max % for keys collection */  
...  
timelimit = 1000000*ACTIVE_EXPIRE_CYCLE_SLOW_TIME_PERC/server.hz/100;
hz调大将会提高Redis主动淘汰的频率，如果你的Redis存储中包含很多冷数据占用内存过大的话，可以考虑将这个值调大，但Redis作者建议这个值不要超过100。我们实际线上将这个值调大到100，观察到CPU会增加2%左右，但对冷数据的内存释放速度确实有明显的提高（通过观察keyspace个数和used_memory大小）。

可以看出timelimit和server.hz是一个倒数的关系，也就是说hz配置越大，timelimit就越小。换句话说是每秒钟期望的主动淘汰频率越高，则每次淘汰最长占用时间就越短。这里每秒钟的最长淘汰占用时间是固定的250ms（1000000*ACTIVE_EXPIRE_CYCLE_SLOW_TIME_PERC/100），而淘汰频率和每次淘汰的最长时间是通过hz参数控制的。

从以上的分析看，当redis中的过期key比率没有超过25%之前，提高hz可以明显提高扫描key的最小个数。假设hz为10，则一秒内最少扫描200个key（一秒调用10次*每次最少随机取出20个key），如果hz改为100，则一秒内最少扫描2000个key；另一方面，如果过期key比率超过25%，则扫描key的个数无上限，但是cpu时间每秒钟最多占用250ms。

当REDIS运行在主从模式时，只有主结点才会执行上述这两种过期删除策略，然后把删除操作”del key”同步到从结点。

maxmemory 当前已用内存超过maxmemory限定时，触发主动清理策略

volatile-lru：只对设置了过期时间的key进行LRU（默认值）
allkeys-lru ： 删除lru算法的key
volatile-random：随机删除即将过期key
allkeys-random：随机删除
volatile-ttl ： 删除即将过期的
noeviction ： 永不过期，返回错误
当mem_used内存已经超过maxmemory的设定，对于所有的读写请求，都会触发redis.c/freeMemoryIfNeeded(void)函数以清理超出的内存。注意这个清理过程是阻塞的，直到清理出足够的内存空间。所以如果在达到maxmemory并且调用方还在不断写入的情况下，可能会反复触发主动清理策略，导致请求会有一定的延迟。

清理时会根据用户配置的maxmemory-policy来做适当的清理（一般是LRU或TTL），这里的LRU或TTL策略并不是针对redis的所有key，而是以配置文件中的maxmemory-samples个key作为样本池进行抽样清理。

maxmemory-samples在redis-3.0.0中的默认配置为5，如果增加，会提高LRU或TTL的精准度，redis作者测试的结果是当这个配置为10时已经非常接近全量LRU的精准度了，并且增加maxmemory-samples会导致在主动清理时消耗更多的CPU时间，建议：

尽量不要触发maxmemory，最好在mem_used内存占用达到maxmemory的一定比例后，需要考虑调大hz以加快淘汰，或者进行集群扩容。
如果能够控制住内存，则可以不用修改maxmemory-samples配置；如果Redis本身就作为LRU cache服务（这种服务一般长时间处于maxmemory状态，由Redis自动做LRU淘汰），可以适当调大maxmemory-samples。
这里提一句，实际上redis根本就不会准确的将整个数据库中最久未被使用的键删除，而是每次从数据库中随机取5个键并删除这5个键里最久未被使用的键。上面提到的所有的随机的操作实际上都是这样的，这个5可以用过redis的配置文件中的maxmemeory-samples参数配置。

Replication link和AOF文件中的过期处理

为了获得正确的行为而不至于导致一致性问题，当一个key过期时DEL操作将被记录在AOF文件并传递到所有相关的slave。也即过期删除操作统一在master实例中进行并向下传递，而不是各salve各自掌控。
这样一来便不会出现数据不一致的情形。当slave连接到master后并不能立即清理已过期的key（需要等待由master传递过来的DEL操作），slave仍需对数据集中的过期状态进行管理维护以便于在slave被提升为master会能像master一样独立的进行过期处理。


## 后台删除之lazyfree机制
为了解决redis使用del命令删除大体积的key，或者使用flushdb、flushall删除数据库时，造成redis阻塞的情况，在redis 4.0引入了lazyfree机制，可将删除操作放在后台，让后台子线程(bio)执行，避免主线程阻塞。

lazy free的使用分为2类：第一类是与DEL命令对应的主动删除，第二类是过期key删除、maxmemory key驱逐淘汰删除。

#### 主动删除
UNLINK命令是与DEL一样删除key功能的lazy free实现。唯一不同时，UNLINK在删除集合类键时，如果集合键的元素个数大于64个(详细后文），会把真正的内存释放操作，给单独的bio来操作。

```
127.0.0.1:7000> UNLINK mylist
(integer) 1
FLUSHALL/FLUSHDB ASYNC

 

127.0.0.1:7000> flushall async //异步清理实例数据
```

#### 被动删除
lazy free应用于被动删除中，目前有4种场景，每种场景对应一个配置参数； 默认都是关闭。

```
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
 slave-lazy-flush n
```

###### lazyfree-lazy-eviction
针对redis内存使用达到maxmeory，并设置有淘汰策略时；在被动淘汰键时，是否采用lazy free机制；

因为此场景开启lazy free, 可能使用淘汰键的内存释放不及时，导致redis内存超用，超过maxmemory的限制。此场景使用时，请结合业务测试。

###### lazyfree-lazy-expire
针对设置有TTL的键，达到过期后，被redis清理删除时是否采用lazy free机制；

此场景建议开启，因TTL本身是自适应调整的速度。

###### lazyfree-lazy-server-del
针对有些指令在处理已存在的键时，会带有一个隐式的DEL键的操作。如rename命令，当目标键已存在,redis会先删除目标键，如果这些目标键是一个big key,那就会引入阻塞删除的性能问题。 此参数设置就是解决这类问题，建议可开启。

###### slave-lazy-flush
针对slave进行全量数据同步，slave在加载master的RDB文件前，会运行flushall来清理自己的数据场景，

参数设置决定是否采用异常flush机制。如果内存变动不大，建议可开启。可减少全量同步耗时，从而减少主库因输出缓冲区爆涨引起的内存使用增长。

##### expire及evict优化
redis在空闲时会进入activeExpireCycle循环删除过期key，每次循环都会率先计算一个执行时间，在循环中并不会遍历整个数据库，而是随机挑选一部分key查看是否到期，所以有时时间不会被耗尽（采取异步删除时更会加快清理过期key），剩余的时间就可以交给freeMemoryIfNeeded来执行。