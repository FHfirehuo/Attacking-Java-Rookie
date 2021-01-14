# 迭代器模式
迭代器模式(Iterator Pattern)：提供一种方法来访问聚合对象，而不用暴露这个对象的内部表示，其别名为游标(Cursor)。迭代器模式是一种对象行为型模式。

### 角色
* Iterator（抽象迭代器）：它定义了访问和遍历元素的接口，声明了用于遍历数据元素的方法，例如：用于获取第一个元素的first()方法，用于访问下一个元素的next()方法，用于判断是否还有下一个元素的hasNext()方法，用于获取当前元素的currentItem()方法等，在具体迭代器中将实现这些方法。
* ConcreteIterator（具体迭代器）：它实现了抽象迭代器接口，完成对聚合对象的遍历，同时在具体迭代器中通过游标来记录在聚合对象中所处的当前位置，在具体实现时，游标通常是一个表示位置的非负整数。
* Aggregate（抽象聚合类）：它用于存储和管理元素对象，声明一个createIterator()方法用于创建一个迭代器对象，充当抽象迭代器工厂角色。
* ConcreteAggregate（具体聚合类）：它实现了在抽象聚合类中声明的createIterator()方法，该方法返回一个与该具体聚合类对应的具体迭代器ConcreteIterator实例。

在迭代器模式中，提供了一个外部的迭代器来对聚合对象进行访问和遍历，迭代器定义了一个访问该聚合元素的接口，并且可以跟踪当前遍历的元素，了解哪些元素已经遍历过而哪些没有。迭代器的引入，将使得对一个复杂聚合对象的操作变得简单。

在迭代器模式中应用了工厂方法模式，抽象迭代器对应于抽象产品角色，具体迭代器对应于具体产品角色，抽象聚合类对应于抽象工厂角色，具体聚合类对应于具体工厂角色。


### 优点

它支持以不同的方式遍历一个聚合对象，在同一个聚合对象上可以定义多种遍历方式。在迭代器模式中只需要用一个不同的迭代器来替换原有迭代器即可改变遍历算法，我们也可以自己定义迭代器的子类以支持新的遍历方式。
迭代器简化了聚合类。由于引入了迭代器，在原有的聚合对象中不需要再自行提供数据遍历等方法，这样可以简化聚合类的设计。
在迭代器模式中，由于引入了抽象层，增加新的聚合类和迭代器类都很方便，无须修改原有代码，满足 “开闭原则” 的要求。

### 缺点

由于迭代器模式将存储数据和遍历数据的职责分离，增加新的聚合类需要对应增加新的迭代器类，类的个数成对增加，这在一定程度上增加了系统的复杂性。
抽象迭代器的设计难度较大，需要充分考虑到系统将来的扩展，例如JDK内置迭代器Iterator就无法实现逆向遍历，如果需要实现逆向遍历，只能通过其子类ListIterator等来实现，而ListIterator迭代器无法用于操作Set类型的聚合对象。在自定义迭代器时，创建一个考虑全面的抽象迭代器并不是件很容易的事情。

### 适用场景:
       
访问一个聚合对象的内容而无须暴露它的内部表示。将聚合对象的访问与内部数据的存储分离，使得访问聚合对象时无须了解其内部实现细节。
需要为一个聚合对象提供多种遍历方式。
为遍历不同的聚合结构提供一个统一的接口，在该接口的实现类中为不同的聚合结构提供不同的遍历方式，而客户端可以一致性地操作该接口。

### 代码展示

```java
package designpatterns.iterator.book;

public interface FireIterator {
    boolean hasNext();
    Object next();
}

```

```java
package designpatterns.iterator.book;

public interface Aggregate {
    FireIterator iterator();
}

```

```java
package designpatterns.iterator.book;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class Book {

    private String name;
}

```

```java
package designpatterns.iterator.book;

public class BookShelf implements Aggregate {

    private Book[] books;
    int pointer = 0;


    public BookShelf(int max_size) {
        books = new Book[max_size];
    }

    public void appendBook(Book book) {
        books[pointer] = book;
        pointer++;
    }

    public Book findBookAt(int index) {
        return books[index];
    }

    public int getLength() {
        return pointer;
    }

    /**
     * @return
     */
    public FireIterator iterator() {
        return new BookShelfIterator(this);
    }

    private class BookShelfIterator implements FireIterator {

        BookShelf bookShelf;
        int index;

        public BookShelfIterator(BookShelf bookShelf) {
            this.bookShelf = bookShelf;
            index = 0;
        }

        public boolean hasNext() {
            if (index < this.bookShelf.getLength()) {
                return true;
            }
            return false;
        }

        public Object next() {
            return bookShelf.findBookAt(index++);
        }
    }

}

```

