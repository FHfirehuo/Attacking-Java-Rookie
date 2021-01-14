# java 面试

1. List 和 Set 的区别
1. HashSet 是如何保证不重复的
1. HashMap 是线程安全的吗，为什么不是线程安全的（最好画图说明多线程环境下不安全）?
1. HashMap 1.7 与 1.8 的 区别，说明 1.8 做了哪些优化，如何优化的？
1. final finally finalize
1. 强引用 、软引用、 弱引用、虚引用
1. Java反射
1. Arrays.sort 实现原理和 Collection 实现原理
1. LinkedHashMap的应用
1. cloneable接口实现原理
1. 异常分类以及处理机制
1. wait和sleep的区别


#### Synchronized 字节码指令

每个对象有一个监视器锁（monitor）。当monitor被占用时就会处于锁定状态。

关于方法的同步：可以看到相对于普通方法，其常量池中多了ACC_SYNCHRONIZED标示符，JVM就是根据该标示符来实现方法的同步的，当方法调用时，调用指令将会检查方法的 ACC_SYNCHRONIZED 访问标志是否被设置，如果设置了，执行线程将先获取monitor，获取成功之后才能执行方法体，方法执行完后再释放monitor。在方法执行期间，其他任何线程都无法再获得同一个monitor对象。

关于同步块的同步：线程执行monitorenter指令时尝试获取monitor的所有权，执行monitorexit其他被这个monitor阻塞的线程可以尝试去获取这个 monitor 的所有权

Synchronized的语义底层是通过一个monitor的对象来完成，其实wait/notify等方法也依赖于monitor对象，这就是为什么只有在同步的块或者方法中才能调用wait/notify等方法，否则会抛出java.lang.IllegalMonitorStateException的异常的原因。

现在我们应该知道，Synchronized是通过对象内部的一个叫做监视器锁（monitor）来实现的。但是监视器锁本质又是依赖于底层的操作系统的Mutex Lock来实现的。而操作系统实现线程之间的切换这就需要从用户态转换到核心态，这个成本非常高，状态之间的转换需要相对比较长的时间，这就是为什么Synchronized效率低的原因。JDK1.6以后，为了减少获得锁和释放锁所带来的性能消耗，提高性能，引入了“偏向锁”和“轻量级锁”


#### volatile 字节码指令

之所以定位到这两行是因为这里结尾写明了line 14，line 14即volatile变量instance赋值的地方。后面的add dword ptr [rsp],0h都是正常的汇编语句，意思是将双字节的栈指针寄存器+0，这里的关键就是add前面的lock指令，后面详细分析一下lock指令的作用和为什么加上lock指令后就能保证volatile关键字的内存可见性。


#### cas

如上面源代码所示，程序会根据当前处理器的类型来决定是否为cmpxchg指令添加lock前缀。如果程序是在多处理器上运行，就为cmpxchg指令加上lock前缀（lock cmpxchg）。反之，如果程序是在单处理器上运行，就省略lock前缀（单处理器自身会维护单处理器内的顺序一致性，不需要lock前缀提供的内存屏障效果）。


## intel的手册对lock前缀的说明如下：

* 确保对内存的读-改-写操作原子执行。在Pentium及Pentium之前的处理器中，带有lock前缀的指令在执行期间会锁住总线，使得其他处理器暂时无法通过总线访问内存。很显然，这会带来昂贵的开销。从Pentium 4，Intel Xeon及P6处理器开始，intel在原有总线锁的基础上做了一个很有意义的优化：如果要访问的内存区域（area of memory）在lock前缀指令执行期间已经在处理器内部的缓存中被锁定（即包含该内存区域的缓存行当前处于独占或以修改状态），并且该内存区域被完全包含在单个缓存行（cache line）中，那么处理器将直接执行该指令。由于在指令执行期间该缓存行会一直被锁定，其它处理器无法读/写该指令要访问的内存区域，因此能保证指令执行的原子性。这个操作过程叫做缓存锁定（cache locking），缓存锁定将大大降低lock前缀指令的执行开销，但是当多处理器之间的竞争程度很高或者指令访问的内存地址未对齐时，仍然会锁住总线。
* 禁止该指令与之前和之后的读和写指令重排序。
* 把写缓冲区中的所有数据刷新到内存中。