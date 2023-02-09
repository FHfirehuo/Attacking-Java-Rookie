# ForkJoin分支合并框架原理剖析

ForkJoinPool的出现并不是为了替代ThreadPoolExecutor，而是作为它的补充，因为在某些场景下，它的性能会比ThreadPoolExecutor更好。在之前的模式中，往往一个任务会分配给一条线程执行，如果有个任务耗时比较长，并且在处理期间也没有新的任务到来，那么则会出现一种情况：线程池中只有一条线程在处理这个大任务，而其他线程却空闲着，这会导致CPU负载不均衡，空闲的处理器无法帮助工作，从而无法最大程度上发挥多核机器的性能。而ForkJoinPool则可以完美解决这类问题，但ForkJoinPool更适合的是处理一些耗时的大任务，如果是普通任务，反而会因为过多的任务拆分和多条线程CPU的来回切换导致效率下降。

# 一、初窥ForkJoin框架的神秘面纱

ForkJoinPool是一个建立在分治思想上的产物，其采用任务“大拆小”的方式以及工作窃取算法实现并行处理任务。通俗来说，ForkJoin框架的作用主要是为了实现将大型复杂任务进行递归的分解，直到任务小到指定阈值时才开始执行，从而递归的返回各个小任务的结果汇集成一个大任务的结果，依次类推最终得出最初提交的那个大型复杂任务的结果，这和方法的递归调用思想是一样的。当然ForkJoinPool线程池为了提高任务的并行度和吞吐量做了非常多而且复杂的设计实现，其中最著名的就是任务窃取机制。但ForkJoinPool更适合于处理一些大型任务，因此，ForkJoinPool的适用范围不大，仅限于某些密集且能被分解成多个子任务的任务，同时这些子任务运行的结果可以合并成最终结果。ForkJoin框架主体由三部分组成：

- ①ForkJoinWorkerThread：任务的执行者，具体的线程实体
- ②ForkJoinTask：需要执行的任务实体
- ③ForkJoinPool：管理执行者线程的管理池

> 后续源码阶段会详细分析！

OK~，接着先简单的来看看ForkJoin框架的使用，ForkJoinPool提交任务的方式也有三种，分别为：

- execute()：可提交Runnbale类型的任务
- submit()：可提交Callable类型的任务
- invoke()：可提交ForkJoinTask类型的任务，但ForkJoinTask存在三个子类： ①RecursiveAction：无返回值型ForkJoinTask任务 ②RecursiveTask：有返回值型ForkJoinTask任务 ③CountedCompleter：任务执行完成后可以触发钩子回调函数的任务

上个案例：

> 业务需求：需要根据ID值对某个范围区间内的每条数据进行变更，变更后获取最新数据更新缓存。
> 运行环境：四核机器

```
public class ForkJoinPoolDemo {
    public static void main(String[] args) {
        testFor();
        testForkJoin();
    }
    
    // 测试for循环
    private static void testFor(){
        Instant startTime = Instant.now();
        List<Integer> list = new ArrayList<Integer>();
        for (int id = 1; id <= 1000*10000; id++) {
            // ....... 模拟从数据库根据id查询数据
            list.add(id);
        }
        Instant endTime = Instant.now();
        System.out.println("For循环耗时："+
            Duration.between(startTime,endTime).toMillis() + "ms");
    }
    
    // 测试ForkJoin框架
    private static void testForkJoin(){
        ForkJoinPool forkJoinPool = new ForkJoinPool();
        Instant startTime = Instant.now();
        List invoke = forkJoinPool.invoke(new IdByFindUpdate(1, 1000*10000));
        Instant endTime = Instant.now();
        System.out.println("ForkJoin耗时："+
            Duration.between(startTime,endTime).toMillis() + "ms");
    }
}

class IdByFindUpdate extends RecursiveTask<List> {
    private Integer startID;
    private Integer endID;

    private static final Integer THURSHOLD = 10000; // 临界值/阈值

    public IdByFindUpdate(Integer startID, Integer endID) {
        this.startID = startID;
        this.endID = endID;
    }

    @Override
    protected List<Integer> compute() {
        int taskSize = endID - startID;
        List<Integer> list = new ArrayList<Integer>();

        // 如果任务小于或等于拆分的最小阈值，那么则直接处理任务
        if (taskSize <= THURSHOLD) {
            for (int id = startID; id <= endID; id++) {
                // ....... 模拟从数据库根据id查询数据
                list.add(id);
            }
            return list;
        }
        // 任务fork拆分
        IdByFindUpdate leftTask = new IdByFindUpdate(startID,
                                (startID + endID) / 2);
        leftTask.fork();
        IdByFindUpdate rightTask = new IdByFindUpdate(((startID
                                + endID) / 2) + 1, endID);
        rightTask.fork();

        // 任务join合并
        list.addAll(leftTask.join());
        list.addAll(rightTask.join());

        return list;
    }
}
复制代码
```

案例如上，在其中模拟了数据库查询1000W数据后，将数据添加到集合中的操作。其中定义了任务类：IdByFindUpdate，因为需要返回结果，所以IdByFindUpdate类实现了ForkJoinTask的子类RecursiveTask，确保任务可以提交给ForkJoinPool线程池执行。任务的拆分阈值设定为1W，当任务的查询数量小于阈值时，则直接执行任务。反之，拆分任务直至最小（达到阈值）为止才开始执行，执行结束后合并结果并返回。

同时，我们为了对比区别，也使用了普通的for循环来对比测试，结果如下：

```
/* 运行结果：
 *      For循环耗时：3274ms
 *      ForkJoin耗时：1270ms
 */
复制代码
```

很明显，ForkJoin的执行速度比普通的for循环速度快上三倍左右，但是值得一提的是：如果任务的量级太小，ForkJoin的处理速度反而比不上普通的For循环。这是因为ForkJoin框架在拆分任务fork阶段于合并结果join阶段需要时间，并且开启多条线程处理任务，CPU切换也需要时间，所以当一个任务fork/join阶段以及CPU切换的时间开销大于原本任务的执行时间时，这种情况下则没有必要使用ForkJoin框架。

> 注意：ForkJoin的执行时间跟机器硬件配置以及拆分临界值/阈值的设定也有关系，拆分的阈值并不是越小越好，因为阈值越小时，一个任务拆分的小任务也就会越多，而拆分、合并阶段都是需要时间的，所以阈值需要根据机器的具体硬件设施和任务的类型进行合理的计算，这样才能保证任务执行时能够到达最佳状态。

ok，我也做了一个比较有意思的小测试，把单线程for循环的模式来处理上述任务以及ForkJoin框架处理上述任务分别分为了两次来执行，同时监控了CPU的利用率状况，具体如下：

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/7c455b59155f46cea6279bbc613f3a69~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669346388&x-signature=lkNgg44w5%2By4J%2BmX2%2FfQFqGNJOE%3D)



通过上图可以非常清晰的看见，当单线程for循环的模式处理任务时，因为是在多核机器上执行，所以对于CPU的利用率最高不到50%，而当使用ForkJoin框架处理任务时，几次触顶达到了100%的CPU利用率。所以我们可以得出一个结论：ForkJoin框架在处理任务时，能够在最大程度上发挥机器的性能。

# 二、ForkJoin框架原理浅析及成员构成

在如上，对于ForkJoin框架已经建立的初步的认知，接着慢慢继续分析其内部实现过程。

# 2.1、ForkJoin框架原理

在前面提到过，ForkJoin框架是建立在分治思想上的产物，而向FoorkJoinPool中传递一个任务时，任务的执行流程大体如下：

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/c0ed30a8034d426eba4f899ba4d262ec~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669346388&x-signature=Y3D9TWWjFvjrL52qxiype3b%2FVMI%3D)



从图中可以很轻易的明白：提交的任务会被分割成一个个小的左/右任务，当分割到最小时，会分别执行每个小的任务，执行完成后，会将每个左/右任务的结果进行，从而合并出父级任务的结果，依次类推，直至最终计算出整个任务的最终结果。

