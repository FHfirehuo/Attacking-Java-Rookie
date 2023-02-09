# 线程池

## 使用线程池可以带来以下好处：

> 降低资源消耗。降低频繁创建、销毁线程带来的额外开销，复用已创建线程
>
> 降低使用复杂度。将任务的提交和执行进行解耦，我们只需要创建一个线程池，然后往里面提交任务就行，具体执行流程由线程池自己管理，降低使用复杂度
>
> 提高线程可管理性。能安全有效的管理线程资源，避免不加限制无限申请造成资源耗尽风险
>
> 提高响应速度。任务到达后，直接复用已创建好的线程执行

线程池的使用场景简单来说可以有：

> **快速响应用户请求，响应速度优先**。比如一个用户请求，需要通过 RPC 调用好几个服务去获取数据然后聚合返回，此场景就可以用线程池并行调用，响应时间取决于响应最慢的那个 RPC 接口的耗时；又或者一个注册请求，注册完之后要发送短信、邮件通知，为了快速返回给用户，可以将该通知操作丢到线程池里异步去执行，然后直接返回客户端成功，提高用户体验。
>
> **单位时间处理更多请求，吞吐量优先**。比如接受 MQ 消息，然后去调用第三方接口查询数据，此场景并不追求快速响应，主要利用有限的资源在单位时间内尽可能多的处理任务，可以利用队列进行任务的缓冲。

基于以上使用场景，可以套到自己项目中，说下为了提升系统性能，自己对负责的系统模块使用线程池做了哪些优化，优化前后对比 Qps 提升多少、Rt 降低多少、服务器数量减少多少等等。

## 线程池的核心参数和执行过程

```
 // 用此变量保存当前池状态（高3位）和当前线程数（低29位）
  private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
```

execute()方法执行逻辑如下：

```
public void execute(Runnable command) {
    if (command == null)
        throw new NullPointerException();
    int c = ctl.get();
    if (workerCountOf(c) < corePoolSize) {
        if (addWorker(command, true))
            return;
        c = ctl.get();
    }
    if (isRunning(c) && workQueue.offer(command)) {
        int recheck = ctl.get();
        if (! isRunning(recheck) && remove(command))
            reject(command);
        else if (workerCountOf(recheck) == 0)
            addWorker(null, false);
    }
    else if (!addWorker(command, false))
        reject(command);
}
```

可以总结出如下主要执行流程，当然看上述代码会有一些异常分支判断，可以自己梳理加到下述执行主流程里

> 判断线程池的状态，如果不是RUNNING状态，直接执行拒绝策略
>
> 如果当前线程数 < 核心线程池，则新建一个线程来处理提交的任务
>
> 如果当前线程数 > 核心线程数且任务队列没满，则将任务放入阻塞队列等待执行
>
> 如果 核心线程池 < 当前线程池数 < 最大线程数，且任务队列已满，则创建新的线程执行提交的任务
>
> 如果当前线程数 > 最大线程数，且队列已满，则执行拒绝策略拒绝该任务



##  Worker 继承 AQS 实现了锁机制，那 ThreadPoolExecutor 都用到了哪些锁？为什么要用锁？

1）mainLock 锁

ThreadPoolExecutor 内部维护了 ReentrantLock 类型锁 mainLock，在访问 workers 成员变量以及进行相关数据统计记账（比如访问 largestPoolSize、completedTaskCount）时需要获取该重入锁。

面试官：为什么要有 mainLock？

```
    private final ReentrantLock mainLock = new ReentrantLock();

    /**
     * Set containing all worker threads in pool. Accessed only when
     * holding mainLock.
     */
    private final HashSet<Worker> workers = new HashSet<Worker>();

    /**
     * Tracks largest attained pool size. Accessed only under
     * mainLock.
     */
    private int largestPoolSize;

    /**
     * Counter for completed tasks. Updated only on termination of
     * worker threads. Accessed only under mainLock.
     */
    private long completedTaskCount;
```

可以看到 workers 变量用的 HashSet 是线程不安全的，是不能用于多线程环境的。largestPoolSize、completedTaskCount 也是没用 volatile 修饰，所以需要在锁的保护下进行访问。

面试官：为什么不直接用个线程安全容器呢？

其实 Doug 老爷子在 mainLock 变量的注释上解释了，意思就是说事实证明，相比于线程安全容器，此处更适合用 lock，主要原因之一就是串行化 interruptIdleWorkers() 方法，避免了不必要的中断风暴。

面试官：怎么理解这个中断风暴呢？

其实简单理解就是如果不加锁，interruptIdleWorkers() 方法在多线程访问下就会发生这种情况。一个线程调用interruptIdleWorkers() 方法对 Worker 进行中断，此时该 Worker 出于中断中状态，此时又来一个线程去中断正在中断中的 Worker 线程，这就是所谓的中断风暴。

面试官：那 largestPoolSize、completedTaskCount 变量加个 volatile 关键字修饰是不是就可以不用 mainLock 了？

这个其实 Doug 老爷子也考虑到了，其他一些内部变量能用 volatile 的都加了 volatile 修饰了，这两个没加主要就是为了保证这两个参数的准确性，在获取这两个值时，能保证获取到的一定是修改方法执行完成后的值。如果不加锁，可能在修改方法还没执行完成时，此时来获取该值，获取到的就是修改前的值，然后修改方法一提交，就会造成获取到的数据不准确了。

2）Worker 线程锁

刚也说了 Worker 线程继承 AQS，实现了 Runnable 接口，内部持有一个 Thread 变量，一个 firstTask，及 completedTasks 三个成员变量。

