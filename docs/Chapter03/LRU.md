# LRU

LRU，最近最少使用，把数据加入一个链表中，按访问时间排序，发生淘汰的时候，把访问时间最旧的淘汰掉。

> 比如有数据 1，2，1，3，2<br>
> 此时缓存中已有（1，2）<br>
> 当3加入的时候，得把后面的2淘汰，变成（3，1）<br>
> 显然<br>
> LRU对于循环出现的数据，缓存命中不高<br>
> 比如，这样的数据，1，1，1，2，2，2，3，4，1，1，1，2，2，2.....<br>
> 当走到3，4的时候，1，2会被淘汰掉，但是后面还有很多1，2


### LRU的一个实现方法：
用一个双向链表记录访问时间，因为链表插入删除高效，时间新的在前面，旧的在后面。
用一个哈希表记录缓存(key, value)，哈希查找近似O(1)，发生哈希冲突时最坏O(n)，
同时哈希表中得记录 (key, Node(key, value))

```java
package algorithm.cache;

import java.util.HashMap;
import java.util.Map;

public class LRUCache<E> {


    private Map<Object, DoublyLinkedNode<E>> data;
    //容量
    private int capacity;

    private DoublyLinkedNode<E> head;
    private DoublyLinkedNode<E> tail;

    public LRUCache() {
        this(10);
    }

    public LRUCache(int capacity) {
        data = new HashMap<>(capacity, 1);
        this.capacity = capacity;
    }

    public int Size() {
        return this.data.size();
    }

    public void put(Object key, E element) {

        DoublyLinkedNode<E> newNode = new DoublyLinkedNode();
        newNode.key = key;
        newNode.element = element;

        if (this.data.containsKey(key)) {
            DoublyLinkedNode<E> oldNode = this.data.get(key);
            this.remove(key, oldNode);
        }

        if (data.size() == this.capacity) {
            removeFail();
        }

        this.add(key, newNode);
        if (data.size() == 1) {
            this.head = newNode;
            this.tail = newNode;
            this.head.next = this.tail;
            this.tail.pre = this.head;
        }


    }

    private void removeFail() {
        DoublyLinkedNode<E> item = this.tail;
        this.tail = item.pre;
        data.remove(item.key);
    }

    private void add(Object key, DoublyLinkedNode<E> item) {
        item.next = this.head;
        if (this.head != null) {
            this.head.pre = item;
        }
        this.head = item;
        data.put(key, item);
    }

    private void remove(Object key, DoublyLinkedNode<E> item) {

        if (item.equals(this.tail)){
            this.tail = item.pre;
        }

        if (item.pre != null) {
            item.pre.next = item.next;
        }
        if (item.next != null) {
            item.next.pre = item.pre;
        }


        data.remove(key);
    }

    public E get(Object key) {
        if (!data.containsKey(key)) {
            return null;
        }
        DoublyLinkedNode<E> item = data.get(key);
        this.remove(key, item);
        this.add(key, item);
        return item.element;
    }

    private class DoublyLinkedNode<E> {
        Object key;
        E element;
        DoublyLinkedNode pre;
        DoublyLinkedNode next;
    }

    public static void main(String[] args) {
        LRUCache<Integer> cache = new LRUCache<>(2);
        cache.put(1, 1);
        cache.put(2, 2);
        System.out.println("get 1 = " + cache.get(1));
        System.out.println("add 3");
        cache.put(3, 3);    // 该操作会使得关键字 2 作废
        System.out.println("get 2 = " + cache.get(2));
        System.out.println("add 4");
        cache.put(4, 4);    // 该操作会使得关键字 1 作废
        System.out.println("get 3 = " + cache.get(3));
        System.out.println("get 4 = " + cache.get(4));
        System.out.println("get 1 = " + cache.get(1));

    }

}

```

> get 1 = 1<br>
  add 3<br>
  get 2 = null<br>
  add 4<br>
  get 3 = 3<br>
  get 4 = 4<br>
  get 1 = null<br>

### java官方实现 LinkedHashMap


LinkedHashMap底层就是用的HashMap加双链表实现的，而且本身已经实现了按照访问顺序的存储。
此外，LinkedHashMap中本身就实现了一个方法removeEldestEntry用于判断是否需要移除最不常读取的数，
方法默认是直接返回false，不会移除元素，所以需要重写该方法。即当缓存满后就移除最不常用的数。

```java
public class LRU<K,V> {
 
  private static final float hashLoadFactory = 0.75f;
  private LinkedHashMap<K,V> map;
  private int cacheSize;
 
  public LRU(int cacheSize) {
    this.cacheSize = cacheSize;
    int capacity = (int)Math.ceil(cacheSize / hashLoadFactory) + 1;
    map = new LinkedHashMap<K,V>(capacity, hashLoadFactory, true){
      private static final long serialVersionUID = 1;
 
      @Override
      protected boolean removeEldestEntry(Map.Entry eldest) {
        return size() > LRU.this.cacheSize;
      }
    };
  }
 
  public synchronized V get(K key) {
    return map.get(key);
  }
 
  public synchronized void put(K key, V value) {
    map.put(key, value);
  }
 
  public synchronized void clear() {
    map.clear();
  }
 
  public synchronized int usedSize() {
    return map.size();
  }
 
  public void print() {
    for (Map.Entry<K, V> entry : map.entrySet()) {
      System.out.print(entry.getValue() + "--");
    }
    System.out.println();
  }
}
```