> 工作窃取：在引言中曾提到过ForkJoin框架是基于分治和工作窃取思想实现的，那么何谓工作窃取呢？先举个例子带大家简单理解一下这个思想，具体的实现会在后面的源码分析中详细谈到。
> 例子：我是开了个工厂当老板，一条流水线上招聘八个年轻小伙做事，每个人安排了五十个任务，并且对他们说：“你们是一个团队，必须等到每个人做完了自己的任务之后才能一起下班！”。但是在这八个小伙里面，有手比较灵巧做的比较快的，也有做的比较慢、效率比较低的人。那么当一段时间过后，代号③的小伙率先完成了分配给自己的任务后，为了早些下班，会跑到一些做的比较慢的小伙哪儿去拿一些任务过来帮助完成进度，这便是工作窃取思想。在ForkJoin框架同样存在这样的情况，某条线程已经执行完成了分配给自己的任务后，有些线程却还在执行并且堆积着很多任务，那么这条已经处理完自己任务的线程则会去“窃取”其他线程的任务执行。

# 2.2、ForkJoin框架成员分析

在前面说过，ForkJoin框架是由三部分组成，分别为：执行者线程、任务实体以及线程池。接下来我们依次分析这些成员。

# 2.2.1、ForkJoinWorkerThread：任务的执行者

ForkJoinWorkerThread继承了Thread线程类，作为Thread的子类，但是却并没有对线程的调度、执行做改变，只是仅仅增加了一些额外功能。ForkJoinWorkerThread线程被创建出来后都交由ForkJoinPool线程池管理，并且设置为了守护线程，而ForkJoinWorkerThread线程创建出来之后都是被注册到FrokJoinPool线程池，由这些线程来执行用户提交的任务，所以ForkJoinWorkerThread也被称为任务的执行者。

ForkJoinPool线程池与之前的线程池有一点区别在于：之前的线程池中，总共只有一个任务队列，而ForkJoinPool中，每个ForkJoinWorkerThread线程在创建时，都会为它分配一个任务队列。同时为了实现工作窃取机制，该队列被设计为双向队列，线程执行自身队列中的任务时，采用LIFO的方式获取任务，当其他线程窃取任务时，采用FIFO的方式获取任务。ForkJoinWorkerThread线程的主要工作为执行自身队列中的任务，其次是窃取其他线程队列中的任务执行。源码如下：

```
public class ForkJoinWorkerThread extends Thread {
    final ForkJoinPool pool;    // 当前线程所属的线程池
    final ForkJoinPool.WorkQueue workQueue; // 当前线程的双向任务队列
    
    protected ForkJoinWorkerThread(ForkJoinPool pool) {
        // 调用Thread父类的构造函数创建线程实体对象
        // 在这里是先暂时使用aFJT作为线程名称，当外部传递线程名称时会替换
        super("aForkJoinWorkerThread");
        // 当前设置线程池
        this.pool = pool;
        // 向ForkJoinPool线程池中注册当前线程，为当前线程分配任务队列
        this.workQueue = pool.registerWorker(this);
    }
    
    // ForkJoinWorkerThread类 → run方法
    public void run() {
        // 如果队列中有任务
        if (workQueue.array == null) { 
            // 定义异常对象，方便后续记录异常
            Throwable exception = null;
            try {
                // 执行前置钩子函数（预留方法，内部未实现）
                onStart();
                // 执行工作队列中的任务
                pool.runWorker(workQueue);
            } catch (Throwable ex) {
                // 记录捕获的异常信息
                exception = ex;
            } finally {
                try {
                    // 对外写出捕获的异常信息
                    onTermination(exception);
                } catch (Throwable ex) {
                    if (exception == null)
                        exception = ex;
                } finally {
                    // 调用 deregisterWorker 方法进行清理
                    pool.deregisterWorker(this, exception);
                }
            }
        }
    }
    // 省略其他代码.....
}
复制代码
```

很明显的可以看到，ForkJoinWorkerThread的构造函数中，在初始化时会将自身注册进线程池中，然后由线程池给每个线程对象分配一个队列。

# 2.2.2、ForkJoinTask：任务实体

ForkJoinTask与FutrueTask一样，是Futrue接口的子类，ForkJoinTask是一种可以将任务进行递归分解执行，从而提高执行并行度的任务类型，执行结束后也可以支持结果返回。但ForkJoinTask仅是一个抽象类，子类有三个：

- ①RecursiveAction：无返回值型ForkJoinTask任务
- ②RecursiveTask：有返回值型ForkJoinTask任务
- ③CountedCompleter：任务执行完成后可以触发钩子回调函数的任务

ForkJoinTask的作用就是根据任务的分解实现，将任务进行拆分，以及等待子任务的执行结果合并成父任务的结果。ForkJoinTask内部存在一个整数类型的成员status，该成员高16位记录任务的执行状态，如：如NORMAL、CANCELLED或EXCEPTIONAL，低16位预留用于记录用户自定义的任务标签。ForkJoinTask源码具体如下：

```
public abstract class ForkJoinTask<V> implements Future<V>, Serializable {
    // 表示任务的执行状态，总共有如下几种值
    volatile int status;
    // 获取任务状态的掩码，后续用于位计算，判断任务是否正常执行结束
    static final int DONE_MASK   = 0xf0000000;
    // 表示任务正常执行结束
    static final int NORMAL      = 0xf0000000; 
    // 表示任务被取消
    static final int CANCELLED   = 0xc0000000;
    // 表示任务出现异常结束
    static final int EXCEPTIONAL = 0x80000000;
    // 表示当前任务被别的任务依赖，在结束前会通知其他任务join结果
    static final int SIGNAL      = 0x00010000; 
    // 低16位掩码，预留占位(short mask)
    // setForkJoinTaskTag方法中应用了该成员，但这个方法没实现/应用
    static final int SMASK       = 0x0000ffff;

    // 异常哈希链表数组（异常哈希表，类似于hashmap1.8之前的实现）
    // 因为任务拆分之后会很多，异常信息要么都没有，要么都会出现
    // 所以不直接记录在ForkJoinTask对象中，而是采用哈希表结构存储弱引用类型的节点
    // 注意这些都是 static 类属性，所有的ForkJoinTask共用的
    private static final ExceptionNode[] exceptionTable;        
    private static final ReentrantLock exceptionTableLock;
    // 在ForkJoinTask的node被GC回收之后，相应的异常节点对象的引用队列
    private static final ReferenceQueue<Object> exceptionTableRefQueue; 

    /**
    * 固定容量的exceptionTable（代表数组长度为32，下标存储链表头节点）
    */
    private static final int EXCEPTION_MAP_CAPACITY = 32;

    // 内部节点类：异常数组存储的元素：
    //      数组是固定长度，这样方便外部访问
    //      但是为了保证内存可用性，所以是弱引用类型
    //      因为不能确定任务的最后一个join何时完成，所以在下次GC发生时会被回收
    //      在GC回收后，这些异常信息会被转存到exceptionTableRefQueue队列
    static final class ExceptionNode extends WeakReference<ForkJoinTask<?>> {
        final Throwable ex;
        ExceptionNode next;
        final long thrower;  // 抛出异常的线程id
        final int hashCode;  // 在弱引用消失之前存储hashCode
        ExceptionNode(ForkJoinTask<?> task, Throwable ex, ExceptionNode next) {
            // //在ForkJoinTask被GC回收之后，会将该节点加入队列exceptionTableRefQueue
            super(task, exceptionTableRefQueue); 
            this.ex = ex;
            this.next = next;
            this.thrower = Thread.currentThread().getId();
            this.hashCode = System.identityHashCode(task);
        }
    }

    /* 抽象方法：用于拓展 */
    // 任务执行完成后返回结果，未完成返回null
    public abstract V getRawResult();
    // 强制性的给定返回结果
    protected abstract void setRawResult(V value);
    // 执行任务
    // 如果执行过程抛出异常则记录捕获的异常并更改任务状态为EXCEPTIONAL
    // 如果执行正常结束，设置任务状态为NORMAL正常结束状态
    // 如果当前是子任务，设置为SIGNAL状态并通知其他需要join该任务的线程
    protected abstract boolean exec();
    
    /* 实现Future接口的方法 */
    // 阻塞等待任务执行结果
    public final V get();
    // 在给定时间内等待返回结果，超出给定时间则中断线程
    public final V get(long timeout, TimeUnit unit);
    // 阻塞非工作线程直至任务结束或者中断（该过程可能会发生窃取动作），返回任务的status值
    private int externalInterruptibleAwaitDone();
    // 尝试取消任务，成功返回true，反之false
    public boolean cancel(boolean mayInterruptIfRunning);
    // 判断任务是否已执行结束
    public final boolean isDone();
    // 判断任务是否被取消
    public final boolean isCancelled();
    
    
    /* 一些重要的方法 */
    // 执行任务的方法
    final int doExec();
    // 修改任务状态的方法
    private int setcompletion (int completion);
    // 取消任务的方法
    public boolean cancel(boolean mayInterruptIfRunning);
    
    
    // 将新创建的子任务放入当前线程的任务(工作)队列
    public final ForkJoinTask<V> fork();
    // 将当前线程阻塞，直到对应的子任务完成运行并返回执行结果
    public final V join();
    // 获取任务执行状态，如果还未结束，当前线程获取任务帮助执行
    private int doJoin();
    // 执行任务，正常结束则返回结果，异常结束则报告异常
    public final V invoke();
    // 使用当前线程执行任务
    private int doInvoke();
    // 阻塞线程直至任务执行结束，如果未执行完成，外部线程尝试帮助执行
    private int externalAwaitDone();
    // 同时执行两个任务，第一个任务由当前线程执行，第二个交由工作线程执行
    public static void invokeAll(ForkJoinTask<?> t1, ForkJoinTask<?> t2);
    // 执行多个任务，入参为任意个任务对象，除开第一个任务，其他交由工作线程执行
    public static void invokeAll(ForkJoinTask<?>... tasks);
    // 入参为Collection集合，可以支持返回结果
    public static <T extends ForkJoinTask<?>> 
        Collection<T> invokeAll(Collection<T> tasks);
    
    /* 异常相关的方法 */
    // 记录异常信息以及设置任务状态
    final int recordExceptionalCompletion(Throwable ex);
    // 删除异常结点并清理状态
    private void clearExceptionalCompletion();
    // 删除哈希表中过期的异常信息引用
    private static void expungeStaleExceptions();
    // 获取任务异常判断与当前线程堆栈关系是否相关，
    // 不相关则构建一个相同类型的异常，作为记录
    // 这样做的原因是为了提供准确的堆栈跟踪
    private Throwable getThrowableException();
}
复制代码
```

