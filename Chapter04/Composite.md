# 组合（Composite）模式

组合模式（Composite Pattern），又叫部分整体模式，是用于把一组相似的对象当作一个单一的对象。
组合模式依据树形结构来组合对象，用来表示部分以及整体层次。
这种类型的设计模式属于结构型模式，它创建了对象组的树形结构。

这种模式创建了一个包含自己对象组的类。该类提供了修改相同对象组的方式。

它是一种将对象组合成树状的层次结构的模式，用来表示“部分-整体”的关系，使用户对单个对象和组合对象具有一致的访问性。

这个模式在我们的生活中也经常使用，比如说如果读者有使用Java的GUI编写过程序的，
肯定少不了定义一些组件，初始化之后，然后使用容器的add方法，将这些组件有顺序的组织成一个界面出来；
或者读者如果编写过前端的页面，肯定使用过<div>等标签定义一些格式，然后格式之间互相组合，
通过一种递归的方式组织成相应的结构，这种方式其实就是组合，将部分的组件镶嵌到整体之中；
又或者文件和文件夹的组织关系，通过目录表项作为共同的特质（父类），一个文件夹可以包含多个文件夹和多个文件，
一个文件容纳在一个文件夹之中。那么凭什么可以这样做呢，需要满足以下两点，
* 首先整体的结构应该是一棵树，
* 第二，所有的组件应该有一个共同的父类（有共同的本质），这个父类使得组件中的共同的本质可以提取出来
（有了共同语言（父类）），进行互融，其实就是父类使用add方法，这样子类就可以通过抽象的方式通过父类来表达了，
可能有点绕口

### 介绍
* 意图：将对象组合成树形结构以表示"部分-整体"的层次结构。组合模式使得用户对单个对象和组合对象的使用具有一致性。
* 主要解决：它在我们树型结构的问题中，模糊了简单元素和复杂元素的概念，客户程序可以向处理简单元素一样来处理复杂元素，从而使得客户程序与复杂元素的内部结构解耦。
* 何时使用： 
   1. 您想表示对象的部分-整体层次结构（树形结构）。 
   2. 您希望用户忽略组合对象与单个对象的不同，用户将统一地使用组合结构中的所有对象。
* 如何解决：树枝和叶子实现统一接口，树枝内部组合该接口。
* 关键代码：树枝内部组合该接口，并且含有内部属性 List，里面放 Component。

### 应用实例：
1. 算术表达式包括操作数、操作符和另一个操作数，其中，另一个操作符也可以是操作数、操作符和另一个操作数。
2. 在 JAVA AWT 和 SWING 中，对于 Button 和 Checkbox 是树叶，Container 是树枝。

### 优点
1. 高层模块调用简单。
2. 节点自由增加。

组合模式使得客户端代码可以一致地处理单个对象和组合对象，无须关心自己处理的是单个对象，还是组合对象，这简化了客户端代码；
更容易在组合体内加入新的对象，客户端不会因为加入了新的对象而更改源代码，满足“开闭原则”；


### 缺点
在使用组合模式时，其叶子和树枝的声明都是实现类，而不是接口，违反了依赖倒置原则。

设计较复杂，客户端需要花更多时间理清类之间的层次关系；不容易限制容器中的构件；不容易用继承的方法来增加构件的新功能；

### 使用场景
部分、整体场景，如树形菜单，文件、文件夹的管理。

在需要表示一个对象整体与部分的层次结构的场合。
要求对用户隐藏组合对象与单个对象的不同，用户可以用统一的接口使用组合结构中的所有对象的场合。

### 注意事项
定义时为具体类。

### 代码展示

##### 示例一
```java
package designpatterns.composite.shopping;

//抽象构件：物品
public interface Articles {

    public float calculation(); //计算
    public void show();
}

```

```java
package designpatterns.composite.shopping;

import java.util.ArrayList;

//树枝构件：袋子
public class Bags implements Articles {

    private String name;     //名字
    private ArrayList<Articles> bags = new ArrayList<Articles>();

    public Bags(String name) {
        this.name = name;
    }

    public void add(Articles c) {
        bags.add(c);
    }

    public void remove(Articles c) {
        bags.remove(c);
    }

    public Articles getChild(int i) {
        return bags.get(i);
    }

    public float calculation() {
        float s = 0;
        for (Object obj : bags) {
            s += ((Articles) obj).calculation();
        }
        return s;
    }

    public void show() {
        for (Object obj : bags) {
            ((Articles) obj).show();
        }
    }
}

```

