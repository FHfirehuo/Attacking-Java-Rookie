# 跳跃表

## 为啥 Redis 使用跳表而不是红黑树

> There are a few reasons:
>
> 1. They are not very memory intensive. It's up to you basically. Changing parameters about the probability of a node to have a given number of levels will make then less memory intensive than btrees.
> 2. A sorted set is often target of many ZRANGE or ZREVRANGE operations, that is, traversing the skip list as a linked list. With this operation the cache locality of skip lists is at least as good as with other kind of balanced trees.
> 3. They are simpler to implement, debug, and so forth. For instance thanks to the skip list simplicity I received a patch (already in Redis master) with augmented skip lists implementing ZRANK in O(log(N)). It required little changes to the code.
>    About the Append Only durability & speed, I don't think it is a good idea to optimize Redis at cost of more code and more complexity for a use case that IMHO should be rare for the Redis target (fsync() at every command). Almost no one is using this feature even with ACID SQL databases, as the performance hint is big anyway.
>    About threads: our experience shows that Redis is mostly I/O bound. I'm using threads to serve things from Virtual Memory. The long term solution to exploit all the cores, assuming your link is so fast that you can saturate a single core, is running multiple instances of Redis (no locks, almost fully scalable linearly with number of cores), and using the "Redis Cluster" solution that I plan to develop in the future.



- 按照区间查找数据（比如查找值在[100, 356]之间的数据）；

- 其中，插入、删除、查找以及迭代输出有序序列这几个操作，红黑树也可以完成，时间复杂度跟跳表是一样的。但是，按照区间来查找数据这个操作，红黑树的效率没有跳表高。

    对于按照区间查找数据这个操作，跳表可以做到O(logn)的时间复杂度定位区间的起点，然后在原始链表中顺序往后遍历就可以了。这样做非常高效。

    当然，Redis之所以用跳表来实现有序集合，还有其他原因，比如，跳表更容易代码实现。虽然跳表的实现也不简单，但比起红黑树来说还是好懂、好写多了，而简单就意味着可读性好，不容易出错。还有，跳表更加灵活，它可以通过改变索引构建策略，有效平衡执行效率和内存消耗。不过，跳表也不能完全替代红黑树。因为红黑树比跳表的出现要早一些，很多编程语言中的Map类型都是通过红黑树来实现的。我们做业务开发的时候，直接拿来用就可以了，不用费劲自己去实现一个红黑树，但是跳表并没有一个现成的实现，所以在开发中，如果你想使用跳表，必须要自己实现。
  

## 跳跃表结构

与跳表相关结构定义在一起的还有一个有序集合结构，很多人会说 redis 中的有序集合是跳表实现的，这句话不错，但有失偏驳。

```
typedef struct zset {
    dict *dict;
    zskiplist *zsl;
} zset;
```


准确来说，redis 中的有序集合是由我们之前介绍过的字典加上跳表实现的，字典中保存的数据和分数 score 的映射关系，每次插入数据会从字典中查询，如果已经存在了，就不再插入，有序集合中是不允许重复数据。

下面我们看看 redis 中跳表的相关代码的实现情况。


## 跳表初始化

跳表初始化

redis 中初始化一个跳表的代码如下：

```
zskiplistNode *zslCreateNode(int level, double score, sds ele) {
    zskiplistNode *zn =
        zmalloc(sizeof(*zn)+level*sizeof(struct zskiplistLevel));
    zn->score = score;
    zn->ele = ele;
    return zn;
}

/* Create a new skiplist. */
zskiplist *zslCreate(void) {
    int j;
    zskiplist *zsl;
    //分配内存空间
    zsl = zmalloc(sizeof(*zsl));
    //默认只有一层索引
    zsl->level = 1;
    //0 个节点
    zsl->length = 0;
    //1、创建一个 node 节点，这是个哨兵节点
    //2、为 level 数组分配 ZSKIPLIST_MAXLEVEL=32 内存大小
    //3、也即 redis 中支持索引最大 32 层
    zsl->header = zslCreateNode(ZSKIPLIST_MAXLEVEL,0,NULL);
    //为哨兵节点的 level 初始化
    for (j = 0; j < ZSKIPLIST_MAXLEVEL; j++) {
        zsl->header->level[j].forward = NULL;
        zsl->header->level[j].span = 0;
    }
    zsl->header->backward = NULL;
    zsl->tail = NULL;
    return zsl;
}
```

zslCreate 用于初始化一个跳表，比较简单，我也给出了基本的注释，这里不再赘述了，强调一点的是，redis 中实现的跳表最高允许 32 层索引，这么做也是一种性能与内存之间的衡量，过多的索引层必然占用更多的内存空间，32 是一个比较合适值。

2、插入一个节点