基于 AQS 的 acquire()、tryAcquire() 实现了 lock()、tryLock() 方法，类上也有注释，**该锁主要是用来维护运行中线程的中断状态**。在 runWorker() 方法中以及刚说的 interruptIdleWorkers() 方法中用到了。

面试官：这个维护运行中线程的中断状态怎么理解呢？

```
  protected boolean tryAcquire(int unused) {
      if (compareAndSetState(0, 1)) {
          setExclusiveOwnerThread(Thread.currentThread());
          return true;
      }
      return false;
  }
  public void lock()        { acquire(1); }
  public boolean tryLock()  { return tryAcquire(1); }
```

在runWorker() 方法中获取到任务开始执行前，需要先调用 w.lock() 方法，lock() 方法会调用 tryAcquire() 方法，tryAcquire() 实现了一把非重入锁，通过 CAS 实现加锁。

```
     protected boolean tryAcquire(int unused) {
          if (compareAndSetState(0, 1)) {
              setExclusiveOwnerThread(Thread.currentThread());
              return true;
          }
          return false;
      }
```

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/429788fa5cac49d9b71b9389d3bd44a6~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669343526&x-signature=HnHCN3CCkHrcEcrFMXU0FJqAxAE%3D)



interruptIdleWorkers() 方法会中断那些等待获取任务的线程，会调用 w.tryLock() 方法来加锁，如果一个线程已经在执行任务中，那么 tryLock() 就获取锁失败，就保证了不能中断运行中的线程了。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/35391530a780409cb9e9d969fa0fd711~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669343526&x-signature=ywNVDhIQGPx7JMv0ISTzS8Q15Ew%3D)



## 如何使用线程池

我们一般都是在 Spring 环境中使用线程池的，直接使用 JUC 原生 ThreadPoolExecutor 有个问题，Spring 容器关闭的时候可能任务队列里的任务还没处理完，有丢失任务的风险。

我们知道 Spring 中的 Bean 是有生命周期的，如果 Bean 实现了 Spring 相应的生命周期接口（InitializingBean、DisposableBean接口），在 Bean 初始化、容器关闭的时候会调用相应的方法来做相应处理。

所以最好不要直接使用 ThreadPoolExecutor 在 Spring 环境中，**可以使用 Spring 提供的 ThreadPoolTaskExecutor，或者 DynamicTp 框架提供的 DtpExecutor 线程池实现。**

也会按业务类型进行线程池隔离，各任务执行互不影响，避免共享一个线程池，任务执行参差不齐，相互影响，高耗时任务会占满线程池资源，导致低耗时任务没机会执行；同时如果任务之间存在父子关系，可能会导致死锁的发生，进而引发 OOM。

## execute() 提交任务和 submit() 提交任务有啥不同？

# 以面试官视角万字解读线程池10大经典面试题

2022-10-29 10:11·[Java架构嘻嘻嘻](https://www.toutiao.com/c/user/token/MS4wLjABAAAAcXucK7QXH4cYu5NDoOBiR3xsoaKCPNVK0BgcQvtMTiIo3l5lfu1WKsw2iHZ8BpZ7/?source=tuwen_detail)

大家好，这篇文章主要跟大家聊下 Java 线程池面试中可能会问到的一些问题。

**全程干货，耐心看完，相信你能轻松应对各种线程池面试问题，同时也能让你对线程池有更深一步的了解。**

相信各位 Javaer 在面试中或多或少肯定被问到过线程池相关问题吧，线程池是一个相对比较复杂的体系，基于此可以问出各种各样、五花八门的问题。

若你很熟悉线程池，如果可以，完全可以滔滔不绝跟面试官扯一个小时线程池，一般面试也就一个小时左右，那么这样留给面试官问其他问题的时间就很少了，或者其他问题可能问的也就不深入了，那你通过面试的几率是不就更大点了呢。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/c8cdfcda379747449acfca4b1cc4fb16~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669343526&x-signature=R7EFeZfhdsjkoWSwRxd2S0Vs%2FLQ%3D)



下面我们开始列下线程池面试可能会被问到的问题以及该怎么回答，以下只是参考答案，你可以加入自己的理解。

# 1. 面试官：日常工作中有用到线程池吗？什么是线程池？为什么要使用线程池？

一般面试官考察你线程池相关知识前，大概率会先问这个问题，如果你说没用过，不了解，ok，那就没以下问题啥事了，估计你的面试结果肯定也凶多吉少了。

作为 JUC 包下的门面担当，线程池是名副其实的 JUC 一哥，不了解线程池，那说明你对 JUC 包其他工具也了解的不咋样吧，对 JUC 没深入研究过，那就是没掌握到 Java 的精髓，给面试官这样一个印象，那结果可想而知了。

所以说，这一分一定要吃下，那我们应该怎么回答好这问题呢？

**可以这样说：**

计算机发展到现在，摩尔定律在现有工艺水平下已经遇到难易突破的物理瓶颈，通过多核 CPU 并行计算来提升服务器的性能已经成为主流，随之出现了多线程技术。

线程作为操作系统宝贵的资源，对它的使用需要进行控制管理，线程池就是采用池化思想（类似连接池、常量池、对象池等）管理线程的工具。

JUC 给我们提供了 ThreadPoolExecutor 体系类来帮助我们更方便的管理线程、并行执行任务。

下图是 Java 线程池继承体系：

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/8f4dc6d6811241d7bf9a9b12762edd47~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669343526&x-signature=lGb898FASP%2B1GuDGAw1fUm8iLdM%3D)



