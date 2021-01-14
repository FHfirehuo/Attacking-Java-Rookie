# 模板方法模式

模板方法就是将实现具体的实现交给子类，而父类只是做一些全局的任务安排，
子类和父类需要紧密的配合才能实现一个任务的功能，因为工作的紧密结合，
我们在写代码的时候一定要做好注释，这样才能使得程序具有强健的可读性。

模板方法模式是一种基于继承的代码复用技术，
它使得子类可以不改变一个算法的结构即可重定义该算法的某些特定步骤，
它是一种类行为型模式。

### 角色
* AbstractClass（抽象类）：在抽象类中定义了一系列基本操作(PrimitiveOperations)，这些基本操作可以是具体的，也可以是抽象的，每一个基本操作对应算法的一个步骤，在其子类中可以重定义或实现这些步骤。
同时，在抽象类中实现了一个模板方法(Template Method)，用于定义一个算法的框架，模板方法不仅可以调用在抽象类中实现的基本方法，也可以调用在抽象类的子类中实现的基本方法，还可以调用其他对象中的方法。
* ConcreteClass（具体子类）：它是抽象类的子类，用于实现在父类中声明的抽象基本操作以完成子类特定算法的步骤，也可以覆盖在父类中已经实现的具体基本操作。

一个模板方法是定义在抽象类中的、把基本操作方法组合在一起形成一个总算法或一个总行为的方法。
这个模板方法定义在抽象类中，并由子类不加以修改地完全继承下来。模板方法是一个具体方法，它给出了一个顶层逻辑框架，而逻辑的组成步骤在抽象类中可以是具体方法，也可以是抽象方法。

基本方法是实现算法各个步骤的方法，是模板方法的组成部分。
基本方法又可以分为三种：

* 抽象方法(Abstract Method)：一个抽象方法由抽象类声明、由其具体子类实现。
* 具体方法(Concrete Method)：一个具体方法由一个抽象类或具体类声明并实现，其子类可以进行覆盖也可以直接继承。
* 钩子方法(Hook Method)：可以与一些具体步骤 “挂钩” ，以实现在不同条件下执行模板方法中的不同步骤


### 优点

在父类中形式化地定义一个算法，而由它的子类来实现细节的处理，在子类实现详细的处理算法时并不会改变算法中步骤的执行次序。
模板方法模式是一种代码复用技术，它在类库设计中尤为重要，它提取了类库中的公共行为，将公共行为放在父类中，而通过其子类来实现不同的行为，它鼓励我们恰当使用继承来实现代码复用。
可实现一种反向控制结构，通过子类覆盖父类的钩子方法来决定某一特定步骤是否需要执行。
在模板方法模式中可以通过子类来覆盖父类的基本方法，不同的子类可以提供基本方法的不同实现，更换和增加新的子类很方便，符合单一职责原则和开闭原则。

### 缺点

需要为每一个基本方法的不同实现提供一个子类，如果父类中可变的基本方法太多，将会导致类的个数增加，系统更加庞大，设计也更加抽象，此时，可结合桥接模式来进行设计。

### 适用场景

对一些复杂的算法进行分割，将其算法中固定不变的部分设计为模板方法和父类具体方法，而一些可以改变的细节由其子类来实现。即：一次性实现一个算法的不变部分，并将可变的行为留给子类来实现。
各子类中公共的行为应被提取出来并集中到一个公共父类中以避免代码重复。
需要通过子类来决定父类算法中某个步骤是否执行，实现子类对父类的反向控制。


### 代码展示

##### 示例一
```java
package designpatterns.template;

public abstract class AbstractDisplay {

    public abstract void open();

    public abstract void print();

    public abstract void close();

    public final void display() {
        open();
        print();
        close();
    }
}

```


```java
package designpatterns.template;

public class CharDisplay extends AbstractDisplay {


    String word;

    CharDisplay(String word) {
        this.word = word;
    }

    public void open() {
        System.out.print("<<");
    }

    public void print() {
        System.out.print(word);
    }

    public void close() {
        System.out.println(">>");
    }
}

```

```java
package designpatterns.template;

public class StringDisplay extends AbstractDisplay {

    String word;
    int width;

    StringDisplay(String word) {
        this.word = word;
        width = word.getBytes().length;
    }

    public void open() {
        printString();
    }

    public void print() {
        for (int i = 0; i < 5; i++) {
            System.out.print("|");
            System.out.print(word);
            System.out.println("|");
        }
    }

    public void close() {
        printString();
    }

    private void printString() {
        System.out.print("#");
        for (int i = 0; i < width; i++) {
            System.out.print("*");
        }
        System.out.println("#");
    }
}

```

```java
package designpatterns.template;

/**
 * 因此说模板非常容易理解，使用起来也很简单，但是在工程中我们往往将模板与其他模式结合起来，因此我们要认清模板的本质，将具有相同操作的多种事物抽象出这些相同的操作，然后将这些操作有机的整合起来变成模板类，
 * 另外也要注意在模板方法的定义final表示此方法不能被继承和重写，这无疑是重要的，规定和法则不能被其他人所改变。
 */
public class TemplateMain {

    public static void main(String[] args) {
        AbstractDisplay p = new CharDisplay("zyr");
        p.display();
        System.out.println("----------------");
        p = new StringDisplay("zyr");
        p.display();
    }
}

```

### 总结

因此说模板非常容易理解，使用起来也很简单，但是在工程中我们往往将模板与其他模式结合起来，因此我们要认清模板的本质，将具有相同操作的多种事物抽象出这些相同的操作，然后将这些操作有机的整合起来变成模板类，
另外也要注意在模板方法的定义final表示此方法不能被继承和重写，这无疑是重要的，规定和法则不能被其他人所改变。在后面的工厂方法里，我们可以看到模板的应用，以及迭代器的影子。

### 源码分析模板方法模式的典型应用

##### Servlet 中的模板方法模式

Servlet（Server Applet）是Java Servlet的简称，用Java编写的服务器端程序，主要功能在于交互式地浏览和修改数据，生成动态Web内容。
在每一个 Servlet 都必须要实现 Servlet 接口，GenericServlet 是个通用的、不特定于任何协议的Servlet，它实现了 Servlet 接口，而 HttpServlet 继承于 GenericServlet，实现了 Servlet 接口，为 Servlet 接口提供了处理HTTP协议的通用实现，所以我们定义的 Servlet 只需要继承 HttpServlet 即可。


##### Mybatis BaseExecutor接口中的模板方法模式
Executor 是 Mybatis 的核心接口之一，其中定义了数据库操作的基本方法，该接口的代码如下：
