# 观察者模式

在软件系统中经常会有这样的需求：如果一个对象的状态发生改变，
某些与它相关的对象也要随之做出相应的变化。
比如，我们要设计一个右键菜单的功能，只要在软件的有效区域内点击鼠标右键，
就会弹出一个菜单；再比如，我们要设计一个自动部署的功能，就像eclipse开发时，
只要修改了文件，eclipse就会自动将修改的文件部署到服务器中。
这两个功能有一个相似的地方，那就是一个对象要时刻监听着另一个对象，
只要它的状态一发生改变，自己随之要做出相应的行动。
其实，能够实现这一点的方案很多，但是，无疑使用观察者模式是一个主流的选择。

### 观察者模式的结构

在最基础的观察者模式中，包括以下四个角色：

* 被观察者：从类图中可以看到，类中有一个用来存放观察者对象的Vector容器（之所以使用Vector而不使用List，是因为多线程操作时，Vector在是安全的，而List则是不安全的），这个Vector容器是被观察者类的核心，另外还有三个方法：attach方法是向这个容器中添加观察者对象；detach方法是从容器中移除观察者对象；notify方法是依次调用观察者对象的对应方法。这个角色可以是接口，也可以是抽象类或者具体的类，因为很多情况下会与其他的模式混用，所以使用抽象类的情况比较多。
* 观察者：观察者角色一般是一个接口，它只有一个update方法，在被观察者状态发生变化时，这个方法就会被触发调用。
* 具体的被观察者：使用这个角色是为了便于扩展，可以在此角色中定义具体的业务逻辑。
* 具体的观察者：观察者接口的具体实现，在这个角色中，将定义被观察者对象状态发生变化时所要处理的逻辑。

### 优点

观察者与被观察者之间是属于轻度的关联关系，并且是抽象耦合的，这样，对于两者来说都比较容易进行扩展。

观察者模式是一种常用的触发机制，它形成一条触发链，依次对各个观察者的方法进行处理。但同时，这也算是观察者模式一个缺点，由于是链式触发，当观察者比较多的时候，性能问题是比较令人担忧的。并且，在链式结构中，比较容易出现循环引用的错误，造成系统假死。


### 代码展示

##### 示例一
```java
package designpatterns.observer.jike;

public interface Observer {
    void update();
}

```

```java
package designpatterns.observer.jike;

public class ConcreteObserver1 implements Observer {
    public void update() {
        System.out.println("观察者1收到信息，并进行处理。");
    }
}

```

```java
package designpatterns.observer.jike;

public class ConcreteObserver2 implements Observer {
    public void update() {
        System.out.println("观察者2收到信息，并进行处理。");
    }
}

```

```java
package designpatterns.observer.jike;

import java.util.Vector;

public abstract class Subject {
    private Vector<Observer> obs = new Vector();

    public void addObserver(Observer obs){
        this.obs.add(obs);
    }
    public void delObserver(Observer obs){
        this.obs.remove(obs);
    }
    protected void notifyObserver(){
        for(Observer o : obs){
            o.update();
        }
    }
    public abstract void doSomething();


}

```

```java
package designpatterns.observer.jike;

public class ConcreteSubject extends Subject {
    public void doSomething(){
        System.out.println("被观察者事件反生");
        this.notifyObserver();
    }
}

```

```java
package designpatterns.observer.jike;

public class Client {
    public static void main(String[] args) {
        Subject sub = new ConcreteSubject();
        sub.addObserver(new ConcreteObserver1()); //添加观察者1
        sub.addObserver(new ConcreteObserver2()); //添加观察者2
        sub.doSomething();
    }
}

```

##### 示例二

```java
package designpatterns.observer.bky;

public interface Observer {
    void update(String message, String name);
}

```

```java
package designpatterns.observer.bky;

public interface HuaiRen {
    //添加便衣观察者
    void addObserver(Observer observer);
    //移除便衣观察者
    void removeObserver(Observer observer);
    //通知观察者
    void notice(String message);
}

```

