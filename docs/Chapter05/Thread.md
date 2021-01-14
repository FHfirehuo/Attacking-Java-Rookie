# 线程




#### 一个异常 Thread starvation or clock leap detected
```text
2018-05-27 13:56:50.820  WARN 111644 --- [      Thread-49] c.g.htmlunit.IncorrectnessListenerImpl   : Obsolete content type encountered: 'text/javascript'.
2018-05-27 13:58:26.957  WARN 111644 --- [l-1 housekeeper] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Thread starvation or clock leap detected (housekeeper delta=51s792ms365µs576ns).
2018-05-27 14:02:55.861  WARN 111644 --- [l-1 housekeeper] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Thread starvation or clock leap detected (housekeeper delta=1m33s765ms258µs244ns).
2018-05-27 14:08:47.880  WARN 111644 --- [l-1 housekeeper] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Thread starvation or clock leap detected (housekeeper delta=6m53s824ms351µs439ns).
2018-05-27 14:17:02.136  WARN 111644 --- [l-1 housekeeper] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Thread starvation or clock leap detected (housekeeper delta=8m17s388ms195µs302ns).
```


This runs on the housekeeper thread, which executes every 30 seconds. If you are on Mac OS X, the clockSource is System.currentTimeMillis(), any other platform the clockSource is System.nanoTime(). Both in theory are monotonically increasing, but various things can affect that such as NTP servers. Most OSes are designed to handle backward NTP time adjustments to preserve the illusion of the forward flow of time.

This code is saying, if time moves backwards (now < previous), or if time has "jumped forward" more than two housekeeping periods (more than 60 seconds), then something strange is likely going on.

A couple of things might be going on:

You could be running in a virtual container (VMWare, AWS, etc.) that for some reason is doing a particularly poor job of maintaining the illusion of the forward flow of time.

Because other things occur in the housekeeper thread -- specifically, closing idle connections -- it is possible that for some reason closing connections is blocking the housekeeper thread for more than two housekeeping periods (60 seconds).

The server is so busy, with all CPUs pegged, that thread starvation is occurring, which is preventing the housekeeper thread from running for more than two housekeeping periods.

Considering these, maybe you can provide additional context.

EDIT: Note that this is based on HikariCP 2.4.1 code. Make sure you are running the most up-to-date version available.


###### 翻译如下：

这在管家线程上运行，该线程每30秒执行一次。如果在Mac OS X上，clockSource是System.currentTimeMillis（），则任何其他平台上的clockSource是System.nanoTime（）。从理论上讲，两者都在单调增加，但是诸如NTP服务器之类的各种因素都可能影响到这一点。大多数操作系统旨在处理向后NTP时间调整，以保留对时间的前向错觉的幻想。

这段代码说的是，如果时间倒退（现在<以前），或者如果时间“跳跃”了两个以上的内务处理周期（超过60秒），那么可能会发生一些奇怪的事情。

可能发生了几件事情：

您可能正在某个虚拟容器（VMWare，AWS等）中运行，由于某种原因，该容器在维持时间上的错觉方面做得特别差。

由于管家线程中发生了其他事情-特别是关闭空闲连接-出于某种原因，关闭连接可能会阻塞管家线程两个以上的维护周期（60秒）。

服务器太忙了，所有CPU都挂了，导致线程出现饥饿，这导致管家线程无法运行两个以上的管家周期。

考虑到这些，也许您可​​以提供其他上下文。

编辑：请注意，这是基于HikariCP 2.4.1代码的。确保您正在运行最新的可用版本。


### Java同一个线程对象能否多次调用start方法

#### 下面看下start方法源码：

```
/**线程成员变量，默认为0，volatile修饰可以保证线程间可见性*/
private volatile int threadStatus = 0;
/* 当前线程所属的线程组 */
private ThreadGroup group;
/**
 * 同步方法，同一时间，只能有一个线程可以调用此方法
 */
public synchronized void start() {
    //threadStatus
    if (threadStatus != 0)
        throw new IllegalThreadStateException();
    //线程组
    group.add(this);
    boolean started = false;
    try {
        //本地方法，该方法会实际调用run方法
        start0();
        started = true;
    } finally {
        try {
            if (!started) {
                //创建失败，则从线程组中删除该线程
                group.threadStartFailed(this);
            }
        } catch (Throwable ignore) {
            /* start0抛出的异常不用处理，将会在堆栈中传递 */
        }
    }
}

```

