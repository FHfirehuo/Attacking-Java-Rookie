# Hashcode

###### Hash的定义

&emsp;&emsp;散列（哈希）函数:把任意长度的输入（又叫做预映射pre-image）通过散列算法变换成固定长度的输出，
该输出就是散列值，是一种压缩映射。或者说一种将任意长度的消息压缩到某一固定长度的消息摘要的函数。

###### Hash函数特性

&emsp;&emsp;h(k1)≠h(k2)则k1≠k2，即散列值不相同，则输入值即预映射不同

&emsp;&emsp;如果k1≠k2，h(k1)=h(k2) 则发生碰撞

&emsp;&emsp;如果h(k1)=h(k2)，k1不一定等于k2

###### Hash的使用场景

&emsp;&emsp;比如说我们下载一个文件，文件的下载过程中会经过很多网络服务器、路由器的中转，如何保证这个文件就是我们所需要的呢？
我们不可能去一一检测这个文件的每个字节，也不能简单地利用文件名、文件大小这些极容易伪装的信息，
这时候，就需要一种指纹一样的标志来检查文件的可靠性，这种指纹就是我们现在所用的Hash算法(也叫散列算法)。

&emsp;&emsp;散列算法就是一种以较短的信息来保证文件唯一性的标志，这种标志与文件的每一个字节都相关，而且难以找到逆向规律。
因此，当原有文件发生改变时，其标志值也会发生改变，从而告诉文件使用者当前的文件已经不是你所需求的文件。
这种标志有何意义呢？之前文件下载过程就是一个很好的例子，事实上，现在大部分的网络部署和版本控制工具都在使用散列算法来保证文件可靠性。


###### HashCode是什么

&emsp;&emsp;HashCode是Object的一个方法，hashCode方法返回一个hash code值，且这个方法是为了更好的支持hash表，比如String、 Set、 HashTable、HashMap等

###### hash code（hash值|hash码）是什么

&emsp;&emsp;哈希码是按照某种规则生成的int类型的数值。

&emsp;&emsp;哈希码并不是完全唯一的。

&emsp;&emsp;让同一个类的对象按照自己不同的特征尽量的有不同的哈希码，但不是说不同的对象哈希码就一定不同，也有相同的情况。

###### HashCode规范

规范1:

&emsp;&emsp;若重写了某个类的equals方法，请一定重写hashCode方法，要能保证通过equals方法判断为true的两个对象，其hashCode方法的返回值相等，
换句话说，就是要保证”两个对象相等，其hashCode一定相同”始终成立;

规范2:

&emsp;&emsp;若equals方法返回false，即两个对象不相等，并不要求这两个对象的hashCode得到不同的数；


###### HashCode的四条推论

&emsp;&emsp;两个对象相等，其HashCode一定相同;

&emsp;&emsp;两个对象不相等，其HashCode有可能相同;

&emsp;&emsp;HashCode相同的两个对象，不一定相等;

&emsp;&emsp;HashCode不相同的两个对象，一定不相等;

###### 改写equals时总是要改写hashCode

java.lnag.Object中对hashCode的约定：

&emsp;&emsp;1. 在一个应用程序执行期间，如果一个对象的equals方法做比较所用到的信息没有被修改的话，则对该对象调用hashCode方法多次，它必须始终如一地返回同一个整数。

&emsp;&emsp;2. 如果两个对象根据equals(Object o)方法是相等的，则调用这两个对象中任一对象的hashCode方法必须产生相同的整数结果。

&emsp;&emsp;3. 如果两个对象根据equals(Object o)方法是不相等的，则调用这两个对象中任一个对象的hashCode方法，不要求产生不同的整数结果。但如果能不同，则可能提高散列表的性能。

&emsp;&emsp;有一个概念要牢记，两个相等对象的equals方法一定为true, 但两个hashcode相等的对象不一定是相等的对象。

&emsp;&emsp;所以hashcode相等只能保证两个对象在一个HASH表里的同一条HASH链上，继而通过equals方法才能确定是不是同一对象，
如果结果为true, 则认为是同一对象在插入，否则认为是不同对象继续插入。

