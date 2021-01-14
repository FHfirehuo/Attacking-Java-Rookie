# 桥接模式

桥接（Bridge）是用于把抽象化与实现化解耦，使得二者可以独立变化。

这种类型的设计模式属于结构型模式，它通过提供抽象化和实现化之间的桥接结构，来实现二者的解耦。

这种模式涉及到一个作为桥接的接口，使得实体类的功能独立于接口实现类。

这两种类型的类可被结构化改变而互不影响。

### 介绍
* 意图：将抽象部分与实现部分分离，使它们都可以独立的变化。
* 主要解决：在有多种可能会变化的情况下，用继承会造成类爆炸问题，扩展起来不灵活。
* 何时使用：实现系统可能有多个角度分类，每一种角度都可能变化。
* 关键代码：抽象类依赖实现类。

### 应用实例： 
1. 猪八戒从天蓬元帅转世投胎到猪，转世投胎的机制将尘世划分为两个等级，即：灵魂和肉体，前者相当于抽象化，后者相当于实现化。生灵通过功能的委派，调用肉体对象的功能，使得生灵可以动态地选择。 
2. 墙上的开关，可以看到的开关是抽象的，不用管里面具体怎么实现的。

### 优点： 
1. 抽象和实现的分离。 
2. 优秀的扩展能力。 
3. 实现细节对客户透明。

### 缺点：
桥接模式的引入会增加系统的理解与设计难度，由于聚合关联关系建立在抽象层，要求开发者针对抽象进行设计与编程。

### 使用场景： 
1. 如果一个系统需要在构件的抽象化角色和具体化角色之间增加更多的灵活性，避免在两个层次之间建立静态的继承联系，通过桥接模式可以使它们在抽象层建立一个关联关系。 
2. 对于那些不希望使用继承或因为多层次继承导致系统类的个数急剧增加的系统，桥接模式尤为适用。 
3. 一个类存在两个独立变化的维度，且这两个维度都需要进行扩展。

### 注意事项
对于两个独立变化的维度，使用桥接模式再适合不过了。

### 个人理解：
桥接是一个接口，它与一方应该是绑定的，也就是解耦的双方中的一方必然是继承这个接口的，
这一方就是实现方，而另一方正是要与这一方解耦的抽象方，如果不采用桥接模式，
一般我们的处理方式是直接使用继承来实现，这样双方之间处于强链接，类之间关联性极强，
如要进行扩展，必然导致类结构急剧膨胀。采用桥接模式，正是为了避免这一情况的发生，
将一方与桥绑定，即实现桥接口，另一方在抽象类中调用桥接口（指向的实现类），
这样桥方可以通过实现桥接口进行单方面扩展，而另一方可以继承抽象类而单方面扩展，
而之间的调用就从桥接口来作为突破口，不会受到双方扩展的任何影响。

##### 下面的实例能真正体现着一点
实例准备：我们假设有一座桥，桥左边为A，桥右边为B，A有A1，A2，A3等，表示桥左边的三个不同地方，
B有B1，B2，B3等，表示桥右边的三个不同地方，假设我们要从桥左侧A出发到桥的右侧B，
我们可以有多重方案，A1到B1，A1到B2，A1到B3，A2到B1...等等

### 桥接模式模式的扩展
在软件开发中，有时桥接（Bridge）模式可与适配器模式联合使用。当桥接（Bridge）模式的实现化角色的接口与现有类的接口不一致时，
可以在二者中间定义一个适配器将二者连接起来

### 注意点

1. 定义一个桥接口，使其与一方绑定，这一方的扩展全部使用实现桥接口的方式。
2. 定义一个抽象类，来表示另一方，在这个抽象类内部要引入桥接口，而这一方的扩展全部使用继承该抽象类的方式。
其实我们可以发现桥接模式应对的场景有方向性的，桥绑定的一方都是被调用者，属于被动方，抽象方属于主动方。

其实我的JDK提供的JDBC数据库访问接口API正是经典的桥接模式的实现者，
接口内部可以通过实现接口来扩展针对不同数据库的具体实现来进行扩展，
而对外的仅仅只是一个统一的接口调用，调用方过于抽象，
可以将其看做每一个JDBC调用程序（这是真实实物，当然不存在抽象）

