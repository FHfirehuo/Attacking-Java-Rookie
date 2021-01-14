# 跳跃表

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