 # 访问者（Visitor）模式
 
什么叫做访问，如果大家学过数据结构，对于这点就很清晰了，遍历就是访问的一般形式，
单独读取一个元素进行相应的处理也叫作访问，读取到想要查看的内容+对其进行处理就叫做访问，
那么我们平常是怎么访问的，基本上就是直接拿着需要访问的地址（引用）来读写内存就可以了。

为什么还要有一个访问者模式呢，这就要放到OOP之中了，在面向对象编程的思想中，我们使用类来组织属性，
以及对属性的操作，那么我们理所当然的将访问操作放到了类的内部，这样看起来没问题，
但是当我们想要使用另一种遍历方式要怎么办呢，我们必须将这个类进行修改，这在设计模式中是大忌，
在设计模式中就要保证，对扩展开放，对修改关闭的开闭原则。

因此，我们思考，可不可以将访问操作独立出来变成一个新的类，当我们需要增加访问操作的时候，
直接增加新的类，原来的代码不需要任何的改变，如果可以这样做，那么我们的程序就是好的程序，因为可以扩展，
符合开闭原则。而访问者模式就是实现这个的，使得使用不同的访问方式都可以对某些元素进行访问。
   
   
### 在访问者模式中，主要包括下面几个角色：
   
* 抽象访问者：抽象类或者接口，声明访问者可以访问哪些元素，具体到程序中就是visit方法中的参数定义哪些对象是可以被访问的。
* 访问者：实现抽象访问者所声明的方法，它影响到访问者访问到一个类后该干什么，要做什么事情。
* 抽象元素类：接口或者抽象类，声明接受哪一类访问者访问，程序上是通过accept方法中的参数来定义的。抽象元素一般有两类方法，一部分是本身的业务逻辑，另外就是允许接收哪类访问者来访问。
* 元素类：实现抽象元素类所声明的accept方法，通常都是visitor.visit(this)，基本上已经形成一种定式了。
* 结构对象：一个元素的容器，一般包含一个容纳多个不同类、不同接口的容器，如List、Set、Map等，在项目中一般很少抽象出这个角色。

### 代码展示

```java
package designpatterns.visitor;

public interface IVisitor {
    void visit(ConcreteElement1 el1);

    void visit(ConcreteElement2 el2);
}

```

```java
package designpatterns.visitor;

public abstract class Element {

    public abstract void accept(IVisitor visitor);

    public abstract void doSomething();
}

```

```java
package designpatterns.visitor;

public class ConcreteElement1 extends Element {

    public void doSomething() {
        System.out.println("这是元素1");
    }

    public void accept(IVisitor visitor) {
        visitor.visit(this);
    }
}

```


```java
package designpatterns.visitor;

public class ConcreteElement2 extends Element {

    public void doSomething() {
        System.out.println("这是元素2");
    }

    public void accept(IVisitor visitor) {
        visitor.visit(this);
    }
}

```


```java
package designpatterns.visitor;

public class Visitor implements IVisitor {
    public void visit(ConcreteElement1 el1) {
        el1.doSomething();
    }

    public void visit(ConcreteElement2 el2) {
        el2.doSomething();
    }
}

```


```java
package designpatterns.visitor;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class ObjectStruture {
    public static List getList() {
        List<Element> list = new ArrayList();
        Random ran = new Random();
        for (int i = 0; i < 10; i++) {
            int a = ran.nextInt(100);
            if (a > 50) {
                list.add(new ConcreteElement1());
            } else {
                list.add(new ConcreteElement2());
            }
        }
        return list;
    }
}

```


```java
package designpatterns.visitor;

import java.util.List;

public class VisitorMain {
    public static void main(String[] args) {
        List<Element> list = ObjectStruture.getList();
        for (Element e : list) {
            e.accept(new Visitor());
        }
    }
}

```


### 优点
   
* 符合单一职责原则：凡是适用访问者模式的场景中，元素类中需要封装在访问者中的操作必定是与元素类本身关系不大且是易变的操作，使用访问者模式一方面符合单一职责原则，
   另一方面，因为被封装的操作通常来说都是易变的，所以当发生变化时，就可以在不改变元素类本身的前提下，实现对变化部分的扩展。
* 扩展性良好：元素类可以通过接受不同的访问者来实现对不同操作的扩展。

### 访问者模式的适用场景
   
1. 假如一个对象中存在着一些与本对象不相干（或者关系较弱）的操作，为了避免这些操作污染这个对象，则可以使用访问者模式来把这些操作封装到访问者中去。
2. 假如一组对象中，存在着相似的操作，为了避免出现大量重复的代码，也可以将这些重复的操作封装到访问者中去。
   
但是，访问者模式并不是那么完美，它也有着致命的缺陷：增加新的元素类比较困难。通过访问者模式的代码可以看到，在访问者类中，每一个元素类都有它对应的处理方法，
也就是说，每增加一个元素类都需要修改访问者类（也包括访问者类的子类或者实现类），修改起来相当麻烦。也就是说，在元素类数目不确定的情况下，应该慎用访问者模式。
所以，访问者模式比较适用于对已有功能的重构，比如说，一个项目的基本功能已经确定下来，元素类的数据已经基本确定下来不会变了，会变的只是这些元素内的相关操作，
这时候，我们可以使用访问者模式对原有的代码进行重构一遍，这样一来，就可以在不修改各个元素类的情况下，对原有功能进行修改。
   
## 总结

正如《设计模式》的作者GoF对访问者模式的描述：大多数情况下，你并需要使用访问者模式，但是当你一旦需要使用它时，那你就是真的需要它了。当然这只是针对真正的大牛而言。
在现实情况下（至少是我所处的环境当中），很多人往往沉迷于设计模式，他们使用一种设计模式时，从来不去认真考虑所使用的模式是否适合这种场景，而往往只是想展示一下自己对面向对象设计的驾驭能力。
编程时有这种心理，往往会发生滥用设计模式的情况。所以，在学习设计模式时，一定要理解模式的适用性。必须做到使用一种模式是因为了解它的优点，不使用一种模式是因为了解它的弊端；
而不是使用一种模式是因为不了解它的弊端，不使用一种模式是因为不了解它的优点。
