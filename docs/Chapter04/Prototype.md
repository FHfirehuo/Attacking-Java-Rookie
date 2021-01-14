# 原型模式

原型模式(Prototype Pattern)：使用原型实例指定创建对象的种类，并且通过拷贝这些原型创建新的对象。

原型模式是一种对象创建型模式。

原型模式的工作原理很简单：将一个原型对象传给那个要发动创建的对象，这个要发动创建的对象通过请求原型对象拷贝自己来实现创建过程。

原型模式是一种“另类”的创建型模式，创建克隆对象的工厂就是原型类自身，工厂方法由克隆方法来实现。

需要注意的是通过克隆方法所创建的对象是全新的对象，它们在内存中拥有新的地址，通常对克隆所产生的对象进行修改对原型对象不会造成任何影响，每一个克隆对象都是相互独立的。
通过不同的方式修改可以得到一系列相似但不完全相同的对象。

### 角色

* Prototype（抽象原型类）：它是声明克隆方法的接口，是所有具体原型类的公共父类，可以是抽象类也可以是接口，甚至还可以是具体实现类。
* ConcretePrototype（具体原型类）：它实现在抽象原型类中声明的克隆方法，在克隆方法中返回自己的一个克隆对象。
* Client（客户类）：让一个原型对象克隆自身从而创建一个新的对象，在客户类中只需要直接实例化或通过工厂方法等方式创建一个原型对象，再通过调用该对象的克隆方法即可得到多个相同的对象。
由于客户类针对抽象原型类Prototype编程，因此用户可以根据需要选择具体原型类，系统具有较好的可扩展性，增加或更换具体原型类都很方便。

### 核心
原型模式的核心在于如何实现克隆方法。


**使用原始模式的时候一定要注意为深克隆还是浅克隆。**


### 优点

当创建新的对象实例较为复杂时，使用原型模式可以简化对象的创建过程，通过复制一个已有实例可以提高新实例的创建效率。
扩展性较好，由于在原型模式中提供了抽象原型类，在客户端可以针对抽象原型类进行编程，而将具体原型类写在配置文件中，增加或减少产品类对原有系统都没有任何影响。
原型模式提供了简化的创建结构，工厂方法模式常常需要有一个与产品类等级结构相同的工厂等级结构，而原型模式就不需要这样，原型模式中产品的复制是通过封装在原型类中的克隆方法实现的，无须专门的工厂类来创建产品。
可以使用深克隆的方式保存对象的状态，使用原型模式将对象复制一份并将其状态保存起来，以便在需要的时候使用（如恢复到某一历史状态），可辅助实现撤销操作。

### 缺点

需要为每一个类配备一个克隆方法，而且该克隆方法位于一个类的内部，当对已有的类进行改造时，需要修改源代码，违背了“开闭原则”。
在实现深克隆时需要编写较为复杂的代码，而且当对象之间存在多重的嵌套引用时，为了实现深克隆，每一层对象对应的类都必须支持深克隆，实现起来可能会比较麻烦。

#### 适用场景

创建新对象成本较大（如初始化需要占用较长的时间，占用太多的CPU资源或网络资源），新的对象可以通过原型模式对已有对象进行复制来获得，如果是相似对象，则可以对其成员变量稍作修改。
如果系统要保存对象的状态，而对象的状态变化很小，或者对象本身占用内存较少时，可以使用原型模式配合备忘录模式来实现。
需要避免使用分层次的工厂类来创建分层次的对象，并且类的实例对象只有一个或很少的几个组合状态，通过复制原型对象得到新实例可能比使用构造函数创建一个新实例更加方便。

### 注意事项

使用原型模式复制对象不会调用类的构造方法。因为对象的复制是通过调用Object类的clone方法来完成的，它直接在内存中复制数据，因此不会调用到类的构造方法。不但构造方法中的代码不会执行，甚至连访问权限都对原型模式无效。还记得单例模式吗？单例模式中，只要将构造方法的访问权限设置为private型，就可以实现单例。但是clone方法直接无视构造方法的权限，所以，单例模式与原型模式是冲突的，在使用时要特别注意。
深拷贝与浅拷贝。Object类的clone方法只会拷贝对象中的基本的数据类型，对于数组、容器对象、引用对象等都不会拷贝，这就是浅拷贝。如果要实现深拷贝，必须将原型模式中的数组、容器对象、引用对象等另行拷贝。例如：

    PS：深拷贝与浅拷贝问题中，会发生深拷贝的有java中的8中基本类型以及他们的封装类型，另外还有String类型。其余的都是浅拷贝。

### 代码展示

定义产品
```java
package designpatterns.prototype;

public interface Product extends Cloneable {
    void use(String word);

    Product createClone();

    void setCh(char ch);
}

```