顶级接口Executor提供了一种方式，解耦任务的提交和执行，只定义了一个 execute(Runnable command) 方法用来提交任务，至于具体任务怎么执行则交给他的实现者去自定义实现。

ExecutorService 接口继承 Executor，且扩展了生命周期管理的方法、返回 Futrue 的方法、批量提交任务的方法。

AbstractExecutorService 抽象类继承 ExecutorService 接口，对 ExecutorService 相关方法提供了默认实现，用 RunnableFuture 的实现类 FutureTask 包装 Runnable 任务，交给 execute() 方法执行，然后可以从该 FutureTask 阻塞获取执行结果，并且对批量任务的提交做了编排。

ThreadPoolExecutor 继承 AbstractExecutorService，采用池化思想管理一定数量的线程来调度执行提交的任务，且定义了一套线程池的生命周期状态，用一个 ctl 变量来同时保存当前池状态（高3位）和当前池线程数（低29位）。看过源码的小伙伴会发现，ThreadPoolExecutor 类里的方法大量有同时需要获取或更新池状态和池当前线程数的场景，放一个原子变量里，可以很好的保证数据的一致性以及代码的简洁性，说到 ctl 了，可以顺便讲下几个状态之间的流转过程。

```
  // 用此变量保存当前池状态（高3位）和当前线程数（低29位）
  private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0)); 
  private static final int COUNT_BITS = Integer.SIZE - 3;
  private static final int CAPACITY   = (1 << COUNT_BITS) - 1;

  // runState is stored in the high-order bits
  // 可以接受新任务提交，也会处理任务队列中的任务
  // 结果：111跟29个0：111 00000000000000000000000000000
  private static final int RUNNING    = -1 << COUNT_BITS;
  
  // 不接受新任务提交，但会处理任务队列中的任务
  // 结果：000 00000000000000000000000000000
  private static final int SHUTDOWN   =  0 << COUNT_BITS;
  
  // 不接受新任务，不执行队列中的任务，且会中断正在执行的任务
  // 结果：001 00000000000000000000000000000
  private static final int STOP       =  1 << COUNT_BITS;
  
  // 任务队列为空，workerCount = 0，线程池的状态在转换为TIDYING状态时，会执行钩子方法terminated()
  // 结果：010 00000000000000000000000000000
  private static final int TIDYING    =  2 << COUNT_BITS;
  
  // 调用terminated()钩子方法后进入TERMINATED状态
  // 结果：010 00000000000000000000000000000
  private static final int TERMINATED =  3 << COUNT_BITS;

  // Packing and unpacking ctl
  // 低29位变为0，得到了线程池的状态
  private static int runStateOf(int c)     { return c & ~CAPACITY; }
  // 高3位变为为0，得到了线程池中的线程数
  private static int workerCountOf(int c)  { return c & CAPACITY; }
  private static int ctlOf(int rs, int wc) { return rs | wc; }
```

使用线程池可以带来以下好处：

> 降低资源消耗。降低频繁创建、销毁线程带来的额外开销，复用已创建线程
>
> 降低使用复杂度。将任务的提交和执行进行解耦，我们只需要创建一个线程池，然后往里面提交任务就行，具体执行流程由线程池自己管理，降低使用复杂度
>
> 提高线程可管理性。能安全有效的管理线程资源，避免不加限制无限申请造成资源耗尽风险
>
> 提高响应速度。任务到达后，直接复用已创建好的线程执行

线程池的使用场景简单来说可以有：

> **快速响应用户请求，响应速度优先**。比如一个用户请求，需要通过 RPC 调用好几个服务去获取数据然后聚合返回，此场景就可以用线程池并行调用，响应时间取决于响应最慢的那个 RPC 接口的耗时；又或者一个注册请求，注册完之后要发送短信、邮件通知，为了快速返回给用户，可以将该通知操作丢到线程池里异步去执行，然后直接返回客户端成功，提高用户体验。
>
> **单位时间处理更多请求，吞吐量优先**。比如接受 MQ 消息，然后去调用第三方接口查询数据，此场景并不追求快速响应，主要利用有限的资源在单位时间内尽可能多的处理任务，可以利用队列进行任务的缓冲。

基于以上使用场景，可以套到自己项目中，说下为了提升系统性能，自己对负责的系统模块使用线程池做了哪些优化，优化前后对比 Qps 提升多少、Rt 降低多少、服务器数量减少多少等等。

# 2. 面试官：ThreadPoolExecutor 都有哪些核心参数？

其实一般面试官问你这个问题并不是简单听你说那几个参数，更多的是想听你描述下线程池执行流程。

**青铜回答：**

包含核心线程数（corePoolSize）、最大线程数（maximumPoolSize），空闲线程超时时间（keepAliveTime）、时间单位（unit）、阻塞队列（workQueue）、拒绝策略（handler）、线程工厂（ThreadFactory）这7个参数。

这个回答基本上也没毛病，但只能 60 分飘过。

**钻石回答：**

回答完包含这几个参数之后，会再主动描述下线程池的执行流程，也就是 execute() 方法执行流程。

execute()方法执行逻辑如下：

```
public void execute(Runnable command) {
    if (command == null)
        throw new NullPointerException();
    int c = ctl.get();
    if (workerCountOf(c) < corePoolSize) {
        if (addWorker(command, true))
            return;
        c = ctl.get();
    }
    if (isRunning(c) && workQueue.offer(command)) {
        int recheck = ctl.get();
        if (! isRunning(recheck) && remove(command))
            reject(command);
        else if (workerCountOf(recheck) == 0)
            addWorker(null, false);
    }
    else if (!addWorker(command, false))
        reject(command);
}
```

