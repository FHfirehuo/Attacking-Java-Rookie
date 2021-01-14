# Condition 源码分析

它是一个用来多线程的协调通信的工具类，当某个线程阻塞等待某个条件时，当满足条件才会被唤醒。

```

public interface Condition {

    void await() throws InterruptedException;
    void awaitUninterruptibly();
    boolean await(long time, TimeUnit unit) throws InterruptedException;
    void signal();

    ....
}
```

两个重要方法，await()和signal()。

它的实现在 AbstractQueuedSynchronizer （也就是我们平时说的aqs）和  AbstractQueuedLongSynchronizer中

#### await

调用此方法会使得线程进入等待队列并释放锁，线程的状态变成等待状态

```
        public final void await() throws InterruptedException {
 //允许线程中断
            if (Thread.interrupted())
                throw new InterruptedException();
 //创建一个状态为condition的节点，采用链表的形式存放数据
            Node node = addConditionWaiter();
//释放当前的锁，得到锁的状态，释放等待队列中的一个线程
            int savedState = fullyRelease(node);
            int interruptMode = 0;
    //判断当前节点是或否在队列上
            while (!isOnSyncQueue(node)) {
 //挂起当前线程
                LockSupport.park(this);
                if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)
                    break;
            }
//acquireQueued为false就拿到了锁
    //interruptMode != THROW_IE表示这个线程没有成功将 node 入队,但 signal 执行了 enq 方法让其入队了
            if (acquireQueued(node, savedState) && interruptMode != THROW_IE)
  //将这个变量设置成 REINTERRUPT
                interruptMode = REINTERRUPT;
            if (node.nextWaiter != null) // clean up if cancelled
  //如果node节点的下一个等待者不为空，则开始进行清理，清理condition节点 
                unlinkCancelledWaiters();
            if (interruptMode != 0)
 //如果线程中断了，需要抛出异常  
                reportInterruptAfterWait(interruptMode);
        }
```


```
private Node addConditionWaiter() {
    Node t = lastWaiter;
    // If lastWaiter is cancelled, clean out.
    //如果lastWaiter不等于空并且waitStatus不为condition，把这个节点从链表中移除
    if (t != null && t.waitStatus != Node.CONDITION) {
        unlinkCancelledWaiters();
        t = lastWaiter;
    }
    //创建一个状态为condition的单向列表
    Node node = new Node(Thread.currentThread(), Node.CONDITION);
    if (t == null)
        firstWaiter = node;
    else
        t.nextWaiter = node;
    lastWaiter = node;
    return node;
}
```


```
final int fullyRelease(Node node) {
    boolean failed = true;
    try {
        //获得重入的次数
        int savedState = getState();
        //释放并唤醒同步队列中的线程
        if (release(savedState)) {
            failed = false;
            return savedState;
        } else {
            throw new IllegalMonitorStateException();
        }
    } finally {
        if (failed)
            node.waitStatus = Node.CANCELLED;
    }
}
```


```
final boolean isOnSyncQueue(Node node) {
    //判断当前节点是否在队列中，false表示不在，true表示在
    if (node.waitStatus == Node.CONDITION || node.prev == null)
        return false;
    if (node.next != null) // If has successor, it must be on queue
        return true;
    /*
     * node.prev can be non-null, but not yet on queue because
     * the CAS to place it on queue can fail. So we have to
     * traverse from tail to make sure it actually made it.  It
     * will always be near the tail in calls to this method, and
     * unless the CAS failed (which is unlikely), it will be
     * there, so we hardly ever traverse much.
     */
    /从tail节点往前扫描AQS队列，如果发现AQS队列中的节点与当前节点相等，则说明节点一定存在与队列中
    return findNodeFromTail(node);
}
```

#### signal()

调用此方法，将会唤醒在AQS队列中的节点
```
public final void signal() {
    //判断当前线程是否获得了锁
    if (!isHeldExclusively())
        throw new IllegalMonitorStateException();
    //AQS队列的第一个节点
    Node first = firstWaiter;
    if (first != null)
        doSignal(first);
}
```

```
private void doSignal(Node first) {
    do {
        //从condition队列中移除first节点
        if ( (firstWaiter = first.nextWaiter) == null)
            lastWaiter = null;
        first.nextWaiter = null;
    } while (!transferForSignal(first) &&
             (first = firstWaiter) != null);
}
```

```
final boolean transferForSignal(Node node) {
    /*
     * If cannot change waitStatus, the node has been cancelled.
     */
    //更新节点状态为0
    if (!compareAndSetWaitStatus(node, Node.CONDITION, 0))
        return false;

    /*
     * Splice onto queue and try to set waitStatus of predecessor to
     * indicate that thread is (probably) waiting. If cancelled or
     * attempt to set waitStatus fails, wake up to resync (in which
     * case the waitStatus can be transiently and harmlessly wrong).
     */
    //调用 enq，把当前节点添加到AQS队列。并且返回返回按当前节点的上一个节点，也就是原tail 节点
    Node p = enq(node);
    int ws = p.waitStatus;
    //如果上一个节点被取消了，尝试设置上一节点状态为SIGNAL
    if (ws > 0 || !compareAndSetWaitStatus(p, ws, Node.SIGNAL))
        //唤醒节点上的线程
        LockSupport.unpark(node.thread);
    return true;
}
```

* 阻塞：await()方法中，在线程释放锁资源之后，如果节点不在AQS等待队列，则阻塞当前线程，如果在等待队列，则自旋等待尝试获取锁；
* 释放：signal()后，节点会从condition队列移动到AQS等待队列，则进入正常锁的获取流程。