ForkJoinTask内部成员主要由两部分构成，一个是表示任务状态的int成员：status，其他的成员则都是跟任务异常信息记录相关的。不过值得注意一提的是：ForkJoinTask内部有关异常信息记录的成员都是static关键字修饰的，也就代表着这些成员是所有ForkJoinTask对象共享的，ForkJoinTask使用类似与HashMap的实现结构：固定长度32的数组+单向链表实现了一个哈希表结构，用于记录所有ForkJoinTask执行过程中出现的异常，所有异常信息都会被封装成ExceptionNode节点加入哈希表中存储，但是ExceptionNode节点是一种弱引用的实现，当程序下次GC发生时会被GC机制回收，GC时这些已捕获的异常则会被转移到exceptionTableRefQueue队列中存储。

而成员status代表任务的执行状态，成员类型为int，从最大程度上减少了内存占用，为了保证原子性，该成员使用了volatile修饰以及操作时都是CAS操作。而当任务未结束时，status都会大于0，任务执行结束后，status都会小于0。在ForkJoinTask也定义了如下几种状态：

- ①DONE_MASK状态：屏蔽非完成位标志，与NORMAL值相同，主要后续用于位运算判断任务是否正常执行结束 二进制值：1111 0000 0000 0000 0000 0000 0000 0000
- ②NORMAL状态：表示任务正常执行结束 二进制值：1111 0000 0000 0000 0000 0000 0000 0000
- ③CANCELLED状态：表示任务被取消 二进制值：1100 0000 0000 0000 0000 0000 0000 0000
- ④EXCEPTIONAL状态：表示任务执行过程中出现异常，导致任务执行终止结束 二进制值：1000 0000 0000 0000 0000 0000 0000 0000
- ⑤SIGNAL状态：表示传递信号状态，代表着当前任务存在依赖关系，执行结束后需要通知其他任务join合并结果 二进制值：0000 0000 0000 0001 0000 0000 0000 0000
- ⑥SMASK状态：低十六位的预留占位 二进制值：0000 0000 0000 0000 1111 1111 1111 1111
- PS：②③④⑤为任务状态，其他的只是辅助标识

而ForkJoinTask中的所有方法也可以分为三大类：

- ①基于status状态成员操作以及维护方法
- ②执行任务以及等待完成方法
- ③附加对外报告结果的用户级方法

重点来看一下fork()以及join()方法：

```
// ForkJoinTask类 → fork方法
public final ForkJoinTask<V> fork() {
    Thread t;
    // 判断当前执行的线程是否为池中的工作线程
    if ((t = Thread.currentThread()) instanceof ForkJoinWorkerThread)
        // 如果是的则直接将任务压入当前线程的任务队列
        ((ForkJoinWorkerThread)t).workQueue.push(this);
    else
        // 如果不是则压入common池中的某个工作线程的任务队列中
        ForkJoinPool.common.externalPush(this);
    // 返回当前ForkJoinTask对象，方便递归拆分
    return this;
}

// ForkJoinTask类 → join方法
public final V join() {
    int s;
    // 判断任务执行状态如果是非正常结束状态
    if ((s = doJoin() & DONE_MASK) != NORMAL)
        // 抛出相关的异常堆栈信息
        reportException(s);
    // 正常执行结束则返回执行结果
    return getRawResult();
}
// ForkJoinTask类 → doJoin方法
private int doJoin() {
    int s; Thread t; ForkJoinWorkerThread wt; ForkJoinPool.WorkQueue w;
    // status<0则直接返回status值
    return (s = status) < 0 ? s :
      // 判断当前线程是否为池中的工作线程
        ((t = Thread.currentThread()) instanceof ForkJoinWorkerThread) ?
        // 是则取出线程任务队列中的当前task执行，执行完成返回status值
        (w = (wt = (ForkJoinWorkerThread)t).workQueue).
        tryUnpush(this) && (s = doExec()) < 0 ? s :
        // 执行未完成则调用awaitJoin方法等待执行完成
        wt.pool.awaitJoin(w, this, 0L) :
      // 不是则调用externalAwaitDone()方法阻塞挂起当前线程
        externalAwaitDone();
}
复制代码
```

- **fork方法逻辑：** ①判断当前线程是否为池中的工作线程类型 是：将当前任务压入当前线程的任务队列中 不是：将当前任务压入common池中某个工作线程的任务队列中 ②返回当前的ForkJoinTask任务对象，方便递归拆分
- **doJoin&join方法逻辑：** ①判断任务状态status是否小于0： 小于：代表任务已经结束，返回status值 不小于：判断当前线程是否为池中的工作线程： 是：取出线程任务队列的当前task执行，判断执行是否结束： 结束：返回执行结束的status值 未结束：调用awaitJoin方法等待执行结束 不是：调用externalAwaitDone()方法阻塞挂起当前线程 ②判断任务执行状态是否为非正常结束状态，是则抛出异常堆栈信息 任务状态为被取消，抛出CancellationException异常 任务状态为异常结束，抛出对应的执行异常信息 ③如果status为正常结束状态，则直接返回执行结果

OK~，最后再看看ForkJoinTask的内部类：

```
static final class ExceptionNode extends 
        WeakReference<ForkJoinTask<?>> {}
        
static final class AdaptedRunnable<T> extends ForkJoinTask<T>
        implements RunnableFuture<T> {}

static final class AdaptedRunnableAction extends ForkJoinTask<Void>
        implements RunnableFuture<Void> {}
        
static final class RunnableExecuteAction extends ForkJoinTask<Void> {}

static final class AdaptedCallable<T> extends ForkJoinTask<T>
        implements RunnableFuture<T> {}
复制代码
```

- ①ExceptionNode：用于记录任务执行过程中抛出的异常信息，是ForkJoinTask的弱引用
- ②AdaptedRunnableAction：用于封装Runable类型任务的适配器，抽象方法实现： getRawResult()方法：直接返回null setRawResult()方法：空实现 exec()方法：直接调用的run()方法
- ③AdaptedCallable：用于封装Callable类型任务的适配器，抽象方法实现： getRawResult()方法：返回call方法的执行结果 setRawResult()方法：设置Callable执行后的返回值 exec()方法：调用的call()方法
- ④AdaptedRunnable：用于封装Runable类型任务的适配器，可以通过构造器设置返回集
- ⑤RunnableExecuteAction：同②类似，区别在于它可以抛出异常

# 2.2.3、ForkJoinPool：线程池