可以总结出如下主要执行流程，当然看上述代码会有一些异常分支判断，可以自己梳理加到下述执行主流程里

> 判断线程池的状态，如果不是RUNNING状态，直接执行拒绝策略
>
> 如果当前线程数 < 核心线程池，则新建一个线程来处理提交的任务
>
> 如果当前线程数 > 核心线程数且任务队列没满，则将任务放入阻塞队列等待执行
>
> 如果 核心线程池 < 当前线程池数 < 最大线程数，且任务队列已满，则创建新的线程执行提交的任务
>
> 如果当前线程数 > 最大线程数，且队列已满，则执行拒绝策略拒绝该任务

这个回答就比较能体现出你的悟性，能主动描述线程池执行流程，说明你对线程池还是比较了解的，在面试官心里就会留下还行的印象，这也是你要面高级 Java 必须要达到的最低要求，这个回答拿个 75 分应该问题不大。

**王者回答：**

在回答完包含哪些参数及 execute 方法的执行流程后。然后可以说下这个执行流程是 JUC 标准线程池提供的执行流程，主要用在 CPU 密集型场景下。

像 Tomcat、Dubbo 这类框架，他们内部的线程池主要用来处理网络 IO 任务的，所以他们都对 JUC 线程池的执行流程进行了调整来支持 IO 密集型场景使用。

他们提供了阻塞队列 TaskQueue，该队列继承 LinkedBlockingQueue，重写了 offer() 方法来实现执行流程的调整。

```
 @Override
    public boolean offer(Runnable o) {
        //we can't do any checks
        if (parent==null) return super.offer(o);
        //we are maxed out on threads, simply queue the object
        if (parent.getPoolSize() == parent.getMaximumPoolSize()) return super.offer(o);
        //we have idle threads, just add it to the queue
        if (parent.getSubmittedCount()<=(parent.getPoolSize())) return super.offer(o);
        //if we have less threads than maximum force creation of a new thread
        if (parent.getPoolSize()<parent.getMaximumPoolSize()) return false;
        //if we reached here, we need to add it to the queue
        return super.offer(o);
    }
```

可以看到他在入队之前做了几个判断，这里的 parent 就是所属的线程池对象

> 1.如果 parent 为 null，直接调用父类 offer 方法入队
>
> 2.如果当前线程数等于最大线程数，则直接调用父类 offer()方法入队
>
> 3.如果当前未执行的任务数量小于等于当前线程数，仔细思考下，是不是说明有空闲的线程呢，那么直接调用父类 offer() 入队后就马上有线程去执行它
>
> 4.如果当前线程数小于最大线程数量，则直接返回 false，然后回到 JUC 线程池的执行流程回想下，是不是就去添加新线程去执行任务了呢
>
> 5.其他情况都直接入队

具体可以看之前写过的这篇文章

动态线程池（DynamicTp）之动态调整Tomcat、Jetty、Undertow线程池参数篇

可以看出当当前线程数大于核心线程数时，JUC 原生线程池首先是把任务放到队列里等待执行，而不是先创建线程执行。

如果 Tomcat 接收的请求数量大于核心线程数，请求就会被放到队列中，等待核心线程处理，如果并发量很大，就会在队列里堆积大量任务，这样会降低请求的总体响应速度。

所以 Tomcat并没有使用 JUC 原生线程池，利用 TaskQueue 的 offer() 方法巧妙的修改了 JUC 线程池的执行流程，改写后 Tomcat 线程池执行流程如下：

> 判断如果当前线程数小于核心线程池，则新建一个线程来处理提交的任务
>
> 如果当前当前线程池数大于核心线程池，小于最大线程数，则创建新的线程执行提交的任务
>
> 如果当前线程数等于最大线程数，则将任务放入任务队列等待执行
>
> 如果队列已满，则执行拒绝策略

而且 Tomcat 会做核心线程预热，在创建好线程池后接着会去创建核心线程并启动，服务启动后就可以直接接受客户端请求进行处理了，避免了冷启动问题。

然后再说下线程池的 Worker 线程模型，继承 AQS 实现了锁机制。线程启动后执行 runWorker() 方法，runWorker() 方法中调用 getTask() 方法从阻塞队列中获取任务，获取到任务后先执行 beforeExecute() 钩子函数，再执行任务，然后再执行 afterExecute() 钩子函数。若超时获取不到任务会调用 processWorkerExit() 方法执行 Worker 线程的清理工作。

相信这一通回答后，拿个 90 分应该问题不大了。

runworker()、getTask()、addWorker() 等源码解读可以看之前写的文章：

线程池源码解析

# 3. 面试官：你刚也说到了 Worker 继承 AQS 实现了锁机制，那 ThreadPoolExecutor 都用到了哪些锁？为什么要用锁？

这个问题比较刁钻，一般准备过程中可能不太会注意，那下面我们来一起看下用到了那些锁。



1）mainLock 锁

ThreadPoolExecutor 内部维护了 ReentrantLock 类型锁 mainLock，在访问 workers 成员变量以及进行相关数据统计记账（比如访问 largestPoolSize、completedTaskCount）时需要获取该重入锁。

面试官：为什么要有 mainLock？