### 下面来理解一下开头的概念：

桥接（Bridge）是用于把抽象化与实现化解耦，使得二者可以独立变化。这种类型的设计模式属于结构型模式，
它通过提供抽象化和实现化之间的桥接结构，来实现二者的解耦。

这种模式涉及到一个作为桥接的接口，使得实体类的功能独立于接口实现类。
这两种类型的类可被结构化改变而互不影响。

##### 理解
此处抽象化与实现化分别指代实例中的双方，而且实现化对应目的地方（通过实现桥接口进行扩展），
抽象方对应来源地方（通过继承抽象类来进行扩展），如果我们不使用桥接模式，我们会怎么想实现这个实例呢？
很简单，我们分别定义来源地A1、A2、A3类和目的地B1、B2、B3，然后具体的实现就是，A1到B1一个类，A1到B2一个类，等，如果我们要扩展了A和B ,要直接增加An类和Bn类，如此编写不说类内部重复性代码多，而且还会导致类结构的急剧膨胀，最重要的是，在通过继承实现路径的时候，会造成双方耦合性增大，而这又进一步加剧了扩展的复杂性。使用桥结构模式可以很好地规避这些问题：重在解耦。

### 代码实现

##### 示例1
```java
package designpatterns.bridge.bky;

public interface Qiao {

    //目的地B
    void targetAreaB();
}

```

```java
package designpatterns.bridge.bky;

public abstract class AreaA {

    //引用桥接口
    Qiao qiao;
    //来源地
    abstract void fromAreaA();
}

```

```java
package designpatterns.bridge.bky;

/**
 * 来源地A1
 */
public class AreaA1 extends AreaA {
    void fromAreaA() {
        System.out.println("我来自A1");
        qiao.targetAreaB();
    }
}

```

```java
package designpatterns.bridge.bky;

public class AreaA2 extends AreaA {
    void fromAreaA() {

        System.out.println("我来自A2");
        qiao.targetAreaB();
    }
}

```

```java
package designpatterns.bridge.bky;

public class AreaA3 extends AreaA {
    void fromAreaA() {
        System.out.println("我来自A3");
        qiao.targetAreaB();
    }
}

```


```java
package designpatterns.bridge.bky;

/**
 * 目的地B1
 */
public class AreaB1 implements Qiao {
    public void targetAreaB() {
        System.out.println("我要去B1");
    }
}

```

```java
package designpatterns.bridge.bky;

public class AreaB2 implements Qiao {
    public void targetAreaB() {
        System.out.println("我要去B2");
    }
}

```

```java
package designpatterns.bridge.bky;

public class AreaB3 implements Qiao {
    public void targetAreaB() {
        System.out.println("我要去B3");
    }
}

```

```java
package designpatterns.bridge.bky;

public class QiaoMain {

    public static void main(String[] args) {
        AreaA a = new AreaA2();
        a.qiao = new AreaB3();
        a.fromAreaA();
//        a.qiao.targetAreaB();
    }
}

```

##### 示例2
```java
package designpatterns.bridge.csdn;

public interface Implementor {
    void OperationImpl();
}

```

```java
package designpatterns.bridge.csdn;

//抽象化角色
public abstract class Abstraction {
    protected Implementor imple;

    protected Abstraction(Implementor imple) {
        this.imple = imple;
    }

    public abstract void Operation();
}

```

```java
package designpatterns.bridge.csdn;

//具体实现化角色
public class ConcreteImplementorA implements Implementor {

    public void OperationImpl() {
        System.out.println("具体实现化(Concrete Implementor)角色被访问");
    }
}

```

```java
package designpatterns.bridge.csdn;

//扩展抽象化角色
public class RefinedAbstraction extends Abstraction {

    protected RefinedAbstraction(Implementor imple) {
        super(imple);
    }

    public void Operation() {
        System.out.println("扩展抽象化(Refined Abstraction)角色被访问");
        imple.OperationImpl();
    }
}

```

```java
package designpatterns.bridge.csdn;

public class BridgeTest {
    public static void main(String[] args) {
        Implementor imple = new ConcreteImplementorA();
        Abstraction abs = new RefinedAbstraction(imple);
        abs.Operation();
    }
}

```