ForkJoinPool也是实现了ExecutorService的线程池，但ForkJoinPool不同于其他类型的线程池，因为其内部实现了工作窃取机制，所有线程在执行完自己的任务之后都会尝试窃取其他线程的任务执行，只有当窃取不到任务的情况下才会发生阻塞等待工作。ForkJoinPool主要是为了执行ForkJoinTask而存在的，ForkJoinPool是整个ForkJoin框架的核心，负责整个框架的核心管理、检查监控与资源调度。

# 2.2.3.1、ForkJoinPool构造器

先来看看ForkJoinPool的构造函数源码：

```
// 构造器1：使用默认的参数配置创建
public ForkJoinPool() {
    this(Math.min(MAX_CAP, Runtime.getRuntime().availableProcessors()),
         defaultForkJoinWorkerThreadFactory, null, false);
}
// 构造器2：可指定并行度
public ForkJoinPool(int parallelism) {
    this(parallelism, defaultForkJoinWorkerThreadFactory, null, false);
}
// 构造器3：可指定并行度、线程工厂、异常策略以及调度模式
public ForkJoinPool(int parallelism,
                    ForkJoinWorkerThreadFactory factory,
                    UncaughtExceptionHandler handler,
                    boolean asyncMode) {
    this(checkParallelism(parallelism),
         checkFactory(factory),
         handler,
         asyncMode ? FIFO_QUEUE : LIFO_QUEUE,
         "ForkJoinPool-" + nextPoolId() + "-worker-");
    checkPermission();
}
// 私有全参构造函数：提供给内部其他三个构造器调用
private ForkJoinPool(int parallelism,
                     ForkJoinWorkerThreadFactory factory,
                     UncaughtExceptionHandler handler,
                     int mode,
                     String workerNamePrefix) {
    this.workerNamePrefix = workerNamePrefix;
    this.factory = factory;
    this.ueh = handler;
    this.config = (parallelism & SMASK) | mode;
    long np = (long)(-parallelism); // offset ctl counts
    this.ctl = ((np << AC_SHIFT) & AC_MASK) | ((np << TC_SHIFT) & TC_MASK);
}
复制代码
```

ForkJoinPool对外提供了三个构造器，但是这三个构造器都是基于内部的私有构造完成的，所以直接分析最后一个全参的私有构造器，该构造器共有五个参数：

- ①parallelism并行度：默认为CPU核数，最小为1。相当于工作线程数，但会有些不同
- ②factory线程工厂：用于创建ForkJoinWorkerThread线程
- ③handler异常捕获策略：默认为null，执行任务出现异常从中被抛出时，就会被handler捕获
- ④mode调度模式：对应前三个构造中的asyncMode参数，默认为0，也就是false false：使用LIFO_QUEUE成员，mode=0，使用先进后出的模式调度工作 true：使用FIFO_QUEUE成员，mode=1<<16，使用先进先出的模式调度工作
- ⑤workerNamePrefix工作名称前缀：工作线程的名称前缀，有默认值，不需要传递该参数

创建ForkJoinPool线程池除开通过构造函数的方式之外，在JDK1.8中还提供了一个静态方法：commonPool()，该方法可以通过指定系统参数的方式（System.setProperty(?,?)）定义“并行度、线程工厂和异常处理策略”，但是该方法是一个静态方法，也就代表着通过该方法创建出来的线程池对象只会有一个，调用commonPool()方法获取到的ForkJoinPool对象是整个程序通用的。

# 2.2.3.2、ForkJoinPool内部成员

前面我们了解了ForkJoinPool的构造器，现在再简单看看它的成员构成：

```
// 线程池的ctl控制变量（与上篇中分析的ctl性质相同）
volatile long ctl;      
// 线程池的运行状态，值为常量中对应的值
volatile int runState;
// 将并行度和mode参数放到了一个int中，便于后续通过位操作计算
final int config;
// 随机种子，与SEED_INCREMENT魔数配合使用
int indexSeed;
// 组成WorkQueue数组，是线程池的核心数据结构
volatile WorkQueue[] workQueues;
// 创建线程的线程工厂
final ForkJoinWorkerThreadFactory factory;
// 任务在执行过程中出现抛出异常时的处理策略，类似于之前线程池的拒绝策略
final UncaughtExceptionHandler ueh;
// 创建线程时，线程名称的前缀
final String workerNamePrefix;
// 任务窃取的原子计数器
volatile AtomicLong stealCounter;

// 默认创建工作线程的工厂类
public static final ForkJoinWorkerThreadFactory
        defaultForkJoinWorkerThreadFactory;
// 线程修改许可，用于检测代码是否具备修改线程状态的权限
private static final RuntimePermission modifyThreadPermission;
// 通用的ForkJoinPool线程池，用于commonPool()方法
static final ForkJoinPool common;
// 通用线程池的并行数
static final int commonParallelism;
// 通用线程池的最大线程数
private static int commonMaxSpares;
// 用于记录已创建的ForkJoinPool线程池的个数
private static int poolNumberSequence;

// 当线程执行完成自己的任务且池中没有活跃线程时，用于计算阻塞时间，默认2s
private static final long IDLE_TIMEOUT = 2000L * 1000L * 1000L;
// 平衡计数，通过IDLE_TIMEOUT会减去TIMEOUT_SLOP，
// 主要为了平衡系统定时器唤醒时带来的延时时间，默认20ms
private static final long TIMEOUT_SLOP = 20L * 1000L * 1000L;
// 通用线程池默认的最大线程数 256
private static final int DEFAULT_COMMON_MAX_SPARES = 256;
/**
 * 自旋次数：阻塞之前旋转等待的次数，目前使用的是随机旋转
 * 在awaitRunStateLock、awaitWork以及awaitRunstateLock方法中使用，
 * 当前设置为零，以减少自旋带来的CPU开销
 * 如果大于零，则SPINS的值必须为2的幂，至少为 4
 */
private static final int SPINS  = 0;
// 这个是产生随机性的魔数，用于扫描的时候进行计算(与ThreadLocal类似)
private static final int SEED_INCREMENT = 0x9e3779b9;


// runState的状态：处于SHUTDOWN时值必须为负数，其他状态只要是2的次幂即可
// 锁定状态：线程池被某条线程获取了锁
private static final int  RSLOCK     = 1;
// 信号状态：线程阻塞前需要设置RSIGNAL，告诉其他线程在释放锁时要叫醒我
private static final int  RSIGNAL    = 1 << 1;
// 启动状态：表示线程池正常，可以创建线程且接受任务处理
private static final int  STARTED    = 1 << 2;
// 停止状态：线程池已停止，不能创建线程且不接受新任务，同时会取消未处理的任务
private static final int  STOP       = 1 << 29;
// 死亡状态：表示线程池内所有任务已取消，所有工作线程已销毁
private static final int  TERMINATED = 1 << 30;
// 关闭状态：尝试关闭线程池，不再接受新的任务，但依旧处理已接受的任务
private static final int  SHUTDOWN   = 1 << 31;


// CTL变量的一些掩码
// 低32位的掩码
private static final long SP_MASK    = 0xffffffffL;
// 高32位的掩码
private static final long UC_MASK    = ~SP_MASK;

// 有效（活跃/存活）计数：正在处理任务的活跃线程数
// 高16位的偏移量，用高16位记录活跃线程数
private static final int  AC_SHIFT   = 48;
// 高16位：活跃线程的计数单元，高16位+1
private static final long AC_UNIT    = 0x0001L << AC_SHIFT;
// 高16位：活跃线程数的掩码
private static final long AC_MASK    = 0xffffL << AC_SHIFT;

// 总计数：整个池中存在的所有线程数量
// 总线程数量的偏移量，使用高32位中的低16位记录
private static final int  TC_SHIFT   = 32;
// 总线程数的计数单元
private static final long TC_UNIT    = 0x0001L << TC_SHIFT;
// 总线程数的掩码
private static final long TC_MASK    = 0xffffL << TC_SHIFT;
// 最大总线程数的掩码，用于判断线程数量是否已达上限
private static final long ADD_WORKER = 0x0001L << (TC_SHIFT + 15); 


// 低16位掩码，表示workQueue在数组中的最大索引值
static final int SMASK        = 0xffff;
// 最大工作线程数
static final int MAX_CAP      = 0x7fff;
// 偶数掩码，第一个bit为0，任何值与它进行 与 计算，结果都为偶数
static final int EVENMASK     = 0xfffe;
// 用于计算偶数值下标，SQMASK值为126
// 0~126之间只存在64个偶数，所以偶数位的槽数只有64个
static final int SQMASK       = 0x007e;

// Masks and units for WorkQueue.scanState and ctl sp subfield
// 用于检测工作线程是否在执行任务的掩码
static final int SCANNING     = 1;
// 负数，用于workQueue.scanState，与scanState进行位或可将scanState变成负数，
// 表示工作线程扫描不到任务，进入不活跃状态，将可能被阻塞
static final int INACTIVE     = 1 << 31;
// 版本计数，用于workQueue.scanState，解决ABA问题
static final int SS_SEQ       = 1 << 16;

// Mode bits for ForkJoinPool.config and WorkQueue.config
// 获取队列的工作调度模式
static final int MODE_MASK    = 0xffff << 16;
// 表示先进后出模式
static final int LIFO_QUEUE   = 0;
// 表示先进先出模式
static final int FIFO_QUEUE   = 1 << 16;
// 表示共享模式
static final int SHARED_QUEUE = 1 << 31;


// Unsafe类对象：用于直接操作内存
private static final sun.misc.Unsafe U;
// ForkJoinTask[]数组的基准偏移量
// 使用这个值+元素的大小可以直接定位一个内存位置
private static final int  ABASE;
// ForkJoinTask[]数组两个元素之间的间距的幂 → log(间距) 底数为2
private static final int  ASHIFT;
// ctl成员的内存偏移量地址
private static final long CTL;
// runState成员的内存偏移量地址
private static final long RUNSTATE;
// stealCounter成员的内存偏移量地址
private static final long STEALCOUNTER;
// parkBlocker成员的内存偏移量地址
private static final long PARKBLOCKER;
// WorkQueue队列的top元素偏移量地址
private static final long QTOP;
// WorkQueue队列的qlock偏移量地址
private static final long QLOCK;
// WorkQueue队列的scanState偏移量地址
private static final long QSCANSTATE;
// WorkQueue队列的parker偏移量地址
private static final long QPARKER;
// WorkQueue队列的CurrentSteal偏移量地址
private static final long QCURRENTSTEAL;
// WorkQueue队列的CurrentJoin偏移量地址
private static final long QCURRENTJOIN;
复制代码
```

