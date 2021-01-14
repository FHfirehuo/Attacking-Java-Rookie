# 抽象工厂模式

抽象工厂模式（Abstract Factory Pattern）是围绕一个超级工厂创建其他工厂;该超级工厂又称为其他工厂的工厂。

抽象工厂模式提供一个创建一系列相关或相互依赖对象的接口，而无须指定它们具体的类。抽象工厂模式又称为Kit模式，它是一种对象创建型模式，提供了一种创建对象的最佳方式。

在抽象工厂模式中，接口是负责创建一个相关对象的工厂，不需要显式指定它们的类。每个生成的工厂都能按照工厂模式提供对象。

在抽象工厂模式中，每一个具体工厂都提供了多个工厂方法用于产生多种不同类型的产品。

抽象工厂模式是工厂方法模式的升级版本，他用来创建一组相关或者相互依赖的对象。

### 与工厂方法模式的区别

工厂方法模式针对的是一个产品等级结构；而抽象工厂模式则是针对的多个产品等级结构

### 介绍

* 意图：提供一个创建一系列相关或相互依赖对象的接口，而无需指定它们具体的类。
* 主要解决：主要解决接口选择的问题。
* 何时使用：系统的产品有多于一个的产品族，而系统只消费其中某一族的产品。
* 如何解决：在一个产品族里面，定义多个产品。
* 关键代码：在一个工厂里聚合多个同类产品。

### 应用实例

工作了，为了参加一些聚会，肯定有两套或多套衣服吧，比如说有商务装（成套，一系列具体产品）、时尚装（成套，一系列具体产品），甚至对于一个家庭来说，可能有商务女装、商务男装、时尚女装、时尚男装，这些也都是成套的，即一系列具体产品。假设一种情况（现实中是不存在的，要不然，没法进入共产主义了，但有利于说明抽象工厂模式），
在您的家中，某一个衣柜（具体工厂）只能存放某一种这样的衣服（成套，一系列具体产品），每次拿这种成套的衣服时也自然要从这个衣柜中取出了。用 OO 的思想去理解，所有的衣柜（具体工厂）都是衣柜类的（抽象工厂）某一个，而每一件成套的衣服又包括具体的上衣（某一具体产品），裤子（某一具体产品），这些具体的上衣其实也都是上衣（抽象产品），具体的裤子也都是裤子（另一个抽象产品）。

### 优点

当一个产品族中的多个对象被设计成一起工作时，它能保证客户端始终只使用同一个产品族中的对象。

### 缺点

产品族扩展非常困难，要增加一个系列的某一产品，既要在抽象的 Creator 里加代码，又要在具体的里面加代码。

### 使用场景

1. QQ 换皮肤，一整套一起换。 
2. 生成不同操作系统的程序。

### 注意事项

产品族难扩展，产品等级易扩展。


### 角色

* AbstractFactory（抽象工厂）：它声明了一组用于创建一族产品的方法，每一个方法对应一种产品。
* ConcreteFactory（具体工厂）：它实现了在抽象工厂中声明的创建产品的方法，生成一组具体产品，这些产品构成了一个产品族，每一个产品都位于某个产品等级结构中。
* AbstractProduct（抽象产品）：它为每种产品声明接口，在抽象产品中声明了产品所具有的业务方法
* ConcreteProduct（具体产品）：它定义具体工厂生产的具体产品对象，实现抽象产品接口中声明的业务方法。

在抽象工厂中声明了多个工厂方法，用于创建不同类型的产品，抽象工厂可以是接口，也可以是抽象类或者具体类

具体工厂实现了抽象工厂，每一个具体的工厂方法可以返回一个特定的产品对象，而同一个具体工厂所创建的产品对象构成了一个产品族

### 代码实现


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
package designpatterns.abstractfactory;

public interface ICar {
    void show();
}

```

奥迪汽车实现

```java
package designpatterns.abstractfactory;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class AudiCar implements ICar {
    private Engine engine;
    private Underpan underpan;
    private Wheel wheel;


    public void show() {
        engine.getStyle();
        underpan.getStyle();
        wheel.getStyle();
        System.out.println("造了一台奥迪汽车");
    }
}

```

奔驰汽车实现

```java
package designpatterns.abstractfactory;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class BenzCar implements ICar {


    private Engine engine;
    private Underpan underpan;
    private Wheel wheel;


    public void show() {
        engine.getStyle();
        underpan.getStyle();
        wheel.getStyle();
        System.out.println("造了一台奔驰汽车");
    }
}

```


定义工厂
```java
package designpatterns.abstractfactory;

public interface IFactory {

    ICar createBenzCar();
    ICar createAudiCar();
}
    

```

工厂实现
```java
package designpatterns.abstractfactory;

public class Factory implements IFactory {
    public ICar createBenzCar() {
        Engine engine = new Engine();
        Underpan underpan = new Underpan();
        Wheel wheel = new Wheel();
        ICar car = new BenzCar(engine, underpan, wheel);
        return car;
    }

    public ICar createAudiCar() {
        Engine engine = new Engine();
        Underpan underpan = new Underpan();
        Wheel wheel = new Wheel();
        ICar car = new AudiCar(engine, underpan, wheel);
        return car;
    }
}


```

运行
```java
package designpatterns.abstractfactory;

public class AbstractFactoryMain {
    public static void main(String[] args) {
        IFactory factory = new Factory();
        ICar benzCar = factory.createBenzCar();
        benzCar.show();

        ICar audi = factory.createAudiCar();
        audi.show();
    }
}

```

运行结果

```console
这是汽车的发动机
这是汽车的底盘
这是汽车的轮胎
造了一台奔驰汽车
这是汽车的发动机
这是汽车的底盘
这是汽车的轮胎
造了一台奥迪汽车

```