```java
package designpatterns.composite.shopping;

//树叶构件：商品
public class Goods implements Articles {

    private String name;     //名字
    private int quantity;    //数量
    private float unitPrice; //单价

    public Goods(String name, int quantity, float unitPrice) {
        this.name = name;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
    }

    public float calculation() {
        return quantity * unitPrice;
    }

    public void show() {
        System.out.println(name + "(数量：" + quantity + "，单价：" + unitPrice + "元)");
    }
}

```

```java
package designpatterns.composite.shopping;

public class ShoppingTest {
    public static void main(String[] args) {


        float s = 0;
        Bags BigBag, mediumBag, smallRedBag, smallWhiteBag;
        Goods sp;
        BigBag = new Bags("大袋子");
        mediumBag = new Bags("中袋子");
        smallRedBag = new Bags("红色小袋子");
        smallWhiteBag = new Bags("白色小袋子");
        sp = new Goods("婺源特产", 2, 7.9f);
        smallRedBag.add(sp);
        sp = new Goods("婺源地图", 1, 9.9f);
        smallRedBag.add(sp);
        sp = new Goods("韶关香菇", 2, 68);
        smallWhiteBag.add(sp);
        sp = new Goods("韶关红茶", 3, 180);
        smallWhiteBag.add(sp);
        sp = new Goods("景德镇瓷器", 1, 380);
        mediumBag.add(sp);
        mediumBag.add(smallRedBag);
        sp = new Goods("李宁牌运动鞋", 1, 198);
        BigBag.add(sp);
        BigBag.add(smallWhiteBag);
        BigBag.add(mediumBag);
        System.out.println("您选购的商品有：");
        BigBag.show();
        s = BigBag.calculation();
        System.out.println("要支付的总价是：" + s + "元");
    }
}

```

##### 示例二
```java
package designpatterns.composite.zyr;

/**
 * Entry 抽象类：共同特质
 */
public abstract class Entry {

    public abstract String getName();

    public abstract int getSize();

    public abstract void printList(String prefix);

    public void printList() {
        printList("");
    }

    public Entry add(Entry entry) throws RuntimeException {
        throw new RuntimeException();
    }

    public String toString() {
        return getName() + "<" + getSize() + ">";
    }
}

```

```java
package designpatterns.composite.zyr;

/**
 * File 类：实现类，叶子结点
 */
public class File extends Entry {


    private String name;
    private int size;

    public File(String name, int size) {
        this.name = name;
        this.size = size;
    }

    public String getName() {
        return name;
    }

    public int getSize() {
        return size;
    }

    public void printList(String prefix) {
        System.out.println(prefix + "/" + this);
    }
}

```

```java
package designpatterns.composite.zyr;

import java.util.ArrayList;
import java.util.Iterator;

public class Directory extends Entry {

    String name;
    ArrayList entrys = new ArrayList();

    public Directory(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public int getSize() {
        int size = 0;
        Iterator it = entrys.iterator();
        while (it.hasNext()) {
            size += ((Entry) it.next()).getSize();
        }
        return size;
    }

    public Entry add(Entry entry) {
        entrys.add(entry);
        return this;
    }

    public void printList(String prefix) {
        System.out.println(prefix + "/" + this);
        Iterator it = entrys.iterator();
        Entry entry;
        while (it.hasNext()) {
            entry = (Entry) it.next();
            entry.printList(prefix + "/" + name);
        }
    }
}

```

```java
package designpatterns.composite.zyr;

public class CompositeZYRMain {


    public static void main(String[] args) {
        Directory life = new Directory("我的生活");
        File eat = new File("吃火锅", 100);
        File sleep = new File("睡觉", 100);
        File study = new File("学习", 100);
        life.add(eat);
        life.add(sleep);
        life.add(study);

        Directory work = new Directory("我的工作");
        File write = new File("写博客", 200);
        File paper = new File("写论文", 200);
        File homework = new File("写家庭作业", 200);
        work.add(write);
        work.add(paper);
        work.add(homework);

        Directory relax = new Directory("我的休闲");
        File music = new File("听听音乐", 200);
        File walk = new File("出去转转", 200);
        relax.add(music);
        relax.add(walk);

        Directory read = new Directory("我的阅读");
        File book = new File("学习书籍", 200);
        File novel = new File("娱乐小说", 200);
        read.add(book);
        read.add(novel);


        Directory root = new Directory("根目录");

        root.add(life);
        root.add(work);
        root.add(relax);
        root.add(read);

        root.printList("D:");
        System.out.println("=================");
        work.printList("work");
        System.out.println("=================");
        novel.printList("novel");
    }
}

```