第一种实现
```java
package designpatterns.prototype;

public class Underline implements Product {
    char ch;

    public Underline(char ch) {
        this.ch = ch;
    }

    public void use(String word) {
        System.out.print(ch);
        System.out.print(word);
        System.out.println(ch);
        for (int i = 0; i < word.getBytes().length + 1; i++) {
            System.out.print(ch);
        }
        System.out.println();
    }

    public Product createClone() {
        Product p = null;
        try {
            p = (Product) clone();
        } catch (CloneNotSupportedException e) {
            e.printStackTrace();
        }
        return p;
    }

    public void setCh(char ch) {
        this.ch = ch;
    }
}

```

第二种实现
```java
package designpatterns.prototype;

public class MessageBox implements Product {
    char ch;

    public MessageBox(char ch) {
        this.ch = ch;
    }

    public void use(String word) {
        for (int i = 0; i < word.getBytes().length + 1; i++) {
            System.out.print(ch);
        }
        System.out.println();

        System.out.print(ch);
        System.out.print(word);
        System.out.println(ch);

        for (int i = 0; i < word.getBytes().length + 1; i++) {
            System.out.print(ch);
        }
        System.out.println();
    }

    public Product createClone() {
        Product p = null;
        try {
            p = (Product) clone();
        } catch (CloneNotSupportedException e) {
            e.printStackTrace();
        }
        return p;
    }

    public void setCh(char ch) {
        this.ch = ch;
    }
}

```

管理类
```java
package designpatterns.prototype;

import java.util.HashMap;

public class Manager {

    HashMap hashmap = new HashMap();

    public void register(String key, Product p) {
        hashmap.put(key, p);
    }

    public Product create(String key) {
        Product p = (Product) hashmap.get(key);
        return p.createClone();
    }
}

```

运行类
```java
package designpatterns.prototype;

public class PrototypeMain {
    public static void main(String[] args) {
        Manager m = new Manager();
        Product p1 = new Underline('@');
        m.register("line", p1);

        Product p2 = new MessageBox('$');
        m.register("msg", p2);
        Product p3 = m.create("line");
        p3.setCh('%');
        Product p4 = m.create("msg");
        p4.setCh('^');
        p1.use("fire");
        p2.use("huo");
        p3.use("love");
        p4.use("1314");

    }
}

```

运行结果
```console
@fire@
@@@@@
$$$$
$huo$
$$$$
%love%
%%%%%
^^^^^
^1314^
^^^^^

```

### Java语言提供的clone()方法

学过Java语言的人都知道，所有的Java类都继承自 java.lang.Object。事实上，Object 类提供一个 clone() 方法，可以将一个Java对象复制一份。因此在Java中可以直接使用 Object 提供的 clone() 方法来实现对象的克隆，Java语言中的原型模式实现很简单。

需要注意的是能够实现克隆的Java类必须实现一个 标识接口 Cloneable，表示这个Java类支持被复制。如果一个类没有实现这个接口但是调用了clone()方法，Java编译器将抛出一个 CloneNotSupportedException 异常。


### 原型模式的典型应用

##### Object 类中的 clone 接口
Cloneable 接口的实现类，可以看到至少一千多个，找几个例子譬如：


##### ArrayList 对 clone 的重写如下：

```java
public class ArrayList<E> extends AbstractList<E>
        implements List<E>, RandomAccess, Cloneable, java.io.Serializable {
    public Object clone() {
        try {
            ArrayList<?> v = (ArrayList<?>) super.clone();
            v.elementData = Arrays.copyOf(elementData, size);
            v.modCount = 0;
            return v;
        } catch (CloneNotSupportedException e) {
            // this shouldn't happen, since we are Cloneable
            throw new InternalError(e);
        }
    }
    //...省略
}
```

调用 super.clone(); 之后把 elementData 数据 copy 了一份

#####  HashMap 对 clone 方法的重写
```java
public class HashMap<K,V> extends AbstractMap<K,V> implements Map<K,V>, Cloneable, Serializable {
    @Override
    public Object clone() {
        HashMap<K,V> result;
        try {
            result = (HashMap<K,V>)super.clone();
        } catch (CloneNotSupportedException e) {
            // this shouldn't happen, since we are Cloneable
            throw new InternalError(e);
        }
        result.reinitialize();
        result.putMapEntries(this, false);
        return result;
    }
    // ...省略...
}
```

##### mybatis 中的 org.apache.ibatis.cache.CacheKey 对 clone 方法的重写：

```java
public class CacheKey implements Cloneable, Serializable {
    private List<Object> updateList;
    public CacheKey clone() throws CloneNotSupportedException {
        CacheKey clonedCacheKey = (CacheKey)super.clone();
        clonedCacheKey.updateList = new ArrayList(this.updateList);
        return clonedCacheKey;
    }
    // ... 省略...
}
```
这里又要注意，updateList 是 List<Object> 类型，所以可能是值类型的List，也可能是引用类型的List，克隆的结果需要注意是否为深克隆或者浅克隆