如上既是ForkJoinPool中的所有成员变量，总的可以分为四类：

- ①ForkJoinPool线程池运行过程中的成员结构
- ②通用线程池common以及所有线程池对象的默认配置
- ③线程池运行状态以及ctl成员的位存储记录
- ④直接操作内存的Unsafe相关成员及内存偏移量

具体的解释可以参考我源码中的注释，我们就挑重点说，先来说说核心成员：ctl，这个成员比较特殊，我估计DougLea在设计它的时候是抱着"一分钱掰成两份用"的心思写的，它是一个long类型的成员，占位8byte/64bit，是不是有些疑惑？用int类型不是更省内存嘛？如果你这样想，那你就错了。因为ctl不是只存储一个数据，而是同时记录四个，64Bit被拆分为四个16位的子字段，分别记录：

- ①1-16bit/AC：记录池中的活跃线程数
- ②17-32bit/TC：记录池中总线程数
- ③33-48bit/SS：记录WorkQueue状态，第一位表示active还是inactive，其余15位表示版本号(避免ABA问题)
- ④49-64bit/ID：记录第一个WorkQueue在数组中的下标，和其他worker通过字段stackPred组成的一个Treiber堆栈
- 低32位可以直接获取，如SP=(int)ctl，如果为负则代表存在空闲worker

ok~，了解了ctl成员之后，再来看看runState成员，它和线程池中的runState不同，它除开用于表示线程池的运行状态之外，同时也作为锁资源保护WorkQueues[]数组的更新。

# 2.2.3.3、ForkJoinPool内部类WorkQueue工作队列

WorkQueue是整个Fork/Join框架的桥接者，每个执行者ForkJoinWorkerThread对象中存在各自的工作队列，ForkJoinTask被存储在工作队列中，而ForkJoinPool使用一个WorkQueue数组管理协调所有执行者线程的队列。接着再看看WorkQueue工作队列的实现：

```
// 使用@Contended防止伪共享
@sun.misc.Contended
static final class WorkQueue {
    // 队列可存放任务数的初始容量：8192
    // 初始化时分配这么大容量的原因是为了减少哈希冲突导致的扩容
    static final int INITIAL_QUEUE_CAPACITY = 1 << 13;
    //  队列可存放任务数的最大容量
    static final int MAXIMUM_QUEUE_CAPACITY = 1 << 26; // 64M
    // 队列的扫描状态。高十六位用于版本计数，低16位用于记录扫描状态
    // 偶数位的WorkQueue，该值为负数时表示不活跃
    // 奇数位的WorkQueue，该值一般为workQueues数组中的下标值，表示当前线程在执行
    // 如果scanState为负数，代表线程没有找到任务执行，被挂起了，处于不活跃状态
    // 如果scanState是奇数，代表线程在寻找任务过程中，如果变成了偶数，代表线程在执行任务
    volatile int scanState;
    // 前一个栈顶的ctl值
    int stackPred;
    // 窃取任务的数量统计
    int nsteals;
    // 用于记录随机选择窃取任务，被窃取任务workQueue在数组中的下标值
    int hint;
    // 记录当前队列在数组中的下标和工作模式
    // 高十六位记录工作模式，低十六位记录数组下标
    int config;
    // 锁标识(类似于AQS是state锁标识) 
    // 为1表示队列被锁定，为0表示未锁定
    // 小于0代表当前队列注销或线程池关闭(terminate状态时为-1)
    volatile int qlock;
    // 下一个pool操作的索引值（栈底/队列头部）
    volatile int base;
    // 下一个push操作的索引值（栈顶/队列尾部）
    int top;
    // 存放任务的数组，初始化时不会分配空间，采用懒加载形式初始化空间
    ForkJoinTask<?>[] array;
    // 所属线程池的引用指向
    final ForkJoinPool pool;
    // 当前队列所属线程的引用，如果为外部提交任务的共享队列则为null
    final ForkJoinWorkerThread owner;
    // 线程在执行过程中如果被挂起阻塞，该成员保存被挂起的线程，否则为空
    volatile Thread parker;
    // 等待join合并的任务
    volatile ForkJoinTask<?> currentJoin;
    // 窃取过来的任务
    volatile ForkJoinTask<?> currentSteal;

    // 构造器
    WorkQueue(ForkJoinPool pool, ForkJoinWorkerThread owner) {
        this.pool = pool;
        this.owner = owner;
        // 开始的时候都指向栈顶
        base = top = INITIAL_QUEUE_CAPACITY >>> 1;
    }
    
    /* 重点方法 */
    // 添加方法：将一个任务添加进队列中
    // 注意：索引不是通过数组下标计算的，而是通过计算内存偏移量定位
    final void push(ForkJoinTask<?> task);
    // 扩容方法：队列元素数量达到容量时，扩容两倍并移动元素到新数组
    final ForkJoinTask<?>[] growArray();
    // 获取方法：从栈顶（LIFO）弹出一个任务
    final ForkJoinTask<?> pop();
    // 获取方法：从栈底（FIFO）弹出一个任务
    final ForkJoinTask<?> poll();
}
复制代码
```

WorkQueue内部采用一个数组存储所有分配的任务，线程执行时会从该队列中获取任务，如果数组为空，那么则会尝试窃取其他线程的任务。

至此，结合前面谈到的ForkJoinPool线程池的结构一同理解，在ForkJoinPool中存在一个由WorkQueue构成的数组成员workQueues，而在每个WorkQueue中又存在一个ForkJoinTask构成的数组成员array，所以Fork/Join框架中存储任务的结构如下：

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/c00575d612ec46c9afb62aa8d4ddd6a8~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669346388&x-signature=W2%2FkjiHHYufShslLV1m52y9Wt%2FA%3D)



- 重点： workQueues数组的容量必须为2的整次幂。下标为偶数的用于存储外部提交的任务，奇数位置存储内部fork出的子任务 偶数位置的任务属于共享任务，由工作线程竞争获取，模式为FIFO 奇数位置的任务属于某个工作线程，一般是fork产生的子任务 工作线程在处理完自身任务时会窃取其他线程的任务，窃取方式为FIFO 工作线程执行自己队列中任务的模式默认为LIFO（可以改成FIFO，不推荐）

> 关于
> ForkJoinWorkerThreadFactory线程工厂以及ManagedBlocker就不再阐述了

# 三、ForkJoin框架任务提交原理