Object的代码:
```java

   /**
     * Returns a hash code value for the object. This method is
     * supported for the benefit of hash tables such as those provided by
     * {@link java.util.HashMap}.
     * <p>
     * The general contract of {@code hashCode} is:
     * <ul>
     * <li>Whenever it is invoked on the same object more than once during
     *     an execution of a Java application, the {@code hashCode} method
     *     must consistently return the same integer, provided no information
     *     used in {@code equals} comparisons on the object is modified.
     *     This integer need not remain consistent from one execution of an
     *     application to another execution of the same application.
     * <li>If two objects are equal according to the {@code equals(Object)}
     *     method, then calling the {@code hashCode} method on each of
     *     the two objects must produce the same integer result.
     * <li>It is <em>not</em> required that if two objects are unequal
     *     according to the {@link java.lang.Object#equals(java.lang.Object)}
     *     method, then calling the {@code hashCode} method on each of the
     *     two objects must produce distinct integer results.  However, the
     *     programmer should be aware that producing distinct integer results
     *     for unequal objects may improve the performance of hash tables.
     * </ul>
     * <p>
     * As much as is reasonably practical, the hashCode method defined by
     * class {@code Object} does return distinct integers for distinct
     * objects. (This is typically implemented by converting the internal
     * address of the object into an integer, but this implementation
     * technique is not required by the
     * Java&trade; programming language.)
     *
     * @return  a hash code value for this object.
     * @see     java.lang.Object#equals(java.lang.Object)
     * @see     java.lang.System#identityHashCode
     */
    public native int hashCode();

```

翻译内容如下：

    返回对象的哈希码值。支持此方法的好处是哈希表，例如java.util.HashMap提供的哈希表。
    hashCode的一般契约是：
    每当在执行Java应用程序期间多次在同一对象上调用它时，hashCode方法必须始终返回相同的整数，前提是不修改对象的equals比较中使用的信息。从应用程序的一次执行到同一应用程序的另一次执行，该整数不需要保持一致。
    如果两个对象根据equals（Object）方法相等，则对两个对象中的每一个调用hashCode方法必须生成相同的整数结果。
    如果两个对象根据equals（Object）方法不相等则不是必需的，则对两个对象中的每一个调用hashCode方法必须产生不同的整数结果。但是，程序员应该知道为不等对象生成不同的整数结果可能会提高哈希表的性能。
    尽可能合理，Object类定义的hashCode方法确实为不同的对象返回不同的整数。 （ 这通常通过将对象的内部地址转换为整数来实现，但Java™编程语言不需要此实现技术。）

###### Object.hashCode不可以代表内存地址
&emsp;&emsp;首先上面注意括号里的这句 **这通常通过将对象的内部地址转换为整数来实现，但Java™编程语言不需要此实现技术**

为了解决这个谜团，还是得看看#Object.java#hashCode的具体实现方法了。
native方法本身非java实现，如果想要看源码，只有下载完整的jdk呗（openJdk1.8）。
找到Object.c文件，查看上面的方法映射表发现，hashCode被映射到了一个叫JVM_IHashCode上去了
```c
static JNINativeMethod methods[] = {
    {"hashCode",    "()I",                    (void *)&JVM_IHashCode},
    {"wait",        "(J)V",                   (void *)&JVM_MonitorWait},
    {"notify",      "()V",                    (void *)&JVM_MonitorNotify},
    {"notifyAll",   "()V",                    (void *)&JVM_MonitorNotifyAll},
    {"clone",       "()Ljava/lang/Object;",   (void *)&JVM_Clone},
};
```

顺藤摸瓜去看看JVM_IHashCode到底干了什么？熟悉的味道，我猜在jvm.h里面有方法声明，那实现一定在jvm.cpp里面。

果然处处有惊喜，和猜想的没错，不过jvm.cpp对于JVM_IHashCode的实现调用的是ObjectSynchronizer::FastHashCode的方法。看来革命尚未成功啊！

```c
JVM_ENTRY(jint, JVM_IHashCode(JNIEnv* env, jobject handle))
  JVMWrapper("JVM_IHashCode");
  // as implemented in the classic virtual machine; return 0 if object is NULL
  return handle == NULL ? 0 : ObjectSynchronizer::FastHashCode (THREAD, JNIHandles::resolve_non_null(handle)) ;
JVM_END
```
找了一会儿，没找到，这就尴尬了。后面百度了一下，发现声明在synchronizer.hpp 实现在这里synchronizer.cpp。感谢前辈们走出的路啊！

