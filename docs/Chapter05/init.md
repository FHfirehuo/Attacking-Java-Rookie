# java 的init方法与clinit方法


一、
clinit静态方法：类型初始化方法主要是对static变量进行初始化操作，对static域和static代码块初始化的逻辑全部封装在<clinit>方法中。
java.lang.Class.forName(String name, boolean initialize,ClassLoader loader)，其中第二个参数就是是否需要初始化。
    
Java类型初始化过程中对static变量的初始化操作依赖于static域和static代码块的前后关系，static域与static代码块声明的位置关系会导致java编译器生成<clinit>方法字节码。
类型的初始化方法<clinit>只在该类型被加载时才执行，且只执行一次。
  
二、
对象实例化方法<init>：Java对象在被创建时，会进行实例化操作。
该部分操作封装在<init>方法中，并且子类的<init>方法中会首先对父类<init>方法的调用。
Java对象实例化过程中对实例域的初始化赋值操作全部在<init>方法中进行，
<init>方法显式的调用父类的<init>方法，
实例域的声明以及实例初始化语句块同样的位置关系会影响编译器生成的<init>方法的字节码顺序，
<init>方法以构造方法作为结束。   

三、init和clinit区别：

①init和clinit方法执行时机不同

    init是对象构造器方法，也就是说在程序执行 new 一个对象调用该对象类的 constructor 方法时才会执行init方法，而clinit是类构造器方法，也就是在jvm进行类加载—–验证—-解析—–初始化，中的初始化阶段jvm会调用clinit方法。

②init和clinit方法执行目的不同

    init is the (or one of the) constructor(s) for the instance, and non-static field initialization. 
    clinit are the static initialization blocks for the class, and static field initialization. 
上面这两句是Stack Overflow上的解析，很清楚init是instance实例构造器，对非静态变量解析初始化，而clinit是class类构造器对静态变量，静态代码块进行初始化。看看下面的这段程序就很清楚了。  

```java
class X {
 
   static Log log = LogFactory.getLog(); // <clinit>
 
   private int x = 1;   // <init>
 
   X(){
      // <init>
   }
 
   static {
      // <clinit>
   }
 
}
```
    clinit一定优先于init
    
今天先来分析一下经常遇到的一个问题，在笔试面试中可能会经常遇见，类中字段代码块的加载顺序等，从jvm角度分析一下这个问题。我们先来看下知识点，接下来进行代码实践验证。

<clinit>，类构造器方法，在jvm第一次加载class文件时调用，因为是类级别的，所以只加载一次，是编译器自动收集类中所有类变量（static修饰的变量）和静态语句块（static{}），中的语句合并产生的，编译器收集的顺序，是由程序员在写在源文件中的代码的顺序决定的。
<init>，实例构造器方法，在实例创建出来的时候调用，包括调用new操作符；调用Class或java.lang.reflect.Constructor对象的newInstance()方法；调用任何现有对象的clone()方法；通过java.io.ObjectInputStream类的getObject()方法反序列化。

1.<clinit>方法和类的构造函数不同，它不需要显示调用父类的构造方法，虚拟机会保证子类的<clinit>方法执行之前，父类的此方法已经执行完毕，因此虚拟机中第一个被执行的<clinit>方法的类肯定是java.lang.Object

2、接口中不能使用static块，但是接口仍然有变量初始化的操作，因此接口也会生成<clinit>方法。但接口和类不同的是，不会先去执行继承接口的<clinit>方法，而是在调用父类变量的时候，才会去调用<clinit>方法。接口的实现类也是一样的。

  