当存在热点数据时，LRU的效率很好，但偶发性的、周期性的批量操作会导致LRU命中率急剧下降，缓存污染情况比较严重。

### 扩展

##### LRU-K

LRU-K中的K代表最近使用的次数，因此LRU可以认为是LRU-1。LRU-K的主要目的是为了解决LRU算法“缓存污染”的问题，其核心思想是将“最近使用过1次”的判断标准扩展为“最近使用过K次”。
相比LRU，LRU-K需要多维护一个队列，用于记录所有缓存数据被访问的历史。只有当数据的访问次数达到K次的时候，才将数据放入缓存。当需要淘汰数据时，LRU-K会淘汰第K次访问时间距当前时间最大的数据。

数据第一次被访问时，加入到历史访问列表，如果书籍在访问历史列表中没有达到K次访问，则按照一定的规则（FIFO,LRU）淘汰；当访问历史队列中的数据访问次数达到K次后，将数据索引从历史队列中删除，将数据移到缓存队列中，并缓存数据，缓存队列重新按照时间排序；缓存数据队列中被再次访问后，重新排序，需要淘汰数据时，淘汰缓存队列中排在末尾的数据，即“淘汰倒数K次访问离现在最久的数据”。
LRU-K具有LRU的优点，同时还能避免LRU的缺点，实际应用中LRU-2是综合最优的选择。由于LRU-K还需要记录那些被访问过、但还没有放入缓存的对象，因此内存消耗会比LRU要多。

##### two queue

Two queues（以下使用2Q代替）算法类似于LRU-2，不同点在于2Q将LRU-2算法中的访问历史队列（注意这不是缓存数据的）改为一个FIFO缓存队列，即：2Q算法有两个缓存队列，一个是FIFO队列，一个是LRU队列。当数据第一次访问时，2Q算法将数据缓存在FIFO队列里面，当数据第二次被访问时，则将数据从FIFO队列移到LRU队列里面，两个队列各自按照自己的方法淘汰数据。

新访问的数据插入到FIFO队列中，如果数据在FIFO队列中一直没有被再次访问，则最终按照FIFO规则淘汰；如果数据在FIFO队列中再次被访问到，则将数据移到LRU队列头部，如果数据在LRU队列中再次被访问，则将数据移动LRU队列头部，LRU队列淘汰末尾的数据。

##### Multi Queue(MQ)

MQ算法根据访问频率将数据划分为多个队列，不同的队列具有不同的访问优先级，其核心思想是：优先缓存访问次数多的数据。详细的算法结构图如下，Q0，Q1....Qk代表不同的优先级队列，Q-history代表从缓存中淘汰数据，但记录了数据的索引和引用次数的队列：

新插入的数据放入Q0，每个队列按照LRU进行管理，当数据的访问次数达到一定次数，需要提升优先级时，将数据从当前队列中删除，加入到高一级队列的头部；为了防止高优先级数据永远不会被淘汰，当数据在指定的时间里没有被访问时，需要降低优先级，将数据从当前队列删除，加入到低一级的队列头部；需要淘汰数据时，从最低一级队列开始按照LRU淘汰，每个队列淘汰数据时，将数据从缓存中删除，将数据索引加入Q-history头部。如果数据在Q-history中被重新访问，则重新计算其优先级，移到目标队列头部。Q-history按照LRU淘汰数据的索引。

MQ需要维护多个队列，且需要维护每个数据的访问时间，复杂度比LRU高。

##### LRU算法对比

| 对比点| 对比| 
| :---| :---|
| 命中率| LRU-2 > MQ(2) > 2Q > LRU |
| 复杂度| LRU-2 > MQ(2) > 2Q > LRU |
| 代价  | LRU-2  > MQ(2) > 2Q > LRU|

### 实现带有过期时间的LRU

```java
 // 构造方法：只要有缓存了，过期清除线程就开始工作
    public LRU() {
        swapExpiredPool.scheduleWithFixedDelay(new ExpiredNode(), 3,3,TimeUnit.SECONDS);
    }
```

```java
public class ExpiredNode implements Runnable {
        @Override
        public void run() {
            // 第一步：获取当前的时间
            long now = System.currentTimeMillis();
            while (true) {
                // 第二步：从过期队列弹出队首元素，如果不存在，或者不过期就返回
                Node node = expireQueue.peek();
                if (node == null || node.expireTime > now)return;
                // 第三步：过期了那就从缓存中删除，并且还要从队列弹出
                cache.remove(node.key);
                expireQueue.poll();
            }// 此过程为while(true)，一直进行判断和删除操作
        }
    }
```
