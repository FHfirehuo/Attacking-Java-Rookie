# Object o=new Object()在内存中占用多少字节

如果jvm默认开启了UseCompressedClassPointers类型指针压缩，那么首先new Object（）占用16个字节（markword占8+classpointer占4+instancedata占0+补齐4），然后Object o有一个引用，这个引用默认开启了压缩，所以是4个字节（每个引用占用4个字节），所以一共占用20个字节（byte）

如果jvm没开启CompressedClassPointers类型指针压缩，那么首先new Object（）占用8(markword)+8(class pointer)+0(instance data)+0(补齐为8的倍数)16个字节，然后加引用（因为jvm默认开启UseCompressedClassPointers类型指针压缩，所以默认引用是占4字节，但这里没启用压缩，所以为8字节）占的8个字节=24个字节

## 普通对象在内存中的存储布局:

#### 普通对象（new xx（））组成

* markword（8字节）：关于锁的信息，关于synchronized所有信息都存储在markword中
* 类型指针（jvm默认开启压缩，为4字节）：指向具体哪个类，64位系统中，默认一个类型指针占64位，8字节，但是jvm默认UseCompressedClassPointers,将其压缩为4字节，markword+类型指针class pointer=对象头（12字节）
* 实例数据：像int就是4字节，long就是8字节
* 对齐：因为jvm按8的倍数读，所以要对齐，不够的补，这样读就特别快，提升效率

#### 数组对象组成
对象头markword,类型指针class pointer，数组长度length(4字节)，实例数据instance data，对齐padding
与普通对象相比，数组对象就是多了一个4字节的数组长度length,其余部分与数组对象保持一致。


Klass Word 这里其实是虚拟机设计的一个oop-klass model模型，这里的OOP是指Ordinary Object Pointer（普通对象指针），看起来像个指针实际上是藏在指针里的对象。
而 klass 则包含 元数据和方法信息，用来描述 Java 类。它在64位虚拟机开启压缩指针的环境下占用 32bits 空间。

####Mark Word

Mark Word 是我们分析的重点，这里也会设计到锁的相关知识。Mark Word 在64位虚拟机环境下占用 64bits 空间。整个Mark Word的分配有几种情况：

1. 未锁定（Normal）： 哈希码（identity_hashcode）占用31bits，分代年龄（age）占用4 bits，偏向模式（biased_lock）占用1 bits，锁标记（lock）占用2 bits，剩余26bits 未使用(也就是全为0)
1. 可偏向（Biased）： 线程id 占54bits，epoch 占2 bits，分代年龄（age）占用4 bits，偏向模式（biased_lock）占用1 bits，锁标记（lock）占用2 bits，剩余 1bit 未使用。
1. 轻量锁定（Lightweight Locked）： 锁指针占用62bits，锁标记（lock）占用2 bits。
1. 重量级锁定（Heavyweight Locked）：锁指针占用62bits，锁标记（lock）占用2 bits。
1. GC 标记：标记位占2bits，其余为空（也就是填充0）

以上就是我们对Java对象头内存模型的解析，只要是Java对象，那么就肯定会包括对象头，也就是说这部分内存占用是避免不了的。所以，在笔者64位虚拟机，Jdk1.8（开启了指针压缩）的环境下，任何一个对象，啥也不做，只要声明一个类，那么它的内存占用就至少是96bits，也就是至少12字节。


## 验证模型

首先添加maven依赖

```
       <dependency>
            <groupId>org.openjdk.jol</groupId>
            <artifactId>jol-core</artifactId>
            <version>0.10</version>
        </dependency>
```

