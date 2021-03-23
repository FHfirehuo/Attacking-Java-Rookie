# 深入分析java中的关键字final

对于final大家从字面意思就能看出来，主要是“最终的不可改变的意思”。
可以修饰类、方法和变量。先给出这篇文章的大致脉络

* 首先，先给出final关键字的三种使用场景，也就是修饰类，方法和变量
* 然后，深入分析final关键字主要注意的几个问题
* 最后，总结一下final关键字

### final关键字的基本使用

##### 认识final关键字

final可以修饰类、方法、变量。那么分别是什么作用呢？

1. 修饰类：表示类不可被继承
2. 修饰方法：表示方法不可被覆盖
3. 修饰变量：表示变量一旦被赋值就不可以更改它的值。java中规定final修饰成员变量必须由程序员显示指定变量的值。

##### final关键字修饰类

final关键字修饰类表示这个类是不可被继承的，如何去验证呢？

###### final关键字修饰方法

final修饰的方法不能被重写。但是可以重载。
下面给出了一个代码例子。主要注意的是：父类中private的方法，
在子类中不能访问该方法，但是子类与父类private方法相同的方法名、
形参列表和返回值的方法，不属于方法重写，只是定义了一个新的方法。

```java
public class FinalClass{
     public final void test(){}
     public final void test(int i){}
}
```

##### final关键字修饰变量

final关键字修饰变量，是比较麻烦的。但是我们只需要对其进行一个分类介绍就能理解清楚了。

* 修饰成员变量

如果final修饰的是类变量，只能在静态初始化块中指定初始值或者声明该类变量时指定初始值。

如果final修饰的是成员变量，可以在非静态初始化块、声明该变量或者构造器中执行初始值。

* 修饰局部变量

系统不会为局部变量进行初始化，局部变量必须由程序员显示初始化。
因此使用final修饰局部变量时，即可以在定义时指定默认值（后面的代码不能对变量再赋值），
也可以不指定默认值，而在后面的代码中对final变量赋初值（仅一次）。

下面使用代码去验证一下这两种情况

```java
public class FinalVar {
    final static int a = 0;//再声明的时候就需要赋值
    public static void main(String[] args) {
        final int localA;   //局部变量只声明没有初始化，不会报错,与final无关。
        localA = 0;//在使用之前一定要赋值
        //localA = 1;  但是不允许第二次赋值
    }
}
```

* 修饰基本类型数据和引用类型数据

   * 如果是基本数据类型的变量，则其数值一旦在初始化之后便不能更改；
   * 如果是引用类型的变量，则在对其初始化之后便不能再让其指向另一个对象。但是引用的值是可变的。

修饰基本类型的数据，在上面的代码中基本上能够看出，下面主要是描述引用类型的变量

```java
public class FinalReferenceTest{
    public static void main(){
        final int[] iArr={1,2,3,4};
        iArr[2]=-3;//合法 
        iArr=null;//非法，对iArr不能重新赋值
        
        final Person p = new Person(25);
        p.setAge(24);//合法
        p=null;//非法 
    }   
}
```

### final关键字需要注意的几个问题

##### final和static的区别

其实如果你看过我上一篇文章，基本上都能够很容易得区分开来。
static作用于成员变量用来表示只保存一份副本，而final的作用是用来保证变量不可变。
下面代码验证一下

```java
public class FinalTest {
    public static void main(String[] args)  {
        AA aa1 = new AA();
        AA aa2 = new AA();
        System.out.println(aa1.i);
        System.out.println(aa1.j);
        System.out.println(aa2.i);
        System.out.println(aa2.j);
    }
}
//j值两个都一样，因为是static修饰的,全局只保留一份
//i值不一样，两个对象可能产生两个不同的值，
class AA {
    public final int i = (int) (Math.random()*100);
    public static int j = (int) (Math.random()*100);
}
//结果是 65、23、67、23
```

##### 为什么局部内部类和匿名内部类只能访问局部final变量？

为了解决这个问题，我们先要去使用代码去验证一下。

```java
public class Test {
    public static void main(String[] args)  {     
    }   
    //局部final变量a,b
    public void test(final int b) {
        final int a = 10;
        //匿名内部类
        new Thread(){
            public void run() {
                System.out.println(a);
                System.out.println(b);
            };
        }.start();
    }
}
```

 上段代码中，如果把变量a和b前面的任一个final去掉，这段代码都编译不过。

 这段代码会被编译成两个class文件：Test.class和Test1.class。默认情况下，编译器会为匿名内部类和局部内部类起名为Outter1.class。