```
    private final ReentrantLock mainLock = new ReentrantLock();

    /**
     * Set containing all worker threads in pool. Accessed only when
     * holding mainLock.
     */
    private final HashSet<Worker> workers = new HashSet<Worker>();

    /**
     * Tracks largest attained pool size. Accessed only under
     * mainLock.
     */
    private int largestPoolSize;

    /**
     * Counter for completed tasks. Updated only on termination of
     * worker threads. Accessed only under mainLock.
     */
    private long completedTaskCount;
```

可以看到 workers 变量用的 HashSet 是线程不安全的，是不能用于多线程环境的。largestPoolSize、completedTaskCount 也是没用 volatile 修饰，所以需要在锁的保护下进行访问。

面试官：为什么不直接用个线程安全容器呢？

其实 Doug 老爷子在 mainLock 变量的注释上解释了，意思就是说事实证明，相比于线程安全容器，此处更适合用 lock，主要原因之一就是串行化 interruptIdleWorkers() 方法，避免了不必要的中断风暴。

面试官：怎么理解这个中断风暴呢？

其实简单理解就是如果不加锁，interruptIdleWorkers() 方法在多线程访问下就会发生这种情况。一个线程调用interruptIdleWorkers() 方法对 Worker 进行中断，此时该 Worker 出于中断中状态，此时又来一个线程去中断正在中断中的 Worker 线程，这就是所谓的中断风暴。

面试官：那 largestPoolSize、completedTaskCount 变量加个 volatile 关键字修饰是不是就可以不用 mainLock 了？

这个其实 Doug 老爷子也考虑到了，其他一些内部变量能用 volatile 的都加了 volatile 修饰了，这两个没加主要就是为了保证这两个参数的准确性，在获取这两个值时，能保证获取到的一定是修改方法执行完成后的值。如果不加锁，可能在修改方法还没执行完成时，此时来获取该值，获取到的就是修改前的值，然后修改方法一提交，就会造成获取到的数据不准确了。

2）Worker 线程锁

刚也说了 Worker 线程继承 AQS，实现了 Runnable 接口，内部持有一个 Thread 变量，一个 firstTask，及 completedTasks 三个成员变量。

基于 AQS 的 acquire()、tryAcquire() 实现了 lock()、tryLock() 方法，类上也有注释，**该锁主要是用来维护运行中线程的中断状态**。在 runWorker() 方法中以及刚说的 interruptIdleWorkers() 方法中用到了。

面试官：这个维护运行中线程的中断状态怎么理解呢？

```
  protected boolean tryAcquire(int unused) {
      if (compareAndSetState(0, 1)) {
          setExclusiveOwnerThread(Thread.currentThread());
          return true;
      }
      return false;
  }
  public void lock()        { acquire(1); }
  public boolean tryLock()  { return tryAcquire(1); }
```

在runWorker() 方法中获取到任务开始执行前，需要先调用 w.lock() 方法，lock() 方法会调用 tryAcquire() 方法，tryAcquire() 实现了一把非重入锁，通过 CAS 实现加锁。

```
     protected boolean tryAcquire(int unused) {
          if (compareAndSetState(0, 1)) {
              setExclusiveOwnerThread(Thread.currentThread());
              return true;
          }
          return false;
      }
```

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/429788fa5cac49d9b71b9389d3bd44a6~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669343526&x-signature=HnHCN3CCkHrcEcrFMXU0FJqAxAE%3D)



interruptIdleWorkers() 方法会中断那些等待获取任务的线程，会调用 w.tryLock() 方法来加锁，如果一个线程已经在执行任务中，那么 tryLock() 就获取锁失败，就保证了不能中断运行中的线程了。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/35391530a780409cb9e9d969fa0fd711~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669343526&x-signature=ywNVDhIQGPx7JMv0ISTzS8Q15Ew%3D)



**重点：所以 Worker 继承 AQS 主要就是为了实现了一把非重入锁，维护线程的中断状态，保证不能中断运行中的线程。**

# 4. 面试官：你在项目中是怎样使用线程池的？Executors 了解吗？

这里面试官主要想知道你日常工作中使用线程池的姿势，现在大多数公司都在遵循阿里巴巴 Java 开发规范，该规范里明确说明不允许使用 Executors 创建线程池，而是通过 ThreadPoolExecutor 显示指定参数去创建。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/932396ac3bcf49dc87599e8518ae2df7~noop.image?_iz=58558&from=article.pc_detail&x-expires=1669343526&x-signature=wF3kS5CPSdGVy6JmL6TwccRSsDs%3D)



你可以这样说，知道 Executors 工具类，很久之前有用过，也踩过坑，Executors 创建的线程池有发生 OOM 的风险。

Executors.newFixedThreadPool 和 Executors.SingleThreadPool 创建的线程池内部使用的是无界（Integer.MAX_VALUE）的 LinkedBlockingQueue 队列，可能会堆积大量请求，导致 OOM。

Executors.newCachedThreadPool 和 Executors.scheduledThreadPool 创建的线程池最大线程数是用的Integer.MAX_VALUE，可能会创建大量线程，导致 OOM。

自己在日常工作中也有封装类似的工具类，但是都是内存安全的，参数需要自己指定适当的值，也有基于 LinkedBlockingQueue 实现了内存安全阻塞队列 MemorySafeLinkedBlockingQueue，当系统内存达到设置的最大剩余阈值时，就不在往队列里添加任务了，避免发生 OOM。