```c
// hashCode() generation :
//
// Possibilities:
// * MD5Digest of {obj,stwRandom}
// * CRC32 of {obj,stwRandom} or any linear-feedback shift register function.
// * A DES- or AES-style SBox[] mechanism
// * One of the Phi-based schemes, such as:
//   2654435761 = 2^32 * Phi (golden ratio)
//   HashCodeValue = ((uintptr_t(obj) >> 3) * 2654435761) ^ GVars.stwRandom ;
// * A variation of Marsaglia's shift-xor RNG scheme.
// * (obj ^ stwRandom) is appealing, but can result
//   in undesirable regularity in the hashCode values of adjacent objects
//   (objects allocated back-to-back, in particular).  This could potentially
//   result in hashtable collisions and reduced hashtable efficiency.
//   There are simple ways to "diffuse" the middle address bits over the
//   generated hashCode values:
 
static inline intptr_t get_next_hash(Thread * Self, oop obj) {
  intptr_t value = 0;
  if (hashCode == 0) {
    // This form uses global Park-Miller RNG.
    // On MP system we'll have lots of RW access to a global, so the
    // mechanism induces lots of coherency traffic.
    value = os::random();
  } else if (hashCode == 1) {
    // This variation has the property of being stable (idempotent)
    // between STW operations.  This can be useful in some of the 1-0
    // synchronization schemes.
    intptr_t addrBits = cast_from_oop<intptr_t>(obj) >> 3;
    value = addrBits ^ (addrBits >> 5) ^ GVars.stwRandom;
  } else if (hashCode == 2) {
    value = 1;            // for sensitivity testing
  } else if (hashCode == 3) {
    value = ++GVars.hcSequence;
  } else if (hashCode == 4) {
    value = cast_from_oop<intptr_t>(obj);
  } else {
    // Marsaglia's xor-shift scheme with thread-specific state
    // This is probably the best overall implementation -- we'll
    // likely make this the default in future releases.
    unsigned t = Self->_hashStateX;
    t ^= (t << 11);
    Self->_hashStateX = Self->_hashStateY;
    Self->_hashStateY = Self->_hashStateZ;
    Self->_hashStateZ = Self->_hashStateW;
    unsigned v = Self->_hashStateW;
    v = (v ^ (v >> 19)) ^ (t ^ (t >> 8));
    Self->_hashStateW = v;
    value = v;
  }
 
  value &= markOopDesc::hash_mask;
  if (value == 0) value = 0xBAD;
  assert(value != markOopDesc::no_hash, "invariant");
  TEVENT(hashCode: GENERATE);
  return value;
}
 
 
intptr_t ObjectSynchronizer::FastHashCode(Thread * Self, oop obj) {
  if (UseBiasedLocking) {
    // NOTE: many places throughout the JVM do not expect a safepoint
    // to be taken here, in particular most operations on perm gen
    // objects. However, we only ever bias Java instances and all of
    // the call sites of identity_hash that might revoke biases have
    // been checked to make sure they can handle a safepoint. The
    // added check of the bias pattern is to avoid useless calls to
    // thread-local storage.
    if (obj->mark()->has_bias_pattern()) {
      // Handle for oop obj in case of STW safepoint
      Handle hobj(Self, obj);
      // Relaxing assertion for bug 6320749.
      assert(Universe::verify_in_progress() ||
             !SafepointSynchronize::is_at_safepoint(),
             "biases should not be seen by VM thread here");
      BiasedLocking::revoke_and_rebias(hobj, false, JavaThread::current());
      obj = hobj();
      assert(!obj->mark()->has_bias_pattern(), "biases should be revoked by now");
    }
  }
 
  // hashCode() is a heap mutator ...
  // Relaxing assertion for bug 6320749.
  assert(Universe::verify_in_progress() || DumpSharedSpaces ||
         !SafepointSynchronize::is_at_safepoint(), "invariant");
  assert(Universe::verify_in_progress() || DumpSharedSpaces ||
         Self->is_Java_thread() , "invariant");
  assert(Universe::verify_in_progress() || DumpSharedSpaces ||
         ((JavaThread *)Self)->thread_state() != _thread_blocked, "invariant");
 
  ObjectMonitor* monitor = NULL;
  markOop temp, test;
  intptr_t hash;
  markOop mark = ReadStableMark(obj);
 
  // object should remain ineligible for biased locking
  assert(!mark->has_bias_pattern(), "invariant");
 
  if (mark->is_neutral()) {
    hash = mark->hash();              // this is a normal header
    if (hash) {                       // if it has hash, just return it
      return hash;
    }
    hash = get_next_hash(Self, obj);  // allocate a new hash code
    temp = mark->copy_set_hash(hash); // merge the hash code into header
    // use (machine word version) atomic operation to install the hash
    test = obj->cas_set_mark(temp, mark);
    if (test == mark) {
      return hash;
    }
    // If atomic operation failed, we must inflate the header
    // into heavy weight monitor. We could add more code here
    // for fast path, but it does not worth the complexity.
  } else if (mark->has_monitor()) {
    monitor = mark->monitor();
    temp = monitor->header();
    assert(temp->is_neutral(), "invariant");
    hash = temp->hash();
    if (hash) {
      return hash;
    }
    // Skip to the following code to reduce code size
  } else if (Self->is_lock_owned((address)mark->locker())) {
    temp = mark->displaced_mark_helper(); // this is a lightweight monitor owned
    assert(temp->is_neutral(), "invariant");
    hash = temp->hash();              // by current thread, check if the displaced
    if (hash) {                       // header contains hash code
      return hash;
    }
    // WARNING:
    //   The displaced header is strictly immutable.
    // It can NOT be changed in ANY cases. So we have
    // to inflate the header into heavyweight monitor
    // even the current thread owns the lock. The reason
    // is the BasicLock (stack slot) will be asynchronously
    // read by other threads during the inflate() function.
    // Any change to stack may not propagate to other threads
    // correctly.
  }
 
  // Inflate the monitor to set hash code
  monitor = ObjectSynchronizer::inflate(Self, obj, inflate_cause_hash_code);
  // Load displaced header and check it has hash code
  mark = monitor->header();
  assert(mark->is_neutral(), "invariant");
  hash = mark->hash();
  if (hash == 0) {
    hash = get_next_hash(Self, obj);
    temp = mark->copy_set_hash(hash); // merge hash code into header
    assert(temp->is_neutral(), "invariant");
    test = Atomic::cmpxchg(temp, monitor->header_addr(), mark);
    if (test != mark) {
      // The only update to the header in the monitor (outside GC)
      // is install the hash code. If someone add new usage of
      // displaced header, please update this code
      hash = test->hash();
      assert(test->is_neutral(), "invariant");
      assert(hash != 0, "Trivial unexpected object/monitor header usage.");
    }
  }
  // We finally get the hash
  return hash;
}
没想到代码这么长，确实比

int var;
return &var;
```

