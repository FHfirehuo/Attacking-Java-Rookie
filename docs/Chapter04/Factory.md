# 工厂模式

工厂模式(Factory Pattern)是Java中最常用的设计模式之一。
这种类型的设计模式属于创建型模式，它提供了一种创建对象的最佳方式。

在工厂模式中，我们在创建对象时不会对客户端暴露创建逻辑，并且是通过使用一个共同的接口来指向新创建的对象。

### 介绍

* 意图：定义一个创建对象的接口，让其子类自己决定实例化哪一个工厂类，工厂模式使其创建过程延迟到子类进行。
* 主要解决：主要解决接口选择的问题。
* 何时使用：我们明确地计划不同条件下创建不同实例时。
* 如何解决：让其子类实现工厂接口，返回的也是一个抽象的产品。
* 关键代码：创建过程在其子类执行。

### 应用实例： 

1. 您需要一辆汽车，可以直接从工厂里面提货，而不用去管这辆汽车是怎么做出来的，以及这个汽车里面的具体实现。 
2. Hibernate 换数据库只需换方言和驱动就可以。

### 优点 
1. 一个调用者想创建一个对象，只要知道其名称就可以了。 
2. 扩展性高，如果想增加一个产品，只要扩展一个工厂类就可以。 
3. 屏蔽产品的具体实现，调用者只关心产品的接口。

### 缺点

每次增加一个产品时，都需要增加一个具体类和对象实现工厂，使得系统中类的个数成倍增加，
在一定程度上增加了系统的复杂度，同时也增加了系统具体类的依赖。这并不是什么好事。

### 使用场景： 

1. 日志记录器：记录可能记录到本地硬盘、系统事件、远程服务器等，用户可以选择记录日志到什么地方。 
2. 数据库访问，当用户不知道最后系统采用哪一类数据库，以及数据库可能有变化时。 
3. 设计一个连接服务器的框架，需要三个协议，"POP3"、"IMAP"、"HTTP"，可以把这三个作为产品类，共同实现一个接口。

### 注意事项

作为一种创建类模式，在任何需要生成复杂对象的地方，都可以使用工厂方法模式。
有一点需要注意的地方就是复杂对象适合使用工厂模式，
而简单对象，特别是只需要通过 new 就可以完成创建的对象，无需使用工厂模式。
如果使用工厂模式，就需要引入一个工厂类，会增加系统的复杂度。

### 代码展示

定义发动机

```java
package designpatterns.factory;

public class Engine {

    public void getStyle(){
        System.out.println("这是汽车的发动机");
    }
}

```

定义地盘
```java
package designpatterns.factory;

public class UnderPan {

    public void getStyle(){
        System.out.println("这是汽车的底盘");
    }
}

```

定义轮胎
```java
package designpatterns.factory;

public class Wheel {

    public void getStyle(){
        System.out.println("这是汽车的轮胎");
    }
}

```

定义汽车接口

```java
package designpatterns.factory;

public interface ICar {
    void show();
}

```

汽车实现

```java
package designpatterns.factory;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class Car implements ICar {


    private Engine engine;
    private UnderPan underpan;
    private Wheel wheel;


    public void show() {
        engine.getStyle();
        underpan.getStyle();
        wheel.getStyle();
        System.out.println("造了一个汽车");
    }
}

```
定义工厂
```java
package designpatterns.factory;

public interface IFactory {

    ICar createCar();
}

```

工厂实现
```java
package designpatterns.factory;

public class Factory implements IFactory {
    public ICar createCar() {
        Engine engine = new Engine();
        UnderPan underpan = new UnderPan();
        Wheel wheel = new Wheel();
        ICar car = new Car(engine, underpan, wheel);
        return car;
    }
}

```

运行
```java
package designpatterns.factory;

public class FactoryMain {
    public static void main(String[] args) {
        IFactory factory = new Factory();
        ICar car = factory.createCar();
        car.show();
    }
}

```

运行结果
```console
D:\Java\jdk1.8.0_161\bin\java.exe "-javaagent:D:\JetBrains\IntelliJ IDEA 2019.3.3\lib\idea_rt.jar=49320:D:\JetBrains\IntelliJ IDEA 2019.3.3\bin" -Dfile.encoding=UTF-8 -classpath D:\Java\jdk1.8.0_161\jre\lib\charsets.jar;D:\Java\jdk1.8.0_161\jre\lib\deploy.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\access-bridge-64.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\cldrdata.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\dnsns.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\jaccess.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\jfxrt.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\localedata.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\nashorn.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunec.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunjce_provider.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunmscapi.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunpkcs11.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\zipfs.jar;D:\Java\jdk1.8.0_161\jre\lib\javaws.jar;D:\Java\jdk1.8.0_161\jre\lib\jce.jar;D:\Java\jdk1.8.0_161\jre\lib\jfr.jar;D:\Java\jdk1.8.0_161\jre\lib\jfxswt.jar;D:\Java\jdk1.8.0_161\jre\lib\jsse.jar;D:\Java\jdk1.8.0_161\jre\lib\management-agent.jar;D:\Java\jdk1.8.0_161\jre\lib\plugin.jar;D:\Java\jdk1.8.0_161\jre\lib\resources.jar;D:\Java\jdk1.8.0_161\jre\lib\rt.jar;D:\github\program\target\classes;D:\firerepository\org\projectlombok\lombok\1.16.22\lombok-1.16.22.jar designpatterns.factory.FactoryMain
这是汽车的发动机
这是汽车的底盘
这是汽车的轮胎
造了一个汽车

Process finished with exit code 0
```