```
public static ThreadPoolExecutor newFixedThreadPool(String threadPrefix, int poolSize, int queueCapacity) {
        return ThreadPoolBuilder.newBuilder()
                .corePoolSize(poolSize)
                .maximumPoolSize(poolSize)
                .workQueue(QueueTypeEnum.MEMORY_SAFE_LINKED_BLOCKING_QUEUE.getName(), queueCapacity, null)
                .threadFactory(threadPrefix)
                .buildDynamic();
    }

    public static ExecutorService newCachedThreadPool(String threadPrefix, int maximumPoolSize) {
        return ThreadPoolBuilder.newBuilder()
                .corePoolSize(0)
                .maximumPoolSize(maximumPoolSize)
                .workQueue(QueueTypeEnum.SYNCHRONOUS_QUEUE.getName(), null, null)
                .threadFactory(threadPrefix)
                .buildDynamic();
    }

    public static ThreadPoolExecutor newThreadPool(String threadPrefix, int corePoolSize,
                                                   int maximumPoolSize, int queueCapacity) {
        return ThreadPoolBuilder.newBuilder()
                .corePoolSize(corePoolSize)
                .maximumPoolSize(maximumPoolSize)
                .workQueue(QueueTypeEnum.MEMORY_SAFE_LINKED_BLOCKING_QUEUE.getName(), queueCapacity, null)
                .threadFactory(threadPrefix)
                .buildDynamic();
    }
```

我们一般都是在 Spring 环境中使用线程池的，直接使用 JUC 原生 ThreadPoolExecutor 有个问题，Spring 容器关闭的时候可能任务队列里的任务还没处理完，有丢失任务的风险。

我们知道 Spring 中的 Bean 是有生命周期的，如果 Bean 实现了 Spring 相应的生命周期接口（InitializingBean、DisposableBean接口），在 Bean 初始化、容器关闭的时候会调用相应的方法来做相应处理。

所以最好不要直接使用 ThreadPoolExecutor 在 Spring 环境中，**可以使用 Spring 提供的 ThreadPoolTaskExecutor，或者 DynamicTp 框架提供的 DtpExecutor 线程池实现。**

也会按业务类型进行线程池隔离，各任务执行互不影响，避免共享一个线程池，任务执行参差不齐，相互影响，高耗时任务会占满线程池资源，导致低耗时任务没机会执行；同时如果任务之间存在父子关系，可能会导致死锁的发生，进而引发 OOM。

使用线程池的常规操作是通过 @Bean 定义多个业务隔离的线程池实例。我们是参考美团线程池实践那篇文章做了一个动态可监控线程池的轮子，而且利用了 Spring 的一些特性，将线程池实例都配置在配置中心里，服务启动的时候会从配置中心拉取配置然后生成 BeanDefination 注册到 Spring 容器中，在 Spring 容器刷新时会生成线程池实例注册到 Spring 容器中。这样我们业务代码就不用显式用 @Bean 声明线程池了，可以直接通过依赖注入的方式使用线程池，而且也可以动态调整线程池的参数了。

更多使用姿势参考之前发的文章：

线程池，我是谁？我在哪儿？

# 5. 面试官：刚你说到了通过 ThreadPoolExecutor 来创建线程池，那核心参数设置多少合适呢？

这个问题该怎么回答呢？

可能很多人都看到过《Java 并发编程实践》这本书里介绍的一个线程数计算公式：

Ncpu = CPU 核数

Ucpu = 目标 CPU 利用率，0 <= Ucpu <= 1

W / C = 等待时间 / 计算时间

要程序跑到 CPU 的目标利用率，需要的线程数为：

Nthreads = Ncpu * Ucpu * (1 + W / C)

这公式太偏理论化了，很难实际落地下来，首先很难获取准确的等待时间和计算时间。再着一个服务中会运行着很多线程，比如 Tomcat 有自己的线程池、Dubbo 有自己的线程池、GC 也有自己的后台线程，我们引入的各种框架、中间件都有可能有自己的工作线程，这些线程都会占用 CPU 资源，所以通过此公式计算出来的误差一定很大。

所以说怎么确定线程池大小呢？

**其实没有固定答案，需要通过压测不断的动态调整线程池参数，观察 CPU 利用率、系统负载、GC、内存、RT、吞吐量等各种综合指标数据，来找到一个相对比较合理的值。**

**所以不要再问设置多少线程合适了，这个问题没有标准答案，需要结合业务场景，设置一系列数据指标，排除可能的干扰因素，注意链路依赖（比如连接池限制、三方接口限流），然后通过不断动态调整线程数，测试找到一个相对合适的值。**

# 6. 面试官：你们线程池是咋监控的？

因为线程池的运行相对而言是个黑盒，它的运行我们感知不到，该问题主要考察怎么感知线程池的运行情况。

可以这样回答：

我们自己对线程池 ThreadPoolExecutor 做了一些增强，做了一个线程池管理框架。主要功能有监控告警、动态调参。主要利用了 ThreadPoolExecutor 类提供的一些 set、get方法以及一些钩子函数。

动态调参是基于配置中心实现的，核心参数配置在配置中心，可以随时调整、实时生效，利用了线程池提供的 set 方法。

监控，主要就是利用线程池提供的一些 get 方法来获取一些指标数据，然后采集数据上报到监控系统进行大盘展示。也提供了 Endpoint 实时查看线程池指标数据。

同时定义了5中告警规则。