在前面给出的ForkJoin使用案例中，我们使用invoke()方法将自己定义的任务提交给了ForkJoinPool线程池执行。前面曾提到过，提交任务的方式有三种：invoke()、execute()以及submit()，但它们三种方式的最终实现都大致相同，所以我们从invoke()方法开始，以它作为入口分析ForkJoin框架任务提交任务的原理实现。源码如下：

```
// ForkJoinPool类 → invoke()方法
public <T> T invoke(ForkJoinTask<T> task) {
    // 如果任务为空，抛出空指针异常
    if (task == null)
        throw new NullPointerException();
    // 如果不为空则提交任务执行
    externalPush(task);
    // 等待任务执行结果返回
    return task.join();
}

// ForkJoinPool类 → externalPush()方法
final void externalPush(ForkJoinTask<?> task) {
    WorkQueue[] ws; WorkQueue q; int m;
    // 获取线程的探针哈希值以及线程池运行状态
    int r = ThreadLocalRandom.getProbe();
    int rs = runState;
    // 判断线程池是否具备了任务提交的环境
    // 如果工作队列数组已经初始化
    //      并且数组以及数组中偶数位的工作队列不为空
    //      并且线程池状态正常
    //      并且获取队列锁成功
    // 满足条件则开始提交任务
    if ((ws = workQueues) != null && (m = (ws.length - 1)) >= 0 &&
        (q = ws[m & r & SQMASK]) != null && r != 0 && rs > 0 &&
        U.compareAndSwapInt(q, QLOCK, 0, 1)) {
        ForkJoinTask<?>[] a; int am, n, s;
        // 判断队列中的任务数组是否初始化并且数组是否还有空位
        if ((a = q.array) != null &&
            (am = a.length - 1) > (n = (s = q.top) - q.base)) {
            // 通过计算内存偏移量得到任务要被的存储索引
            int j = ((am & s) << ASHIFT) + ABASE;
            // 通过Unsafe类将任务写入到数组中
            U.putOrderedObject(a, j, task);
            U.putOrderedInt(q, QTOP, s + 1);
            U.putIntVolatile(q, QLOCK, 0);
            // 如果队列任务很多
            if (n <= 1)
                // 唤醒或者新启一条线程帮忙处理
                signalWork(ws, q);
            return;
        }
        // 释放队列锁
        U.compareAndSwapInt(q, QLOCK, 1, 0);
    }
    // 提交执行
    externalSubmit(task);
}

// ForkJoinPool类 → externalSubmit()方法
private void externalSubmit(ForkJoinTask<?> task) {
    int r; 
    // 如果当前提交任务的线程的探针哈希值为0，
    // 则初始化当前线程的探针哈希值
    if ((r = ThreadLocalRandom.getProbe()) == 0) {
        ThreadLocalRandom.localInit();
        r = ThreadLocalRandom.getProbe();
    }
    // 开启死循环直至成功提交任务为止
    for (;;) {
        WorkQueue[] ws; WorkQueue q; int rs, m, k;
        // 定义竞争标识
        boolean move = false;
        // 如果runState小于0代表为负数，代表线程池已经要关闭了
        if ((rs = runState) < 0) {
            // 尝试关闭线程池
            tryTerminate(false, false);     // help terminate
            // 线程池关闭后同时抛出异常
            throw new RejectedExecutionException();
        }
        // 如果线程池还未初始化，先对线程池进行初始化操作
        else if ((rs & STARTED) == 0 ||     // initialize
                 ((ws = workQueues) == null || (m = ws.length - 1) < 0)) {
            int ns = 0;
            // 获取池锁，没获取锁的线程则会自旋或者阻塞挂起
            rs = lockRunState();
            try {
                // 再次检测是否已初始化
                if ((rs & STARTED) == 0) {
                    U.compareAndSwapObject(this, STEALCOUNTER, null,
                                           new AtomicLong());
                    // 获取并行数
                    int p = config & SMASK; 
                    // 通过如下计算得到最接近2次幂的值
                    // 找到之后对该值 * 2倍
                    // 原理：将p中最高位的那个1以后的位都设置为1，
                    // 最后加1得到最接近的二次幂的值
                    int n = (p > 1) ? p - 1 : 1;
                    n |= n >>> 1; n |= n >>> 2;  n |= n >>> 4;
                    n |= n >>> 8; n |= n >>> 16; n = (n + 1) << 1;
                    workQueues = new WorkQueue[n];
                    ns = STARTED;
                }
            } finally {
                // 释放锁，并更改运行状态为STARTED
                unlockRunState(rs, (rs & ~RSLOCK) | ns);
            }
        }
        // r：随机值,m：工作队列的容量减1,SQMASK：偶数位最大的64个的掩码
        // r&m计算出了下标，位与SQMASK之后会变成一个<=126的偶数
        // 如果随机出来的偶数位下标位置队列不为空
        else if ((q = ws[k = r & m & SQMASK]) != null) {
            // 先获取队列锁
            if (q.qlock == 0 && U.compareAndSwapInt(q, QLOCK, 0, 1)) {
                // 获取队列的任务数组
                ForkJoinTask<?>[] a = q.array;
                // 记录队列原本的栈顶/队列尾部的数组下标
                int s = q.top;
                // 提交标识
                boolean submitted = false;
                try {
                    // 如果数组不为空并且数组中还有空位
                    // （a.length > s+1-q.base如果不成立则代表空位不足）
                    // 队列元素数量达到容量，没有空位时调用growArray进行扩容
                    if ((a != null && a.length > s + 1 - q.base) ||
                        (a = q.growArray()) != null) {
                        // 通过计算内存偏移量得到栈顶/队列尾部位置
                        int j = (((a.length - 1) & s) << ASHIFT) + ABASE;
                        // 将新的任务放在栈顶/队列尾部位置
                        U.putOrderedObject(a, j, task);
                        // 更新栈顶/队列尾部
                        U.putOrderedInt(q, QTOP, s + 1);
                        // 提交标识改为true
                        submitted = true;
                    }
                } finally {
                    // 释放队列锁
                    U.compareAndSwapInt(q, QLOCK, 1, 0);
                }
                // 如果任务已经提交到了工作队列
                if (submitted) {
                    // 创建新的线程处理，如果线程数已满，唤醒线程处理
                    signalWork(ws, q);
                    return;
                }
            }
            // 能执行到这里则代表前面没有获取到锁，该位置的队列有其他线程在操作
            // 将竞争标识改为true
            move = true;            
        }
        // 如果随机出来的偶数下标位置的队列为空
        // 那么则在该位置上新建工作队列，然后将任务放进去
        else if (((rs = runState) & RSLOCK) == 0) {
            // 新建一个工作队列，第二个参数是所属线程
            // 现在创建的第二个参数为null，因为偶数位的队列是共享的
            q = new WorkQueue(this, null);
            // 队列记录一下前面的随机值
            q.hint = r;
            // k是前面计算出的偶数位置索引，SHARED_QUEUE是共享队列模式
            // 使用高16位存储队列模式，低16位存储数组索引
            q.config = k | SHARED_QUEUE;
            // 扫描状态为失活状态（负数，因为共享队列
            // 不属于任何一个工作线程，它不需要标记工作线程状态）
            q.scanState = INACTIVE;
            // 获取池锁
            rs = lockRunState();
            // 将新创建的工作队列放入数组中
            if (rs > 0 &&  (ws = workQueues) != null &&
                k < ws.length && ws[k] == null)
                ws[k] = q;
            // 释放池锁
            unlockRunState(rs, rs & ~RSLOCK);
        }
        else
            move = true;
        // 如果计算出的偶数位置有其他线程在操作，为了减少竞争，
        // 获取下一个随机值，重新定位一个新的位置处理
        if (move)
            r = ThreadLocalRandom.advanceProbe(r);
    }
}
复制代码
```

源码如上，可以很明显的看到，流程比较长，总结一下核心，如下：