可以看到在get_next_hash函数中，有五种不同的hashCode生成策略。

第一种：是使用全局的os::random()随机数生成策略。os::random()的实现方式在os.cpp中，代码如下

````c
void os::init_random(unsigned int initval) {
  _rand_seed = initval;
}
 
 
static int random_helper(unsigned int rand_seed) {
  /* standard, well-known linear congruential random generator with
   * next_rand = (16807*seed) mod (2**31-1)
   * see
   * (1) "Random Number Generators: Good Ones Are Hard to Find",
   *      S.K. Park and K.W. Miller, Communications of the ACM 31:10 (Oct 1988),
   * (2) "Two Fast Implementations of the 'Minimal Standard' Random
   *     Number Generator", David G. Carta, Comm. ACM 33, 1 (Jan 1990), pp. 87-88.
  */
  const unsigned int a = 16807;
  const unsigned int m = 2147483647;
  const int q = m / a;        assert(q == 127773, "weird math");
  const int r = m % a;        assert(r == 2836, "weird math");
 
  // compute az=2^31p+q
  unsigned int lo = a * (rand_seed & 0xFFFF);
  unsigned int hi = a * (rand_seed >> 16);
  lo += (hi & 0x7FFF) << 16;
 
  // if q overflowed, ignore the overflow and increment q
  if (lo > m) {
    lo &= m;
    ++lo;
  }
  lo += hi >> 15;
 
  // if (p+q) overflowed, ignore the overflow and increment (p+q)
  if (lo > m) {
    lo &= m;
    ++lo;
  }
  return lo;
}
 
int os::random() {
  // Make updating the random seed thread safe.
  while (true) {
    unsigned int seed = _rand_seed;
    unsigned int rand = random_helper(seed);
    if (Atomic::cmpxchg(rand, &_rand_seed, seed) == seed) {
      return static_cast<int>(rand);
    }
  }
}
````

根据代码注解的提示，随机数的生成策略是一种线性取余方式生成的。

第二种：addrBits ^ (addrBits >> 5) ^ GVars.stwRandom。
这里是第一次 看到和地址相关的变量，addrBits通过调用cast_from_oop方法得到。
cast_from_oop实现在oopsHierarchy.cpp。具体代码如下

````c
template <class T> inline oop cast_to_oop(T value) {
  return (oop)(CHECK_UNHANDLED_OOPS_ONLY((void *))(value));
}
//以下部分内容来源于 oopsHierachy.hpp
template <class T> inline T cast_from_oop(oop o) {
  return (T)(CHECK_UNHANDLED_OOPS_ONLY((void*))o);
}
````
很遗憾的是我还是没有看到 cast_to_oop具体是怎么实现的，后面会更新的

第三种：敏感测试

````c
value = 1;   
````
第四种：自增序列
````c
 value = ++GVars.hcSequence;