> 线程池活跃度告警。活跃度 = activeCount / maximumPoolSize，当活跃度达到配置的阈值时，会进行事前告警。
>
> 队列容量告警。容量使用率 = queueSize / queueCapacity，当队列容量达到配置的阈值时，会进行事前告警。
>
> 拒绝策略告警。当触发拒绝策略时，会进行告警。
>
> 任务执行超时告警。重写 ThreadPoolExecutor 的 afterExecute() 和 beforeExecute()，根据当前时间和开始时间的差值算出任务执行时长，超过配置的阈值会触发告警。
>
> 任务排队超时告警。重写 ThreadPoolExecutor 的 beforeExecute()，记录提交任务时时间，根据当前时间和提交时间的差值算出任务排队时长，超过配置的阈值会触发告警

通过监控 + 告警可以让我们及时感知到我们业务线程池的执行负载情况，第一时间做出调整，防止事故的发生。

# 7. 面试官：execute() 提交任务和 submit() 提交任务有啥不同？

看到这个问题，是不是大多数人都觉得这个我行。execute() 无返回值，submit() 有返回值，会返回一个 FutureTask，然后可以调用 get() 方法阻塞获取返回值。

这样回答只能算及格，其实面试官问你这个问题主要想听你讲下 FutureTask 的实现原理，FutureTask 继承体系如下：

我们调用 submit() 方法提交的任务（Runnable or Callable）会被包装成 FutureTask() 对象。FutureTask 类提供了 7 种任务状态和五个成员变量。

```
    /*
     * Possible state transitions:
     * NEW -> COMPLETING -> NORMAL
     * NEW -> COMPLETING -> EXCEPTIONAL
     * NEW -> CANCELLED
     * NEW -> INTERRUPTING -> INTERRUPTED
     */
    // 构造函数中 state 置为 NEW，初始态
    private static final int NEW          = 0;
    // 瞬时态，表示完成中
    private static final int COMPLETING   = 1;
    // 正常执行结束后的状态
    private static final int NORMAL       = 2;
    // 异常执行结束后的状态
    private static final int EXCEPTIONAL  = 3;
    // 调用 cancel 方法成功执行后的状态
    private static final int CANCELLED    = 4;
    // 瞬时态，中断中
    private static final int INTERRUPTING = 5;
    // 正常执行中断后的状态
    private static final int INTERRUPTED  = 6;

    // 任务状态，以上 7 种
    private volatile int state;
    /** 通过 submit() 提交的任务，执行完后置为 null*/
    private Callable<V> callable;
    /** 任务执行结果或者调用 get() 要抛出的异常*/
    private Object outcome; // non-volatile, protected by state reads/writes
    /** 执行任务的线程，会在 run() 方法中通过 cas 赋值*/
    private volatile Thread runner;
    /** 调用get()后由等待线程组成的无锁并发栈，通过 cas 实现无锁*/
    private volatile WaitNode waiters;
```

创建 FutureTask 对象时 state 置为 NEW，callable 赋值为我们传入的任务。

run() 方法中会去执行 callable 任务。执行之前先判断任务处于 NEW 状态并且通过 cas 设置 runner 为当前线程成功。然后去调用 call() 执行任务，执行成功后会调用 set() 方法将结果赋值给 outcome，任务执行抛出异常后会将异常信息调用 setException() 赋值给 outcome。至于为什么要先将状态变为 COMPLETING，再变为 NORMAL，主要是为了保证在 NORMAL 态时已经完成了 outcome 赋值。finishCompletion() 会去唤醒（通过 LockSupport.unpark()）那些因调用 get() 而阻塞的线程（waiters）。

```
    protected void set(V v) {
        if (UNSAFE.compareAndSwapInt(this, stateOffset, NEW, COMPLETING)) {
            outcome = v;
            UNSAFE.putOrderedInt(this, stateOffset, NORMAL); // final state
            finishCompletion();
        }
    }
```

调用 get() 方法会阻塞获取结果（或异常），如果 state > COMPLETING，说明任务已经执行完成（NORMAL、EXCEPTIONAL、CANCELLED、INTERRUPTED），则直接通过 report() 方法返回结果或抛出异常。如果state <= COMPLETING，说明任务还在执行中或还没开始执行，则调用 awaitDone() 方法进行阻塞等待。

```
    public V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException {
        if (unit == null)
            throw new NullPointerException();
        int s = state;
        if (s <= COMPLETING &&
            (s = awaitDone(true, unit.toNanos(timeout))) <= COMPLETING)
            throw new TimeoutException();
        return report(s);
    }
```

awaitDone() 方法则通过 state 状态判断来决定直接返回还是将当前线程添加到 waiters 里，然后调用LockSupport.park() 方法挂起当前线程。

还有个重要的 cancel() 方法，因为 FutureTask 源码类注释的第一句就说了 FutureTask 是一个可取消的异步计算。代码也非常简单，如果 state 不是 NEW 或者通过 CAS 赋值为 INTERRUPTING / CANCELLED 失败则直接返回。反之如果 mayInterruptIfRunning = ture，表示可能中断在运行中线程，则中断线程，state 变为 INTERRUPTED，最后去唤醒等待的线程。

```
    public boolean cancel(boolean mayInterruptIfRunning) {
        if (!(state == NEW &&
              UNSAFE.compareAndSwapInt(this, stateOffset, NEW,
                  mayInterruptIfRunning ? INTERRUPTING : CANCELLED)))
            return false;
        try {    // in case call to interrupt throws exception
            if (mayInterruptIfRunning) {
                try {
                    Thread t = runner;
                    if (t != null)
                        t.interrupt();
                } finally { // final state
                    UNSAFE.putOrderedInt(this, stateOffset, INTERRUPTED);
                }
            }
        } finally {
            finishCompletion();
        }
        return true;
    }
```

