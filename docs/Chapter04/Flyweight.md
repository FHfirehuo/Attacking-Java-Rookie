# 享元模式

享元模式（Flyweight Pattern）主要用于减少创建对象的数量，以减少内存占用和提高性能。这种类型的设计模式属于结构型模式，它提供了减少对象数量从而改善应用所需的对象结构的方式。

享元模式尝试重用现有的同类对象，如果未找到匹配的对象，则创建新对象。我们将通过创建 5 个对象来画出 20 个分布于不同位置的圆来演示这种模式。由于只有 5 种可用的颜色，所以 color 属性被用来检查现有的 Circle 对象。

享元模式：“享”就是分享之意，指一物被众人共享，而这也正是该模式的终旨所在。

享元模式有点类似于单例模式，都是只生成一个对象来被共享使用。这里有个问题，那就是对共享对象的修改，为了避免出现这种情况，我们将这些对象的公共部分，或者说是不变化的部分抽取出来形成一个对象。这个对象就可以避免到修改的问题。

享元的目的是为了减少不会要额内存消耗，将多个对同一对象的访问集中起来，不必为每个访问者创建一个单独的对象，以此来降低内存的消耗。


### 介绍
* 意图：运用共享技术有效地支持大量细粒度的对象。
* 主要解决：在有大量对象时，有可能会造成内存溢出，我们把其中共同的部分抽象出来，如果有相同的业务请求，直接返回在内存中已有的对象，避免重新创建。
* 何时使用： 
   1. 系统中有大量对象。 
   2. 这些对象消耗大量内存。 
   3. 这些对象的状态大部分可以外部化。 
   4. 这些对象可以按照内蕴状态分为很多组，当把外蕴对象从对象中剔除出来时，每一组对象都可以用一个对象来代替。 
   5. 系统不依赖于这些对象身份，这些对象是不可分辨的。
* 如何解决：用唯一标识码判断，如果在内存中有，则返回这个唯一标识码所标识的对象。
* 关键代码：用 HashMap 存储这些对象。

### 应用实例

1. JAVA 中的 String，如果有则返回，如果没有则创建一个字符串保存在字符串缓存池里面。 
2. 数据库的数据池。

### 优点
大大减少对象的创建，降低系统的内存，使效率提高。

### 缺点
提高了系统的复杂度，需要分离出外部状态和内部状态，而且外部状态具有固有化的性质，不应该随着内部状态的变化而变化，否则会造成系统的混乱。

### 使用场景
1. 系统有大量相似对象。 
2. 需要缓冲池的场景。

当我们项目中创建很多对象，而且这些对象存在许多相同模块，
这时，我们可以将这些相同的模块提取出来采用享元模式生成单一对象，
再使用这个对象与之前的诸多对象进行配合使用，
这样无疑会节省很多空间。

### 注意事项： 
1. 注意划分外部状态和内部状态，否则可能会引起线程安全问题。 
2. 这些类必须有一个工厂对象加以控制。

### 其实在Java中就存在这种类型的实例：String。

Java中将String类定义为final（不可改变的），
JVM中字符串一般保存在字符串常量池中，这个字符串常量池在jdk 6.0以前是位于常量池中，
位于永久代，而在JDK 7.0中，JVM将其从永久代拿出来放置于堆中。

我们使用如下代码定义的两个字符串指向的其实是同一个字符串常量池中的字符串值。

```java
1 String s1 = "abc";
2 String s2 = "abc";

```

如果我们以s1==s2进行比较的话所得结果为：true，因为s1和s2保存的是字符串常量池中的同一个字符串地址。
这就类似于我们今天所讲述的享元模式，
字符串一旦定义之后就可以被共享使用，因为他们是不可改变的，
同时被多处调用也不会存在任何隐患。

### 代码展示

```java
package designpatterns.flyweight;

public interface Jianzhu {
    void use();
}

```

```java
package designpatterns.flyweight;

public class TiYuGuan implements Jianzhu {

    private String name;
    private String shape;
    private String yundong;

    public TiYuGuan(String yundong) {
        this.setYundong(yundong);
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getShape() {
        return shape;
    }

    public void setShape(String shape) {
        this.shape = shape;
    }

    public String getYundong() {
        return yundong;
    }

    public void setYundong(String yundong) {
        this.yundong = yundong;
    }

    public void use() {
        System.out.println("该体育馆被使用来召开奥运会" + "  运动为：" + yundong + "  形状为：" + shape + "  名称为：" + name);
    }
}

```

```java
package designpatterns.flyweight;

import java.util.HashMap;
import java.util.Map;

public class JianZhuFactory {

    private static final Map<String, TiYuGuan> tygs = new HashMap<String, TiYuGuan>();

    public static TiYuGuan getTyg(String yundong) {
        TiYuGuan tyg = tygs.get(yundong);
        if (tyg == null) {
            tyg = new TiYuGuan(yundong);
            tygs.put(yundong, tyg);
        }
        return tyg;
    }

    public static int getSize() {
        return tygs.size();
    }
}

```

```java
package designpatterns.flyweight;

/**
 * 使用工厂模式进行配合，创建对象池，
 * 测试类中的循环，你可以想象成为要举行5场比赛，每场比赛的场地就是体育馆
 *
 * 通过执行结果可以看出，在这个对象池（HashMap）中，
 * 一直都只有一个对象存在，第一次使用的时候创建对象，
 * 之后的每次调用都用的是那个对象，不会再重新创建。
 */
public class FlyweightMain {
    public static void main(String[] args) {
        String yundong ="足球";
        for(int i = 1;i <= 5;i++){
            TiYuGuan tyg = JianZhuFactory.getTyg(yundong);
            tyg.setName("中国体育馆");
            tyg.setShape("圆形");
            tyg.use();
            System.out.println("对象池中对象数量为："+JianZhuFactory.getSize());
        }
    }
}

```