原因是为什么呢？这是因为test()方法里面的参数a和b，在运行时，main线程快要结束，但是thread还没有开始。因此需要有一种机制，在使得运行thread线程时候能够调用a和b的值，怎办呢？java采用了一种复制的机制，

也就说如果局部变量的值在编译期间就可以确定，则直接在匿名内部里面创建一个拷贝。如果局部变量的值无法在编译期间确定，则通过构造器传参的方式来对拷贝进行初始化赋值。

### 总结

final关键字主要用在三个地方：变量、方法、类。

1. 对于一个final变量，如果是基本数据类型的变量，则其数值一旦在初始化之后便不能更改；如果是引用类型的变量，则在对其初始化之后便不能再让其指向另一个对象。
1. 当用final修饰一个类时，表明这个类不能被继承。final类中的所有成员方法都会被隐式地指定为final方法。
1. 使用final方法的原因有两个。第一个原因是把方法锁定，以防任何继承类修改它的含义；第二个原因是效率。在早期的Java实现版本中，会将final方法转为内嵌调用。但是如果方法过于庞大，可能看不到内嵌调用带来的任何性能提升（现在的Java版本已经不需要使用final方法进行这些优化了）。类中所有的private方法都隐式地指定为final。







# 细节七、写 final 域的重排序规则，你知道吗？

这个规则是指禁止对 final 域的写重排序到构造函数之外，这个规则的实现主要包含了两个方面：

1. JMM 禁止编译器把 final 域的写重排序 到 构造函数 之外
2. 编译器会在 final 域写之后，构造函数 return 之前，插入一个 StoreStore 屏障。这个屏障可以禁止处理器把 final 域的写重排序到构造函数之外

给举个例子，要不太抽象了，先看一段代码

```
public class FinalTest{

    private int a;  //普通域
    private final int b; //final域
    private static FinalTest finalTest;

    public FinalTest() {
        a = 1; // 1. 写普通域
        b = 2; // 2. 写final域
    }

    public static void writer() {
        finalTest = new FinalTest();
    }

    public static void reader() {
        FinalTest demo = finalTest; // 3.读对象引用
        int a = demo.a;    //4.读普通域
        int b = demo.b;    //5.读final域
    }
}
```

假设线程 A 在执行 writer()方法，线程 B 执行 reader()方法。

由于变量 a 和变量 b 之间没有依赖性，所以就有可能会出现下图所示的重排序

![final关键字的这8个小细节，你get到几个？](https://p6-tt.byteimg.com/origin/pgc-image/f1d28a566eca4622aec231152fae7533?from=pc)



由于普通变量 a 可能会被重排序到构造函数之外，所以线程 B 就有可能读到的是普通变量 a 初始化之前的值（零值），这样就可能出现错误。

而 final 域变量 b，根据重排序规则，会禁止 final 修饰的变量 b 重排序到构造函数之外，从而 b 能够正确赋值，线程 B 就能够读到 final 域变量 b初始化后的值。

**结论**：写 final 域的重排序规则可以确保在对象引用为任意线程可见之前，对象的 final 域已经被正确初始化过了，而普通域就不具有这个保障。

# 细节八：读 final 域的重排序规则，你知道吗？

这个规则是指在一个线程中，初次读对象引用和初次读该对象包含的 final 域，JMM 会禁止这两个操作的重排序。

还是上面那段代码

```
public class FinalTest{

    private int a;  //普通域
    private final int b; //final域
    private static FinalTest finalTest;

    public FinalTest() {
        a = 1; // 1. 写普通域
        b = 2; // 2. 写final域
    }

    public static void writer() {
        finalTest = new FinalTest();
    }

    public static void reader() {
        FinalTest demo = finalTest; // 3.读对象引用
        int a = demo.a;    //4.读普通域
        int b = demo.b;    //5.读final域
    }
}
```

假设线程 A 在执行 writer()方法，线程 B 执行 reader()方法。

线程 B 可能就会出现下图所示的重排序

![final关键字的这8个小细节，你get到几个？](https://p1-tt.byteimg.com/origin/pgc-image/81016de6ea904d92aa1ee03bf8add379?from=pc)



可以看到，由于读对象的普通域被重排序到了读对象引用的前面，就会出现线程 B 还未读到对象引用就在读取该对象的普通域变量，这显然是错误的操作。而 final 域的读操作就“限定”了在读 final 域变量前已经读到了该对象的引用，从而就可以避免这种情况。

**结论**：读 final 域的重排序规则可以确保在读一个对象的 final 域之前，一定会先读包含这个 final 域的对象的引用。