以上简单介绍了下 FutureTask 的执行流程，篇幅有限，源码解读的不是很仔细，后面可以考虑单独出一篇文章好好分析下 FutureTask 的源码。



## 什么是阻塞队列？阻塞队列有哪些？

阻塞队列 BlockingQueue 继承 Queue，是我们熟悉的基本数据结构队列的一种特殊类型。

当从阻塞队列中获取数据时，如果队列为空，则等待直到队列有元素存入。当向阻塞队列中存入元素时，如果队列已满，则等待直到队列中有元素被移除。提供 offer()、put()、take()、poll() 等常用方法。

JDK 提供的阻塞队列的实现有以下前 7 种：

1）ArrayBlockingQueue：由数组实现的有界阻塞队列，该队列按照 FIFO 对元素进行排序。维护两个整形变量，标识队列头尾在数组中的位置，在生产者放入和消费者获取数据共用一个锁对象，意味着两者无法真正的并行运行，性能较低。

2）LinkedBlockingQueue：由链表组成的有界阻塞队列，如果不指定大小，默认使用 Integer.MAX_VALUE 作为队列大小，该队列按照 FIFO 对元素进行排序，对生产者和消费者分别维护了独立的锁来控制数据同步，意味着该队列有着更高的并发性能。

3）SynchronousQueue：不存储元素的阻塞队列，无容量，可以设置公平或非公平模式，插入操作必须等待获取操作移除元素，反之亦然。

4）PriorityBlockingQueue：支持优先级排序的无界阻塞队列，默认情况下根据自然序排序，也可以指定 Comparator。

5）DelayQueue：支持延时获取元素的无界阻塞队列，创建元素时可以指定多久之后才能从队列中获取元素，常用于缓存系统或定时任务调度系统。

6）LinkedTransferQueue：一个由链表结构组成的无界阻塞队列，与LinkedBlockingQueue相比多了transfer和tryTranfer方法，该方法在有消费者等待接收元素时会立即将元素传递给消费者。

7）LinkedBlockingDeque：一个由链表结构组成的双端阻塞队列，可以从队列的两端插入和删除元素。



## 线程池是怎样实现复用线程的

线程池复用线程的逻辑很简单，就是在线程启动后，通过while死循环，不断从阻塞队列中拉取任务，从而达到了复用线程的目的。

具体源码如下：

```
// 线程执行入口
public void run() {
    runWorker(this);
}

// 线程运行核心方法
final void runWorker(Worker w) {
    Thread wt = Thread.currentThread();
    Runnable task = w.firstTask;
    w.firstTask = null;
    w.unlock();
    boolean completedAbruptly = true;
    try {
        // 1. 使用while死循环，不断从阻塞队列中拉取任务
        while (task != null || (task = getTask()) != null) {
            // 加锁，保证thread不被其他线程中断（除非线程池被中断）
            w.lock();
            // 2. 校验线程池状态，是否需要中断当前线程
            if ((runStateAtLeast(ctl.get(), STOP) ||
                    (Thread.interrupted() &&
                            runStateAtLeast(ctl.get(), STOP))) &&
                    !wt.isInterrupted())
                wt.interrupt();
            try {
                beforeExecute(wt, task);
                Throwable thrown = null;
                try {
                    // 3. 执行run方法
                    task.run();
                } catch (RuntimeException x) {
                    thrown = x;
                    throw x;
                } catch (Error x) {
                    thrown = x;
                    throw x;
                } catch (Throwable x) {
                    thrown = x;
                    throw new Error(x);
                } finally {
                    afterExecute(task, thrown);
                }
            } finally {
                task = null;
                w.completedTasks++;
                w.unlock();
            }
        }
        completedAbruptly = false;
    } finally {
        processWorkerExit(w, completedAbruptly);
    }
}
```

runWorker方法逻辑很简单，就是不断从阻塞队列中拉取任务并执行。



## 线程池是怎么统计线程的空闲时间的

这个我知道，线程池统计线程的空闲时间的实现逻辑很简单。

阻塞队列（BlockingQueue）提供了一个**poll(time, unit)**方法用来拉取数据， **作用就是：** 当队列为空时，会阻塞指定时间，然后返回null。

线程池就是就是利用阻塞队列的这个方法，如果在指定时间内拉取不到任务，就表示该线程的存活时间已经超过阈值了，就要被回收了。

**具体源码如下：**

```
// 从阻塞队列中拉取任务
private Runnable getTask() {
    boolean timedOut = false;
    for (; ; ) {
        int c = ctl.get();
        int rs = runStateOf(c);
        // 1. 如果线程池已经停了，或者阻塞队列是空，就回收当前线程
        if (rs >= SHUTDOWN && (rs >= STOP || workQueue.isEmpty())) {
            decrementWorkerCount();
            return null;
        }
        int wc = workerCountOf(c);
        // 2. 再次判断是否需要回收线程
        boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;
        if ((wc > maximumPoolSize || (timed && timedOut))
                && (wc > 1 || workQueue.isEmpty())) {
            if (compareAndDecrementWorkerCount(c))
                return null;
            continue;
        }
        try {
            // 3. 在指定时间内，从阻塞队列中拉取任务
            Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
                    workQueue.take();
            if (r != null)
                return r;
            // 4. 如果没有拉取到任务，就标识该线程已超时，然后就被回收
            timedOut = true;
        } catch (InterruptedException retry) {
            timedOut = false;
        }
    }
}
```



## 线程池抛异常了，也没有try/catch，会发生什么

线程池中的代码如果抛异常了，也没有try/catch，会从线程池中删除这个异常线程，并创建一个新线程。

