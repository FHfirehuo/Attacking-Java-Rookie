# 向量

知道向量指向需要先知道一个概念**序列（Sequence**。
所谓序列，就是依次排列的多个对象。
比如，每一计算机程序都可以看作一个序列，
它由一系列依次排列的指令组成，正是指令之间的次序决定了程序的具体功能。
因此，所谓序列，就是一组对象之间的后继与前驱关系。
在实际问题中，序列可以用来实现很多种数据结构，
因此被认为是数据结构设计的基础。
栈、队列以及双端队列，都可以看作带有附加限制的序列。

**向量（Vector）和列表（List）都属于序列**

#### 什么是向量

对数组结构进行抽象与扩展之后，就可以得到向量结构，
因此向量也称作数组列表（Array list）。
向量提供一些访问方法，使得我们可以通过下标直接访问序列中的元素，
也可以将指定下标处的元素删除，或将新元素插入至指定下标。
为了与通常数组结构的下标（Index）概念区分开来，
我们通常将序列的下标称为秩（Rank）。

假定集合 S 由n 个元素组成，它们按照线性次序存放，
于是我们就可以直接访问其中的第一个元素、第二个元素、第三个元素……。
也就是说，通过[0, n-1]之间的每一个整数，
都可以直接访问到唯一的元素e，
而这个整数就等于S 中位于e 之前的元素个数——在此，我们称之为该元素的秩（Rank）。
不难看出，若元素e 的秩为r，则只要e 的直接前驱（或直接后继）存在，其秩就是r-1（或r+1）。

支持通过秩直接访问其中元素的序列，
称作向量（Vector）或数组列表（Array list）。
实际上，秩这一直观概念的功能非常强大——它可以直接指定插入或删除元素的位置。

#### 向量ADT(AbstractDataType)

| 操作方法 | 功能描述 |
| :---- | :---- |
| getSize() | 报告向量中的元素数目<br>输入：无<br>输出：非负整数 |
| isEmpty() | 判断向量是否为空<br>输入：无<br>输出：布尔值 |
| getAtRank(r) | 若0 ≤ r < getSize()，则返回秩为r 的那个元素 ；否则，报错<br>输入：一个整数<br>输出：对象 |
| replaceAtRank(r, e) | 若0 ≤ r < getSize()，则将秩为r 的元素替换为e，并返回原来的元素 ；否则，报错<br>输入：一个整数和一个对象<br>输出：对象 |
| insertAtRank(r, e) | 若0 ≤ r ≤ getSize()，则将e 插入向量中，作为秩为r 的元素（原秩不小于r 的元素顺次后移），并返回原来的元素 ；否则，报错<br>输入：一个整数和一个对象<br>输出：对象 |
| removeAtRank(r) | 若0 ≤ r < getSize()，则删除秩为r 的那个元素并返回之（原秩大于r 的元素顺次前移）；否则，报错<br>输入：一个整数<br>输出：对象 |

#### 基于数组的简单实现

```java
package datastructure.sequence;


public interface FireVector<E> {

    boolean isEmpty();

    int size();

    void add(E e);

    void set(int index, E e);

    E get(int index);

    void remove(int index);

    boolean contains(E e);

}

```

```java
package datastructure.sequence;

import java.util.Arrays;

public class FireArrayVector<E> implements FireVector<E> {

    private Object[] elementData;

    private int elementCount;

    private int capacityIncrement;

    protected int modCount;

    /**
     *
     * @param initialCapacity 初始容量
     * @param capacityIncrement 扩容时增长的容量
     */
    public FireArrayVector(int initialCapacity, int capacityIncrement) {
        if (initialCapacity < 0) {
            throw new IllegalArgumentException("illegal capacity " + initialCapacity);
        }
        this.elementData = new Object[initialCapacity];
        this.capacityIncrement = capacityIncrement;
    }

    public FireArrayVector(int initialCapacity) {
        this(initialCapacity, 0);
    }


    public FireArrayVector() {
        this(10);
    }


    @Override
    public boolean isEmpty() {
        return this.elementCount == 0;
    }

    @Override
    public int size() {
        return this.elementCount;
    }

    @Override
    public void add(E element) {
        elementCount ++;
        capacityHelper(elementCount);
        elementData[elementCount] = element;
    }

    private void capacityHelper(int minLength) {
        if(minLength > elementData.length){
            grow(minLength);
        }
    }

    /**
     * The maximum size of array to allocate.
     * Some VMs reserve some header words in an array.
     * Attempts to allocate larger arrays may result in  OutOfMemoryError: Requested array size exceeds VM limit
     *
     * 要分配的最大数组大小。 一些虚拟机在数组中保留一些头字。 
     * 尝试分配更大的阵列可能会导致OutOfMemoryError：请求的阵列大小超出VM限制
     */
    private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;

    private void grow(int minCapacity) {
        int oldCapacity = elementData.length;
        int newCapacity= oldCapacity + ((capacityIncrement > 0) ? capacityIncrement : oldCapacity);

        if(minCapacity - newCapacity > 0){
            newCapacity = minCapacity;
        }
        if (newCapacity > MAX_ARRAY_SIZE){

        }
        elementData = Arrays.copyOf(elementData, newCapacity);
    }

    @Override
    public void set(int index, E element) {
        if (index >= elementCount){
            throw new ArrayIndexOutOfBoundsException();
        }

        elementData[index] = element;
    }

    @Override
    public E get(int index) {
        if (index >= elementCount){
            throw new ArrayIndexOutOfBoundsException();
        }
        return (E) elementData[index];
    }

    @Override
    public void remove(int index) {
        if(index < 0){
            throw new ArrayIndexOutOfBoundsException(index);
        }
        if (index > elementCount){
            throw new ArrayIndexOutOfBoundsException(index);
        }
        int j = elementCount - index - 1;
        System.arraycopy(elementData, index + 1, elementData, index, j);
        elementData[--elementCount] = null;
    }

    @Override
    public boolean contains(Object o) {
        return indexOf(o) >= 0;
    }


    private int indexOf(Object o) {
        if (o == null) {
            for (int i = 0; i < elementCount; i++) {
                if (elementData[i] == null) {
                    return i;
                }
            }
        } else {
            for (int i = 0; i < elementCount; i++) {
                if (o.equals(elementData[i])) {
                    return i;
                }
            }
        }

        return -1;
    }
}

```

> Java本身也提供了与向量ADT功能类似的两个类：java.util.ArrayList和java.util.Vector。