````
官方将会默认。利用位移生成随机数
````c
// Marsaglia's xor-shift scheme with thread-specific state
    // This is probably the best overall implementation -- we'll
    // likely make this the default in future releases.
    unsigned t = Self->_hashStateX;
    t ^= (t << 11);
    Self->_hashStateX = Self->_hashStateY;
    Self->_hashStateY = Self->_hashStateZ;
    Self->_hashStateZ = Self->_hashStateW;
    unsigned v = Self->_hashStateW;
    v = (v ^ (v >> 19)) ^ (t ^ (t >> 8));
    Self->_hashStateW = v;
    value = v;
````

最后来回答 一开始的问题。

1.hashCode 是怎么来的？——原来有很多，自增序列，随机数，内存地址。这里又有个新问题产生了，为什么不用时间戳了？

2.可以预测值？——这很难说啊！
###### hash table（hash表）是什么

Hash表数据结构常识：

&emsp;&emsp;哈希表基于数组。

&emsp;&emsp;缺点：基于数组的，数组创建后难以扩展。某些哈希表被基本填满时，性能下降得非常严重。

&emsp;&emsp;没有一种简便得方法可以以任何一种顺序遍历表中数据项。

&emsp;&emsp;如果不需要有序遍历数据，并且可以提前预测数据量的大小，那么哈希表在速度和易用性方面是无与伦比的。

###### Hash表定义

&emsp;&emsp;根据关键码值（KEY-VALUE）而直接进行访问的数据结构；它通过把关键码值（KEY-VALUE）映射到表中一个位置来访问记录，
以加快查找的速度。这个映射函数叫做散列函数，存放记录的数组叫做散列表。

###### 如何理解Hashcode的作用
&emsp;&emsp;以java.lang.Object来理解,JVM每new一个Object,它都会将这个Object丢到一个Hash哈希表中去,
这样的话,下次做Object的比较或者取这个对象的时候,它会根据对象的hashcode再从Hash表中取这个对象。这样做的目的是提高取对象的效率。具体过程是这样:

&emsp;&emsp;1.new Object(),JVM根据这个对象的Hashcode值,放入到对应的Hash表对应的Key上,
如果不同的对象确产生了相同的hash值,也就是发生了Hash key相同导致冲突的情况,那么就在这个Hash key的地方产生一个链表,将所有产生相同hashcode的对象放到这个单链表上去,串在一起。

&emsp;&emsp;2.比较两个对象的时候,首先根据他们的hashcode去hash表中找他的对象,
当两个对象的hashcode相同,那么就是说他们这两个对象放在Hash表中的同一个key上,那么他们一定在这个key上的链表上。
那么此时就只能根据Object的equal方法来比较这个对象是否equal。当两个对象的hashcode不同的话，肯定他们不能equal.

###### 为什么HashCode对于对象是如此的重要

&emsp;&emsp;一个对象的HashCode就是一个简单的Hash算法的实现，虽然它和那些真正的复杂的Hash算法相比还不能叫真正的算法，如何实现它，不仅仅是程序员的编程水平问题，
而是关系到你的对象存取性能。有可能，不同的HashCode算法可能会使你的对象存取产生成百上千倍的性能差别.
先来看一下，在JAVA中两个重要的数据结构:HashMap和Hashtable，虽然它们有很大的区别，如继承关系不同，对value的约束条件(是否允许null)不同，以及线程安全性等有着特定的区别，
但从实现原理上来说，它们是一致的.所以，我们只以Hashtable来说明：

&emsp;&emsp;在java中，存取数据的性能，一般来说当然是首推数组，但是在数据量稍大的容器选择中，Hashtable将有比数组更高的查询速度.具体原因看下面的内容.

&emsp;&emsp;Hashtable在存储数据时，一般先将该对象的HashCode和0x7FFFFFFF做与操作，因为一个对象的HashCode可以为负数，这样操作后可以保证它为一个正整数.然后以Hashtable的长度取模，得到该对象在Hashtable中的索引.

Hashtable中源码HashMap没有
``java
int hash = key.hashCode();
int index = (hash & 0x7FFFFFFF) % tab.length;
``

&emsp;&emsp;这个对象就会直接放在Hashtable的每index位置，但如果是查询，经过同样的算法，Hashtable可以直接从第index取得这个对象，而数组却要做循环比较.所以对于数据量稍大时，Hashtable的查询比数据具有更高的性能.
既然一个对象可以根据HashCode直接定位它在Hashtable中的位置，那么为什么Hashtable还要用key来做映射呢?这就是关系Hashtable性能问题的最重要的问题"Hash冲突".


###### Hash冲突(Hash碰撞)



###### 