1. 通过断点跟踪，可以看到当线程对象第一次调用start方法时会进入同步方法，会判断threadStatus是否为0，如果为0，则进行往下走，否则抛出非法状态异常；
2. 将当前线程对象加入线程组；
3. 调用本地方法start0执行真正的创建线程工作，并调用run方法，可以看到在start0执行完后，threadStatus的值发生了改变，不再为0；
4. finally块用于捕捉start0方法调用发生的异常。

继续回到原话题，当start调用后，并且run方法内容执行完后，线程是如何终止的呢？实际上是由虚拟机调用Thread中的exit方法来进行资源清理并终止线程的，看下exit方法源码：

```
/**
 * 系统调用该方法用于在线程实际退出之前释放资源
 */
private void exit() {
    //释放线程组资源
    if (group != null) {
        group.threadTerminated(this);
        group = null;
    }
    //清理run方法实例对象
    target = null;
    /*加速资源释放。快速垃圾回收 */
    threadLocals = null;
    inheritableThreadLocals = null;
    inheritedAccessControlContext = null;
    blocker = null;
    uncaughtExceptionHandler = null;
}

```

1. 到这里，t1 线程经历了从新建（NEW），就绪（RUNNABLE），运行（RUNNING），定时等待（TIMED_WAITING），终止（TERMINATED）这样一个过程；
2, 由于在第一次 start 方法后，threadStatus 值被改变，因此第二次调用start时会抛出非法状态异常；
3. 在调用start0方法后，如果run方法体内容被快速执行完，那么系统会自动调用exit方法释放资源，销毁对象，所以第二次调用start方法时，有可能内部资源已经被释放。

> 初步结论：同一个线程对象不可以多次调用 start 方法。

#### 通过反射修改threadStatus来多次执行start方法

```
public static void main(String[] args) throws Exception {
    //创建一个线程t1
    Thread t1 = new Thread(() -> {
        try {
            //睡眠10秒，防止run方法执行过快，
            //触发exit方法导致线程组被销毁
            TimeUnit.SECONDS.sleep(10);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    });

    //第一次启动
    t1.start();

    //修改threadStatus，重新设置为0，即 NEW 状态
    Field threadStatus = t1.getClass().getDeclaredField("threadStatus");
    threadStatus.setAccessible(true);
    //重新将线程状态设置为0，新建（NEW）状态
    threadStatus.set(t1, 0);

    //第二次启动
    t1.start();
}

```

截取start后半截源码：

```
boolean started = false;
try {
    //第二次执行start0会抛异常，这时started仍然为false
    start0();
    started = true;
} finally {
    try {
        if (!started) {
            //创建失败，则从线程组中删除该线程
            group.threadStartFailed(this);
        }
    } catch (Throwable ignore) {
        /* start0抛出的异常不用处理，将会在堆栈中传递 */
    }
}

```

1. 在上面代码中，在第一次调用start方法后，我通过反射修改threadStatus值，这样在第二次调用时可以跳过状态值判断语句，达到多次调用start方法；
2. 当我第二次调用t1.start时，需要设置run方法运行时间长一点，防止系统调用exit方法清理线程资源；
3. 经过以上两步，我成功绕开 threadStatus 判断和线程组增加方法，开始执行start0方法，但是在执行start0的时候抛出异常，并走到了finally块中，由于start为false，所以会执行group.threadStartFailed(this)操作，将该线程从线程组中移除；
4. 所以start0中还是会对当前线程状态进行了一个判断，不允许重复创建线程。

> 最后结论：无论是直接二次调用还是通过反射二次调用，同一个线程对象都无法多次调用start方法，仅可调用一次。
