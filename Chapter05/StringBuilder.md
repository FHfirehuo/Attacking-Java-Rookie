# 深入理解StringBuilder

## 为什么StringBuilder是线程不安全的

#### 原因分析

如果你看了StringBuilder或StringBuffer的源代码会说，因为StringBuilder在append操作时并未使用线程同步，而StringBuffer几乎大部分方法都使用了synchronized关键字进行方法级别的同步处理。

上面这种说法肯定是正确的，对照一下StringBuilder和StringBuffer的部分源代码也能够看出来。

StringBuilder的append方法源代码：

```java
    @Override
    public StringBuilder append(String str) {
        super.append(str);
        return this;
    }
```

StringBuffer的append方法源代码：
```java
    @Override
    public synchronized StringBuffer append(String str) {
        toStringCache = null;
        super.append(str);
        return this;
    }
```

对于上面的结论肯定是没什么问题的，但并没有解释是什么原因导致了StringBuilder的线程不安全？
为什么要使用synchronized来保证线程安全？如果不是用会出现什么异常情况？

下面我们来逐一讲解。

#### 异常示例
```java
    public static void test() throws InterruptedException {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 10; i++) {
            new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    sb.append("a");
                }
            }).start();
        }
        // 睡眠确保所有线程都执行完
        Thread.sleep(1000);
        System.out.println(sb.length());
    }
```
上述业务逻辑比较简单，就是构建一个StringBuilder，然后创建10个线程，每个线程中拼接字符串“a”1000次，理论上当线程执行完成之后，打印的结果应该是10000才对。

但多次执行上面的代码打印的结果是10000的概率反而非常小，大多数情况都要少于10000。同时，还有一定的概率出现下面的异常信息“

>Exception in thread "Thread-1" java.lang.ArrayIndexOutOfBoundsException<br>
 	at java.lang.System.arraycopy(Native Method)<br>
 	at java.lang.String.getChars(String.java:826)<br>
 	at java.lang.AbstractStringBuilder.append(AbstractStringBuilder.java:449)<br>
 	at java.lang.StringBuilder.append(StringBuilder.java:136)<br>
 	at string.StringB.lambda$test$0(StringB.java:20)<br>
 	at java.lang.Thread.run(Thread.java:748)<br>
 9513

#### 线程不安全的原因

StringBuilder中针对字符串的处理主要依赖两个成员变量char数组value和count。StringBuilder通过对value的不断扩容和count对应的增加来完成字符串的append操作。

```java
abstract class AbstractStringBuilder implements Appendable, CharSequence {
    /**
     * The value is used for character storage.
     */
// 存储的字符串（通常情况一部分为字符串内容，一部分为默认值）
    char[] value;

    /**
     * The count is the number of characters used.
     */
// 数组已经使用数量
    int count;
```

上面的这两个属性均位于它的抽象父类AbstractStringBuilder中。

如果查看构造方法我们会发现，在创建StringBuilder时会设置数组value的初始化长度。
```java
    public StringBuilder(String str) {
        super(str.length() + 16);
        append(str);
    }
```


```java
    AbstractStringBuilder(int capacity) {
        value = new char[capacity];
    }
```
默认是传入字符串长度加16。这就是count存在的意义，因为数组中的一部分内容为默认值。

当调用append方法时会对count进行增加，增加值便是append的字符串的长度，具体实现也在抽象父类中

```java
    public AbstractStringBuilder append(String str) {
        if (str == null)
            return appendNull();
        int len = str.length();
        ensureCapacityInternal(count + len);
        str.getChars(0, len, value, count);
        count += len;
        return this;
    }
```
我们所说的线程不安全的发生点便是在append方法中count的“+=”操作。我们知道该操作是线程不安全的，那么便会发生两个线程同时读取到count值为5，执行加1操作之后，都变成6，而不是预期的7。这种情况一旦发生便不会出现预期的结果。

#### 抛异常的原因

回头看异常的堆栈信息，回发现有这么一行内容：

     	at java.lang.String.getChars(String.java:826)

对应的代码就是上面AbstractStringBuilder中append方法中的代码。对应String类中getChars方法的源代码如下：
```java
    public void getChars(int srcBegin, int srcEnd, char dst[], int dstBegin) {
        if (srcBegin < 0) {
            throw new StringIndexOutOfBoundsException(srcBegin);
        }
        if (srcEnd > value.length) {
            throw new StringIndexOutOfBoundsException(srcEnd);
        }
        if (srcBegin > srcEnd) {
            throw new StringIndexOutOfBoundsException(srcEnd - srcBegin);
        }
        System.arraycopy(value, srcBegin, dst, dstBegin, srcEnd - srcBegin);
    }
```

其实异常是最后一行arraycopy时JVM底层发生的。arraycopy的核心操作就是将传入的String对象copy到value当中。

而异常发生的原因是明明value的下标只到6，程序却要访问和操作下标为7的位置，当然就跑异常了。

那么，为什么会超出这么一个位置呢？这与我们上面讲到到的count被少加有关。在执行str.getChars方法之前还需要根据count校验一下当前的value是否使用完毕，如果使用完了，那么就进行扩容。append中对应的方法如下：

    ensureCapacityInternal(count + len);

```java
    private void ensureCapacityInternal(int minimumCapacity) {
        // overflow-conscious code
        if (minimumCapacity - value.length > 0) {
            value = Arrays.copyOf(value,
                    newCapacity(minimumCapacity));
        }
    }
```

count本应该为7，value长度为6，本应该触发扩容。但因为并发导致count为6，假设len为1，则传递的minimumCapacity为7，并不会进行扩容操作。这就导致后面执行str.getChars方法进行复制操作时访问了不存在的位置，因此抛出异常。

这里我们顺便看一下扩容方法中的newCapacity方法：
```java
    private int newCapacity(int minCapacity) {
        // overflow-conscious code
        int newCapacity = (value.length << 1) + 2;
        if (newCapacity - minCapacity < 0) {
            newCapacity = minCapacity;
        }
        return (newCapacity <= 0 || MAX_ARRAY_SIZE - newCapacity < 0)
            ? hugeCapacity(minCapacity)
            : newCapacity;
    }
```

除了校验部分，最核心的就是将新数组的长度扩充为原来的两倍再加2。把计算所得的新长度作为Arrays.copyOf的参数进行扩容。