```java
package designpatterns.observer.bky;

import java.util.ArrayList;
import java.util.List;

public class XianFan implements HuaiRen {
    //别称
    private String name = "大熊";
    //定义观察者集合
    private List<Observer> observerList = new ArrayList<Observer>();

    //增加观察者
    @Override
    public void addObserver(Observer observer) {
        if (!observerList.contains(observer)) {
            observerList.add(observer);
        }
    }

    //移除观察者
    @Override
    public void removeObserver(Observer observer) {
        if (observerList.contains(observer)) {
            observerList.remove(observer);
        }
    }

    //通知观察者
    @Override
    public void notice(String message) {
        for (Observer observer : observerList) {
            observer.update(message, name);
        }
    }
}

```

```java
package designpatterns.observer.bky;

public class BianYi implements Observer {
    //定义姓名
    private String bName = "张昊天";

    @Override
    public void update(String message, String name) {
        System.out.println(bName + ":" + name + "那里有新情况：" + message);

    }
}

```

```java
package designpatterns.observer.bky;

public class Clienter {
    public static void main(String[] args) {
        //定义两个嫌犯
        HuaiRen xf1 = new XianFan();
//        Huairen xf2 = new XianFan2();
        //定义三个观察便衣警察
        Observer o1 = new BianYi();
//        Observer o2 = new Bianyi2();
//        Observer o3 = new Bianyi3();
        //为嫌犯增加观察便衣
        xf1.addObserver(o1);
//        xf1.addObserver(o2);
//        xf2.addObserver(o1);
//        xf2.addObserver(o3);
        //定义嫌犯1的情况
        String message1 = "又卖了一批货";
        String message2 = "老大要下来视察了";
        xf1.notice(message1);
//        xf2.notice(message2);
    }
}

```

### 总结

java语言中，有一个接口Observer，以及它的实现类Observable，对观察者角色常进行了实现。我们可以在jdk的api文档具体查看这两个类的使用方法。

做过VC++、javascript DOM或者AWT开发的朋友都对它们的事件处理感到神奇，
了解了观察者模式，就对事件处理机制的原理有了一定的了解了。
如果要设计一个事件触发处理机制的功能
，使用观察者模式是一个不错的选择，AWT中的事件处理DEM
（委派事件模型Delegation Event Model）就是使用观察者模式实现的。

观察者模式，又可以称之为发布-订阅模式，观察者，顾名思义，就是一个监听者，类似监听器的存在，一旦被观察/监听的目标发生的情况，就会被监听者发现，这么想来目标发生情况到观察者知道情况，其实是由目标将情况发送到观察者的。

观察者模式多用于实现订阅功能的场景，例如微博的订阅，当我们订阅了某个人的微博账号，当这个人发布了新的消息，就会通知我们。

关键点：

1. 针对观察者与被观察者分别定义接口，有利于分别进行扩展。
2. 重点就在被观察者的实现中：
   * 定义观察者集合，并定义针对集合的添加、删除操作，用于增加、删除订阅者（观察者）
   * 定义通知方法，用于将新情况通知给观察者用户（订阅者用户）
   * 观察者中需要有个接收被观察者通知的方法。

观察者模式定义的是一对多的依赖关系，一个被观察者可以拥有多个观察者，并且通过接口对观察者与被观察者进行逻辑解耦，降低二者的直接耦合。

如此这般，想了一番之后，突然发现这种模式与桥接模式有点类似的感觉。

桥接模式也是拥有双方，同样是使用接口（抽象类）的方式进行解耦，使双方能够无限扩展而互不影响，其实二者还是有者明显的区别：

1. 主要就是使用场景不同，桥接模式主要用于实现抽象与实现的解耦，主要目的也正是如此，为了双方的自由扩展而进行解耦，这是一种多对多的场景。观察者模式侧重于另一方面的解耦，侧重于监听方面，侧重于一对多的情况，侧重于一方发生情况，多方能获得这个情况的场景。
2. 另一方面就是编码方面的不同，在观察者模式中存在许多独有的内容，如观察者集合的操作，通知的发送与接收，而在桥接模式中只是简单的接口引用。

