# 责任链

责任链（chain of responsibility）模式很像异常的捕获和处理，
当一个问题发生的时候，当前对象看一下自己是否能够处理，
不能的话将问题抛给自己的上级去处理，
但是要注意这里的上级不一定指的是继承关系的父类，
这点和异常的处理是不一样的。

所以可以这样说，当问题不能解决的时候，将问题交给另一个对象去处理，就这样一直传递下去直至当前对象找不到下线了，处理结束。

### 在实际中的应用
* try-catch语句

每一个catch语句是根据Exception异常类型进行匹配的，一般会有多个catch语句，就形成了一个责任链；
此时如果有一个catch语句与当前所要处理的异常Exception符合时，该Exception就会交给相应的catch语句进行处理，之后的catch语句就不会再执行了。

* 异常处理机制
方法的调用构成了一个栈，当栈顶的方法产生异常时，需要将异常抛出，被抛出的异常沿着调用栈向下发展，寻找一个处理的块，被栈顶抛出的方法作为一个请求，而调用栈上的每一个方法就相当于一个handler，该Handler即可以选择自行处理这个被抛出的异常，也可以选择将异常沿着调用栈传递下去。
异常：请求
调用栈中的每一级：Handler
调用栈中的handler：责任链
栈底元素：上一级元素的直接后继

* 过滤器链（一般链条中只有一个对象处理请求，但是过滤器链可以有多个对象同时处理请求）

* Spring Security框架
通过多个filter类构成一个链条来处理Http请求，从而为应用提供一个认证与授权的框架。

### 责任链模式内部处理
在责任链模式中，作为请求接受者的多个对象通过对其后继的引用而连接起来形成一条链。
请求在这条链上传递，直到链上某一个接收者处理这个请求。
每个接收者都可以选择自行处理请求或是向后继传递请求

Handler设了一个自身类型的对象作为其后继，Handler是抽象的，从而整条链也是抽象的，
这种抽象的特性使得在运行时可以动态的绑定链条中的对象，从而提供了足够的空间。

在代码中直接后继successor的类型是PriceHandler,而不是任何其他具体的类（Sales、Manager等），
使得在后面变更需求时，加入了lead层次，可以简单的实现。
所以责任链模式遵循了OO中的依赖倒置原则，即依赖于抽象而非依赖于具体。降低了程序的耦合度。

发出请求的客户端并不知道链上的哪一个接收者会处理这个请求，
从而实现了客户端和接收者之间的解耦。

###  责任链模式的优缺点
* 开闭原则：对扩展开放，对变更关闭；

有业务变更时，希望通过新增一个类，而非修改原有的代码来满足业务需求。

* 执行性能：在结构上，责任链模式由处理器首尾相接构成的一条链，当由请求到来之时，需要从链的头部开始遍历整条责任链，直到有一个处理器处理了请求，或者是整个链条遍历完成。
在这个过程中性能的损耗体现在两个方面：
   1. 时间：相对于单个handler处理请求的时间而言，整个链条遍历的过程可能会消耗更多的时间。
   2. 内存：创建了大量的对象来表示处理器对象，但是实际仅仅使用了其中的少部分，剩余的大部分处理器都未被使用到。

### 代码展示

```java
package designpatterns.chainofresponsibility.cor;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class Trouble {

    private int number;


    public String toString() {
        return "问题编号：[" + number + "]";
    }
}

```


```java
package designpatterns.chainofresponsibility.cor;

/**
 * （抽象类，使用了模板方法）
 */
public abstract class Support {
    protected abstract boolean resolve(Trouble trouble);

    String name;
    Support next;

    public Support(String name) {
        this.name = name;
    }

    public String toString() {
        return "对象：<" + name + ">";
    }

    public Support setAndReturnNext(Support next) {
        this.next = next;
        return next;
    }

    public final void support(Trouble trouble) {
        if (resolve(trouble)) {
            done(trouble);
        } else if (next != null) {
            next.support(trouble);
        } else {
            fail(trouble);
        }
    }

    protected void fail(Trouble trouble) {
        System.out.println(this + "解决问题失败，" + trouble);
    }

    protected void done(Trouble trouble) {
        System.out.println(this + "已经解决问题，" + trouble);
    }
}

```


```java
package designpatterns.chainofresponsibility.cor;

public class LimitSupport extends Support {

    private int limit;

    public LimitSupport(String name, int limit) {
        super(name);
        this.limit = limit;
    }

    protected boolean resolve(Trouble trouble) {
        return trouble.getNumber() <= limit ? true : false;
    }
}

```


```java
package designpatterns.chainofresponsibility.cor;

public class NoSupport extends Support {

    public NoSupport(String name) {
        super(name);
    }

    protected boolean resolve(Trouble trouble) {
        return false;
    }
}

```


```java
package designpatterns.chainofresponsibility.cor;

public class OddSupport extends Support {


    public OddSupport(String name) {
        super(name);
    }

    protected boolean resolve(Trouble trouble) {
        return (trouble.getNumber() % 2) == 1 ? true : false;
    }
}

```


```java
package designpatterns.chainofresponsibility.cor;

public class SpecialSupport extends Support {

    public int specialNumber;

    public SpecialSupport(String name, int specialNumber) {
        super(name);
        this.specialNumber = specialNumber;
    }

    protected boolean resolve(Trouble trouble) {
        return trouble.getNumber() == specialNumber ? true : false;
    }
}

```

```java
package designpatterns.chainofresponsibility.cor;

public class Main {

    public static void main(String[] args) {
        Support limitSupportLess = new LimitSupport("有限支持小", 5);
        Support limitSupportMore = new LimitSupport("有限支持大", 15);
        Support oddSupport = new OddSupport("奇数支持");
        Support specialSupport = new SpecialSupport("特定支持", 36);
        Support noSupport = new NoSupport("没有支持");
        limitSupportLess.setAndReturnNext(limitSupportMore).setAndReturnNext(oddSupport).setAndReturnNext(specialSupport).setAndReturnNext(noSupport);
        System.out.println("===<有限支持小>尝试解决问题===");
        for (int i = 0; i < 40; i++) {
            limitSupportLess.support(new Trouble(i));
        }
        System.out.println("===<特定支持>尝试解决问题===");
        for (int i = 0; i < 40; i++) {
            specialSupport.support(new Trouble(i));
        }

    }
}

```
