# 静态（简单）工厂模式

简单工厂模式是最初自然而然就有的设计思想，它只是把创建过程比较自然的封装了一下，
又称为静态工厂模式，是直接根据条件决定创建的产品。



```java
Animal
public  abstract class Animal {

    public abstract void call();

}

// Dog
public static class Dog extends Animal {

    @Override
    public void call() {
        System.out.println("Dog");
    }
}

//Cat
public static class Cat extends Animal {
    @Override
    public void call() {
        System.out.println("Cat");
    }
}

 

//Factory
public class Factory {

    public  int Type_Dog=0;
    public  int Type_Cat=1;

    public static Animal readAnimal(int Type){
        switch (Type){
            default:
                return new Dog();
            case 0:
                return  new Dog();
            case 1:
                return new Cat();
        }
    }

    public static void main(String[] args){
        Animal animal=Factory.readAnimal(Type_Cat);
        animal.call();
    }
}
 控制台输出：Cat

```

Effective+Java作者joshua bloch（Java 集合框架创办人、谷歌首席java架构师）建议，
考虑用静态工厂方法来代替多个构造函数。

第一个优点,有名称，有时候一个类的构造器不止一个，
名称往往相同，参数不同，很难理解他们有什么不同的含义，
如果使用静态工厂方法，
就一目了然知道设计者想表达的意图。

第二个优点，不用重复创建一个对象。

第三个优点，可以返回类型的任何子类型.举个例子,

    List list = Collections.synchronizedList(new ArrayList())　

这个例子就说明了可以返回原返回类型的任何子类型的对象。

### 缺点：

1. 公有的静态方法所返回的非公有类不能被实例化，
也就是说Collections.synchronizedList返回的SynchronizedList不能被实例化。

2. 查找API比较麻烦，
它们不像普通的类有构造器在API中标识出来，
在文档中要详细说明实例化一个类，非常困难。

3. 由于工厂类集中了所有实例的创建逻辑，
这就直接导致一旦这个工厂出了问题，
所有的客户端都会受到牵连；
而且由于简单工厂模式的产品室基于一个共同的抽象类或者接口，
这样一来，若产品的种类增加时，
即有不同的产品接口或者抽象类的时候，
工厂类就需要判断何时创建何种种类的产品，
更改其中逻辑，
这就和创建何种种类产品的产品相互混淆在了一起
，违背了单一职责，
导致系统丧失灵活性和可维护性。
而且更重要的是，
简单工厂模式违背了“开放封闭原则”，
就是违背了“系统对扩展开放，对修改关闭”的原则，
因为当我新增加一个产品的时候必须修改工厂类，
相应的工厂类就需要重新编译一遍。

## 总结一下

简单工厂模式分离产品的创建者和消费者，
有利于软件系统结构的优化；
但是由于一切逻辑都集中在一个工厂类中，
导致了没有很高的内聚性，
同时也违背了“开放封闭原则”。
另外，简单工厂模式的方法一般都是静态的，
而静态工厂方法是无法让子类继承的，
因此，简单工厂模式无法形成基于基类的继承树结构。