- ①判断任务是否为空，为空抛出异常，不为空则开始提交任务
- ②调用externalPush()方法尝试快速提交任务 快速提交条件：探针哈希值已初始化、池中队列数组已初始化、随机的偶数位置队列不为空、线程池已初始化并状态正常、能成功获取队列锁 如上条件全部成立则快速提交任务，提交成功直接返回，结束执行 如果不成立则调用externalSubmit()提交任务，流程如下述步骤
- ③初始化线程的探针哈希值并开启死循环提交任务(这个循环会直至提交成功才终止)
- ④检查线程池状态是否正常，如果状态为关闭状态则拒绝任务，抛出异常
- ⑤检查线程池是否已启动，如果还未启动则获取池锁，初始化线程池
- ⑥如果通过探针值+队列数组容量减一的值+掩码计算出的偶数位队列不为空： 尝试获取队列锁： 成功：将任务添加到计算出的偶数位队列的任务数组中，如过数组长度不够则先扩容，任务添加成功后新建或唤醒一条线程，然后返回 失败：代表有其他线程在操作这个偶数位置的队列，将move标识改为true
- ⑦如果计算出的偶数位置队列还未初始化，那么则先尝试获取池锁 成功：在该位置上创建一个共享队列，最后再释放池锁 失败：代表有其他线程也在操作池中的队列数组，将move标识改为true
- ⑧如果move竞争标识为true，代表本次操作存在线程竞争，为了减少竞争，重新获取一个新的探针哈希值，计算出一个新的偶数位进行操作
- ⑨当任务第一次执行没有添加成功时，会继续重复这些步骤，直至任务成功入列 第一次添加失败的情况： 队列存在其他线程操作没有获取到队列锁 计算出的偶数索引位的队列为空，第一次执行会先初始化队列
- ⑩任务成功提交到工作队列后，join等待任务执行完成，返回结果合并

> 对于上述步骤中提及到的一些名词解释：
> 探针哈希值：Thread类threadLocalRandomProbe成员的值，
> ThreadLocalRandom.getProbe()通过Unsafe计算当前线程的内存偏移量来获取
> 池锁：runState的RSLOCK状态，如果要对池中的队列数组进行操作则要先获取这个锁
> 队列锁：队列中的qlock成员，如果要对队列的任务数组进行操作则要先获取这个锁
> 偶数位队列：前面提到过，池中的队列数组workQueues下标为偶数的位置用来存储用户提交的任务，属于共享队列，不属于任何一条线程，里面的任务需要线程竞争获取

OK~，至此任务提交的流程分析完毕，关于execute()、submit()方法则不再分析，最终实现都是相同的，只是入口不同。最后再来个图理解一下：

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/eee44000305d4dd08fffe11a4a2a51a6~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669346388&x-signature=ixMnORKTkJlNBK7FpIBf%2BsYxLEU%3D)



# 四、ForkJoin框架任务工作原理

在前面的提交原理分析中可以得知，任务的执行都是通过调用signalWork()执行的，而这个方法会新创建一条线程处理任务，但当线程数量已经达到线程池的最大线程数时，则会尝试唤醒一条线程执行。下面则以signalWork()做为入口来分析ForkJoin框架任务工作原理，先来看看signalWork()源码：

```
// ForkJoinPool类 → signalWork()方法
final void signalWork(WorkQueue[] ws, WorkQueue q) {
    long c; int sp, i; WorkQueue v; Thread p;
    // ctl初始化时为负数，如果ctl<0则代表有任务需要处理
    while ((c = ctl) < 0L) {
        // sp==0代表不存在空闲的线程
        // 前面分析成员构成的时候提到过：
        //      低32位可以直接获取，如SP=(int)ctl，
        //      如果sp为负则代表存在空闲worker
        if ((sp = (int)c) == 0) {
            // 如果池中线程数量还未达到最大线程数
            if ((c & ADD_WORKER) != 0L)
                // 创建一条新的线程来处理工作
                tryAddWorker(c);
            // 新建线程完成后退出循环并返回
            break;
        }
        // 下面这三个判断都是在检测线程池状态是否正常
        // 因为signalWork只能框架内部调用，所以传入的队列不可能为空，
        // 除非是处于unstarted/terminated状态，代表线程池即将关闭，
        // 尝试中断未执行任务，直接清空了任务，所以此时直接中断执行
        if (ws == null)
            break;
        if (ws.length <= (i = sp & SMASK)) 
            break;
        if ((v = ws[i]) == null)
            break;
        // 下述代码是获取所有阻塞线程链中的top线程并唤醒它
        // 但是在唤醒之前需要先把top线程的stackPerd标识放在ctl中
        int vs = (sp + SS_SEQ) & ~INACTIVE;        // next scanState
        int d = sp - v.scanState;                  // screen CAS
        long nc = (UC_MASK & (c + AC_UNIT)) | (SP_MASK & v.stackPred);
        // 利用CAS机制修改ctl值
        if (d == 0 && U.compareAndSwapLong(this, CTL, c, nc)) {
            v.scanState = vs;
            if ((p = v.parker) != null)
                // 唤醒线程
                U.unpark(p);
            // 唤醒后退出
            break;
        }
        // 如果队列为空或者没有task，退出执行
        if (q != null && q.base == q.top)
            break;
    }
}
// ForkJoinPool类 → tryAddWorker()方法
private void tryAddWorker(long c) {
    // 定义新增标识
    boolean add = false;
    do {
        // 添加活跃线程数和总线程数
        long nc = ((AC_MASK & (c + AC_UNIT)) |
                   (TC_MASK & (c + TC_UNIT)));
        // 如果ctl值没有被其他线程修改
        if (ctl == c) {
            int rs, stop; 
            // 获取锁并检测线程池状态是否正常
            if ((stop = (rs = lockRunState()) & STOP) == 0)
                // 只有当线程池没有停止才可以创建线程
                add = U.compareAndSwapLong(this, CTL, c, nc);
            // 释放池锁
            unlockRunState(rs, rs & ~RSLOCK);
            // 如果线程池状态已经stop，那么则退出执行
            if (stop != 0)
                break;
            // 如果没有stop
            if (add) {
                // 则新建线程
                createWorker();
                // 退出
                break;
            }
        }
    // ADD_WORKER的第48位是1，和ctl位与运算是为了检查总线程是否已满
    // (int)c == 0代表池中不存在空闲线程数
    // 只有当总线程数未满时以及池中不存在空闲线程数才会创建线程
    } while (((c = ctl) & ADD_WORKER) != 0L && (int)c == 0);
}
复制代码
```

如上两个方法的逻辑比较简单：

- ①如果有任务需要处理并且池中目前不存在空闲线程并且池中线程还未满，调用tryAddWorker()方法尝试创建线程
- ②获取池锁更改ctl值并检测线程池的状态是否正常，正常则调用createWorker()创建线程
- ③ryAddWorker()是一个自旋方法，在池中线程数未满且没有出现空闲线程的情况下，会一直循环至成功创建线程或者池关闭
- ④如果池中存在空闲线程或者线程数已满，那么则会尝试唤醒阻塞链上的第一条线程

# 4.1、工作线程创建及注册原理

接着继续看看createWorker()方法：

```
// ForkJoinPool类 → createWorker()方法
private boolean createWorker() {
    // 获取池中的线程工厂
    ForkJoinWorkerThreadFactory fac = factory;
    Throwable ex = null;
    ForkJoinWorkerThread wt = null;
    try {
        // 通过线程工厂的newThread方法创建一条新线程
        if (fac != null && (wt = fac.newThread(this)) != null) {
            // 创建成功后返回true
            wt.start();
            return true;
        }
    } catch (Throwable rex) {
        // 如果出现异常则记录异常信息
        ex = rex;
    }
    // 然后注销线程以及将之前tryAddWorker()方法中修改的ctl值改回去
    deregisterWorker(wt, ex);
    return false;
}

// DefaultForkJoinWorkerThreadFactory类 → newThread()方法
public final ForkJoinWorkerThread newThread(ForkJoinPool pool) {
    // 直接创建了一条工作线程
    return new ForkJoinWorkerThread(pool);
}
复制代码
```

创建工作线程的源码比较简单，首先会获取池中采用的线程工厂，然后通过线程工厂创建一条ForkJoinWorkerThread工作线程。ok，再回到最开始的ForkJoin框架成员构成分析中的ForkJoinWorkerThread构造函数：

