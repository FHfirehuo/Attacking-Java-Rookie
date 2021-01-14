# 外观模式

外观模式（Facade Pattern）隐藏系统的复杂性，并向客户端提供了一个客户端可以访问系统的接口。
这种类型的设计模式属于结构型模式，它向现有的系统添加一个接口，来隐藏系统的复杂性。

其实直接调用也会得到相同的结果，但是采用外观模式能规范代码，
外观类就是子系统对外的一个总接口，我们要访问子系统是，
直接去子系统对应的外观类进行访问即可！

这种模式涉及到一个单一的类，该类提供了客户端请求的简化方法和对现有系统类方法的委托调用。

### 介绍
* 意图：为子系统中的一组接口提供一个一致的界面，外观模式定义了一个高层接口，这个接口使得这一子系统更加容易使用。
* 主要解决：降低访问复杂系统的内部子系统时的复杂度，简化客户端与之的接口。
* 如何解决：客户端不与系统耦合，外观类与系统耦合。
* 关键代码：在客户端和复杂系统之间再加一层，这一层将调用顺序、依赖关系等处理好。
* 何时使用： 
  1. 客户端不需要知道系统内部的复杂联系，整个系统只需提供一个"接待员"即可。 
  2. 定义系统的入口。


### 应用实例： 
1. 去医院看病，可能要去挂号、门诊、划价、取药，让患者或患者家属觉得很复杂，如果有提供接待人员，只让接待人员来处理，就很方便。 
2. JAVA 的三层开发模式。

### 优点： 
1. 减少系统相互依赖。 
2. 提高灵活性。 
3. 提高了安全性。

### 缺点：

不符合开闭原则，如果要改东西很麻烦，继承重写都不合适。

### 使用场景： 
1. 为复杂的模块或子系统提供外界访问的模块。 
2. 子系统相对独立。 
3. 预防低水平人员带来的风险。

### 注意事项：

在层次化结构中，可以使用外观模式定义系统中每一层的入口。

### 外观模式应用场景

当我们访问的子系统拥有复杂额结构，内部调用繁杂，初接触者根本无从下手时，
不凡由资深者为这个子系统设计一个外观类来供访问者使用，统一访问路径（集中到外观类中），
将繁杂的调用结合起来形成一个总调用写到外观类中，之后访问者不用再繁杂的方法中寻找需要的方法进行调用，
直接在外观类中找对应的方法进行调用即可。

还有就是在系统与系统之间发生调用时，也可以为被调用子系统设计外观类，
这样方便调用也，屏蔽了系统的复杂性。

### 代码实现

```java
package designpatterns.facade;

public class SubMethod1 {

    public void method1() {
        System.out.println("子系统中类1的方法1");
    }

    public void method3() {
        System.out.println("子系统类1方法3");
    }
}

```


```java
package designpatterns.facade;

public class SubMethod2 {

    public void method2() {
        System.out.println("子系统中类2方法2");
    }
}

```


```java
package designpatterns.facade;

public class SubMethod3 {
    public void method3() {
        System.out.println("子系统类3方法3");
    }
}

```

```java
package designpatterns.facade;

public class Facader {

    private SubMethod1 sm1 = new SubMethod1();
    private SubMethod2 sm2 = new SubMethod2();
    private SubMethod3 sm3 = new SubMethod3();

    public void facMethod1() {
        sm1.method1();
        sm2.method2();
        sm1.method3();
    }

    public void facMethod2() {
        sm2.method2();
        sm3.method3();
        sm1.method1();
    }
}

```


```java
package designpatterns.facade;

public class FacaderMain {
    public static void main(String[] args) {
        Facader face = new Facader();
        face.facMethod1();
//        face.facMethod2();
    }
}

```