```java
package designpatterns.iterator.book;

public class BookMain {


    public static void main(String[] args) {

        Book book1 = new Book("朝花夕拾");
        Book book2 = new Book("围城");
        Book book3 = new Book("遮天");
        Book book4 = new Book("寻秦记");
        Book book5 = new Book("骆驼祥子");

        BookShelf bookShelf = new BookShelf(5);

        bookShelf.appendBook(book1);
        bookShelf.appendBook(book2);
        bookShelf.appendBook(book3);
        bookShelf.appendBook(book4);
        bookShelf.appendBook(book5);

        /**
         * MyIterator，而不是BookShelfIterator，这样做的好处是完全屏蔽了内部的细节，
         * 在用户使用的时候，完全不知道BookShelfIterator的存在。
         *
         * 引入迭代器之后，可以将元素的遍历和实现分离开来，
         * 如下面的代码中的while循环，没有依赖与BookShelf的实现，
         * 没有使用BookShelf的其他方法，只是用了迭代器中hasNext和next方法。
         * 可复用指的是将一个类作为一个组件，当一个组件改变时，不需要对其他组件进行修改或者只进行少量的修改就可以实现修改后的功能。
         * MyIterator it= bookShelf.iterator();面向接口编程，便于程序的修改和维护。
         */
        FireIterator it = bookShelf.iterator();
        while (it.hasNext()) {
            Book book = (Book) it.next();
            System.out.println("书的名字为《" + book.getName() + "》");
        }
    }
}

```

### 源码分析迭代器模式的典型应用

##### Java集合中的迭代器模式

看 java.util.ArrayList 类

```java
public class ArrayList<E> extends AbstractList<E> implements List<E>, RandomAccess, Cloneable, java.io.Serializable {
    transient Object[] elementData; // non-private to simplify nested class access
    private int size;

    public E get(int index) {
        rangeCheck(index);

        return elementData(index);
    }

    public boolean add(E e) {
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        elementData[size++] = e;
        return true;
    }

    public ListIterator<E> listIterator() {
        return new ListItr(0);
    }

    public ListIterator<E> listIterator(int index) {
        if (index < 0 || index > size)
            throw new IndexOutOfBoundsException("Index: "+index);
        return new ListItr(index);
    }

    public Iterator<E> iterator() {
        return new Itr();
    }

    private class Itr implements Iterator<E> {
        int cursor;       // index of next element to return
        int lastRet = -1; // index of last element returned; -1 if no such
        int expectedModCount = modCount;

        public boolean hasNext() {
            return cursor != size;
        }

        public E next() {
            //...
        }

        public E next() {
            //...
        }

        public void remove() {
            //...
        }
        //...
    }  

    private class ListItr extends Itr implements ListIterator<E> {
        public boolean hasPrevious() {
            return cursor != 0;
        }

        public int nextIndex() {
            return cursor;
        }

        public int previousIndex() {
            return cursor - 1;
        }

        public E previous() {
            //...
        }

        public void set(E e) {
            //...
        }

        public void add(E e) {
            //...
        }
    //...
}
```

从 ArrayList 源码中看到了有两个迭代器 Itr 和 ListItr，分别实现 Iterator 和 ListIterator 接口；

第一个当然很容易看明白，它跟我们示例的迭代器的区别是这里是一个内部类，可以直接使用 ArrayList 的数据列表；第二个迭代器是第一次见到， ListIterator 跟 Iterator 有什么区别呢？

先看 ListIterator 源码

```java
public interface ListIterator<E> extends Iterator<E> {
    boolean hasNext();
    E next();
    boolean hasPrevious();  // 返回该迭代器关联的集合是否还有上一个元素
    E previous();           // 返回该迭代器的上一个元素
    int nextIndex();        // 返回列表中ListIterator所需位置后面元素的索引
    int previousIndex();    // 返回列表中ListIterator所需位置前面元素的索引
    void remove();
    void set(E var1);       // 从列表中将next()或previous()返回的最后一个元素更改为指定元素e
    void add(E var1);   
}
```

接着是 Iterator 的源码