```
// ForkJoinWorkerThread类 → 构造函数
protected ForkJoinWorkerThread(ForkJoinPool pool) {
    // 调用Thread父类的构造函数创建线程实体对象
    // 在这里是先暂时使用aFJT作为线程名称，当外部传递线程名称时会替换
    super("aForkJoinWorkerThread");
    // 当前设置线程池
    this.pool = pool;
    // 向ForkJoinPool线程池中注册当前线程，为当前线程分配任务队列
    this.workQueue = pool.registerWorker(this);
}

// ForkJoinPool类 → registerWorker()方法
final WorkQueue registerWorker(ForkJoinWorkerThread wt) {
    // 异常策略
    UncaughtExceptionHandler handler;
    // 设置为守护线程
    wt.setDaemon(true);
    // 为创建的线程设置异常汇报策略
    if ((handler = ueh) != null)
        wt.setUncaughtExceptionHandler(handler);
    // 为创建的线程分配任务队列
    WorkQueue w = new WorkQueue(this, wt);
    int i = 0;   // 池中队列数组的索引
    int mode = config & MODE_MASK; // 获取队列模式
    int rs = lockRunState(); // 获取池锁
    try {
        WorkQueue[] ws; int n;   // skip if no array
        // 如果池中队列数组不为空并且已经初始化
        if ((ws = workQueues) != null && (n = ws.length) > 0) {
            // 获取用于计算数组下标随机的索引种子
            int s = indexSeed += SEED_INCREMENT;
            int m = n - 1; // 获取队列数组的最大索引值
            // 计算出一个奇数位索引
            // 与1位或，就是将第1个bit位设为1，此时这个数必然是奇数
            // 与m位与，为了保证得到的值是在m以内奇数下标值
            i = ((s << 1) | 1) & m; 
            // 如果计算出的位置不为空则代表已经有队列了，
            // 代表此时发生了碰撞冲突，那么此时则需要换个位置
            if (ws[i] != null) {
                int probes = 0;
                // 计算步长，步长是一个不能为2以及2次幂值的偶数
                // 为了保证计算出的值不为2的次幂值，会在最后进行+2操作
                // 后续会用原本的索引值+步长得到一个新的奇数索引值
                // 奇数+偶数=奇数，所以不需要担心会成为偶数位索引
                // 这里计算步长是通过长度n来计算的，
                // 因为步长大一些，避免冲突的概念就会小一些
                int step = (n <= 4) ? 2 : ((n >>> 1) & EVENMASK) + 2;
                // 如果新计算出的奇数位索引位置依旧不为空
                while (ws[i = (i + step) & m] != null) {
                    // 从下标0开始遍历整个数组
                    if (++probes >= n) {
                        // 如果所有奇数位值都不为空，代表数组满了，
                        // 那么扩容两倍，扩容后重新再遍历一次新数组
                        // 直至找出为空的奇数位下标
                        workQueues = ws = Arrays.copyOf(ws, n <<= 1);
                        m = n - 1;
                        probes = 0;
                    }
                }
            }
            // 记录这个随机出来的索引种子
            w.hint = s;          // use as random seed
            // 将前面计算得到的奇数位索引值以及工作模式记录在config
            w.config = i | mode;
            // 扫描状态队列在数组中的下标，为正数表示正在扫描任务状态
            w.scanState = i;    // publication fence
            // 将前面创建的队列放在队列数组的i位置上
            ws[i] = w;
        }
    } finally {
        // 释放池锁
        unlockRunState(rs, rs & ~RSLOCK);
    }
    // 在这里再设置线程的名称
    wt.setName(workerNamePrefix.concat(Integer.toString(i >>> 1)));
    return w;
}
复制代码
```

工作线程的创建与注册原理：

- ①将线程设置为守护线程，同时为新线程创建工作队列和设置异常处理策略
- ②尝试获取池锁成功后，先获取一个随机生成的用于计算数组下标的索引种子，然后通过种子和数组最大下标计算出一个奇数索引值
- ③如果计算出的奇数位值不为空，则通过偶数掩码+数组最大下标计算出一个偶数步长，然后通过这个步长循环整个数组找一个空的位置，如果找完了整个数组还是没有奇数空位，则对数组发生两倍扩容，然后再次依照步长遍历新数组找空位，直至找到奇数空位为止
- ④为队列设置hint、config、scanState值并将队列放到计算出的奇数位置上
- ⑤释放池锁并设置工作线程名字

> 工作线程注册的原理实则不难理解，难点在于计算奇数位索引有些玄妙，不理解的小伙伴可以看看下面这个案例：

```
// 模拟线程池中的队列数组和EVENMASK偶数掩码值
private static final int EVENMASK = 0xfffe;
private static Object[] ws = new Object[8];

public static void main(String[] args) {
    // 先将所有位置填满
    for (int i = 0; i < ws.length; i++) {
        ws[i] = new Object();
    }
    // 然后开始查找
    findOddNumberIdenx();
}

 private static void findOddNumberIdenx() {
    int n, m, i, probes;
    m = (n = ws.length) - 1;
    // 模拟第一次计算出的奇数位索引为3
    i = 3;
    probes = 0;
    int step = (n <= 4) ? 2 : ((n >>> 1) & EVENMASK) + 2;
    while (ws[i = (i + step) & m] != null) {
        System.out.println("查找奇数位：" + i);
        if (++probes >= n) {
            System.out.println("扩容两倍....");
            ws = Arrays.copyOf(ws, n <<= 1);
            m = n - 1;
            probes = 0;
        }
    }
     System.out.println("最终确定索引值：" + i);
}

/*
 运行结果：
    查找奇数位：1
    查找奇数位：7
    查找奇数位：5
    查找奇数位：3
    查找奇数位：1
    查找奇数位：7
    查找奇数位：5
    查找奇数位：3
    扩容两倍....
    最终确定索引值：9
*/
复制代码
```

# 4.2、工作线程注销原理

```
// ForkJoinPool类 → deregisterWorker()方法
final void deregisterWorker(ForkJoinWorkerThread wt, Throwable ex) {
    WorkQueue w = null;
    // 如果工作线程以及它的工作队列不为空
    if (wt != null && (w = wt.workQueue) != null) {
        WorkQueue[] ws;
        // 获取队列在池中数组的下标
        int idx = w.config & SMASK;
        // 获取池锁
        int rs = lockRunState();
        // 移除队列数组中idx位置的队列
        if ((ws = workQueues) != null && ws.length > idx && ws[idx] == w)
            ws[idx] = null;
        // 释放池锁
        unlockRunState(rs, rs & ~RSLOCK);
    }
    long c;
    // 在CTL成员中减去一个线程数
    do {} while (!U.compareAndSwapLong
                 (this, CTL, c = ctl, ((AC_MASK & (c - AC_UNIT)) |
                                       (TC_MASK & (c - TC_UNIT)) |
                                       (SP_MASK & c))));
    if (w != null) {
        // 标识这个队列已停止工作
        w.qlock = -1; 
        // 将当前工作队列的偷取任务数加到ForkJoinPool#stealCounter中
        w.transferStealCount(this);
        // 取消队列中剩余的任务
        w.cancelAll();
    }
    for (;;) {                                  
        WorkQueue[] ws; int m, sp;
        // 如果线程池是要关闭了，那么直接退出
        if (tryTerminate(false, false) || w == null || w.array == null ||
            (runState & STOP) != 0 || (ws = workQueues) == null ||
            (m = ws.length - 1) < 0)    
            break;
        // 如果线程池不是要关闭，那么先通过ctl看看有没有阻塞的线程
        if ((sp = (int)(c = ctl)) != 0) {  
            // 如果有则唤醒它来代替被销毁的线程工作
            if (tryRelease(c, ws[sp & m], AC_UNIT))
                break;
        }
        // 如果池中不存在阻塞挂起的线程，则先判断池内线程是否已满
        else if (ex != null && (c & ADD_WORKER) != 0L) {
            // 如果没满则新建一条线程代替被销毁的线程工作
            tryAddWorker(c);                  
            break;
        }
        // 如果池运行正常，不存在线程阻塞，线程数已满
        else
            // 那么直接退出
            break;
    }
    if (ex == null) 
        // 清理异常哈希表中当前线程的异常节点信息
        ForkJoinTask.helpExpungeStaleExceptions();
    else
        // 抛出异常
        ForkJoinTask.rethrow(ex);
}
复制代码
```

线程注销的逻辑相对比较简单，如下：

- ①获取池锁之后将工作线程的任务队列从数组中移除，移除后释放池锁
- ②将偷窃的任务数加到stealCounter成员，然后取消自身队列中的所有任务
- ③判断当前线程池的情况，判断当前销毁线程是否是因为线程池要关闭了： 如果是：直接退出 如果不是：再判断池中是否存在挂起阻塞的线程 存在：唤醒阻塞线程来代替被销毁的线程工作 不存在：判断池中线程是否已满 没满：新建一条线程代替被销毁的线程工作 满了：直接退出
- ④清除异常哈希表中当前线程的异常节点信息，然后抛出异常

总的来说，在销毁线程时，会先注销已注册的工作队列，注销之后会根据情况选择唤醒或新建一条线程来补偿线程池。