```java
public interface Iterator<E> {
    boolean hasNext();
    E next();

    default void remove() {
        throw new UnsupportedOperationException("remove");
    }

    // 备注：JAVA8允许接口方法定义默认实现
    default void forEachRemaining(Consumer<? super E> action) {
        Objects.requireNonNull(action);
        while (hasNext())
            action.accept(next());
    }
}
```
可以看出 ListIterator 的 add、set、remove 方法会直接改变原来的 List 对象，而且可以通过 previous 反向遍历

##### Mybatis中的迭代器模式
当查询数据库返回大量的数据项时可以使用游标 Cursor，利用其中的迭代器可以懒加载数据，避免因为一次性加载所有数据导致内存奔溃，Mybatis 为 Cursor 接口提供了一个默认实现类 DefaultCursor，代码如下
```java
public interface Cursor<T> extends Closeable, Iterable<T> {
    boolean isOpen();
    boolean isConsumed();
    int getCurrentIndex();
}

public class DefaultCursor<T> implements Cursor<T> {
    private final DefaultResultSetHandler resultSetHandler;
    private final ResultMap resultMap;
    private final ResultSetWrapper rsw;
    private final RowBounds rowBounds;
    private final ObjectWrapperResultHandler<T> objectWrapperResultHandler = new ObjectWrapperResultHandler<T>();

    // 游标迭代器
    private final CursorIterator cursorIterator = new CursorIterator(); 

    protected T fetchNextUsingRowBound() {
        T result = fetchNextObjectFromDatabase();
        while (result != null && indexWithRowBound < rowBounds.getOffset()) {
            result = fetchNextObjectFromDatabase();
        }
        return result;
    }

    @Override
    public Iterator<T> iterator() {
        if (iteratorRetrieved) {
            throw new IllegalStateException("Cannot open more than one iterator on a Cursor");
        }
        iteratorRetrieved = true;
        return cursorIterator;
    }

    private class CursorIterator implements Iterator<T> {

        T object;
        int iteratorIndex = -1;

        @Override
        public boolean hasNext() {
            if (object == null) {
                object = fetchNextUsingRowBound();
            }
            return object != null;
        }

        @Override
        public T next() {
            T next = object;

            if (next == null) {
                next = fetchNextUsingRowBound();
            }

            if (next != null) {
                object = null;
                iteratorIndex++;
                return next;
            }
            throw new NoSuchElementException();
        }

        @Override
        public void remove() {
            throw new UnsupportedOperationException("Cannot remove element from Cursor");
        }
    }
    // ...
}
```


游标迭代器 CursorIterator 实现了 java.util.Iterator 迭代器接口，这里的迭代器模式跟 ArrayList 中的迭代器几乎一样

```java

```




```java

```




```java

```



```java

```



```java

```

迭代器模式的优缺点

迭代器模式的优点有：

简化了遍历方式，对于对象集合的遍历，还是比较麻烦的，对于数组或者有序列表，我们尚可以通过游标来取得，但用户需要在对集合了解很清楚的前提下，自行遍历对象，但是对于hash表来说，用户遍历起来就比较麻烦了。而引入了迭代器方法后，用户用起来就简单的多了。
可以提供多种遍历方式，比如说对有序列表，我们可以根据需要提供正序遍历，倒序遍历两种迭代器，用户用起来只需要得到我们实现好的迭代器，就可以方便的对集合进行遍历了。
封装性良好，用户只需要得到迭代器就可以遍历，而对于遍历算法则不用去关心。
迭代器模式的缺点：

对于比较简单的遍历（像数组或者有序列表），使用迭代器方式遍历较为繁琐，大家可能都有感觉，像ArrayList，我们宁可愿意使用for循环和get方法来遍历集合。
迭代器模式的适用场景

迭代器模式是与集合共生共死的，一般来说，我们只要实现一个集合，就需要同时提供这个集合的迭代器，就像java中的Collection，List、Set、Map等，这些集合都有自己的迭代器。假如我们要实现一个这样的新的容器，当然也需要引入迭代器模式，给我们的容器实现一个迭代器。

但是，由于容器与迭代器的关系太密切了，所以大多数语言在实现容器的时候都给提供了迭代器，并且这些语言提供的容器和迭代器在绝大多数情况下就可以满足我们的需要，所以现在需要我们自己去实践迭代器模式的场景还是比较少见的，我们只需要使用语言中已有的容器和迭代器就可以了。
