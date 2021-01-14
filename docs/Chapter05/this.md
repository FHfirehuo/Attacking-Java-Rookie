# 深入分析java中的关键字this

### 为什么要引入this关键字？
    
现在出现一个问题，就是你希望在方法的内部去获得当前对象的引用。
现在java提供了一个关键字this。他就表示当前对象的引用。

##### 使用this关键字

* 一个方法调用同一个类的另外一个方法，

这种情况是不需要使用this的。直接使用即可。

```java
class MyClass{
    void f1(){};
    void f2(){ 
         f1();
    }
}
```

* 当成员变量和局部变量重名时，在方法中使用this时，表示的是该方法所在类中的成员变量。（this是当前对象自己）

```java
public class Hello {
    String s = "Hello";//这里的S与Hello()方法里面的成员变量重名
    public Hello(String s) {
       System.out.println("s = " + s);
       System.out.println("1 -> this.s = " + this.s);
       this.s = s;//把参数值赋给成员变量，成员变量的值改变
       System.out.println("2 -> this.s = " + this.s);
    }
    public static void main(String[] args) {
       Hello x = new Hello("HelloWorld!");
       System.out.println("s=" + x.s);//验证成员变量值的改变
    }
}
```

在这个例子中，构造函数Hello中，参数s与类Hello的成员变量s同名，
这时如果直接对s进行操作则是对参数s进行操作。
若要对类Hello的成员变量s进行操作就应该用this进行引用。
运行结果的第一行就是直接对构造函数中传递过来的参数s进行打印结果；
 第二行是对成员变量s的打印；
 第三行是先对成员变量s赋传过来的参数s值后再打印，
 所以结果是HelloWorld!
 而第四行是主函数中直接打印类中的成员变量的值，也可以验证成员变量值的改变。

* 把自己当作参数传递时，也可以用this.(this作当前参数进行传递)

```java
class A {
    public A() {
       new B(this).print();// 调用B的方法
    }
    public void print() {
       System.out.println("HelloAA from A!");
    }
 }
class B {
    A a;
    public B(A a) {
       this.a = a;
    }
    public void print() {
       a.print();//调用A的方法
       System.out.println("HelloAB from B!");
    }
}
public class HelloA {
    public static void main(String[] args) {
       A aaa = new A();
       aaa.print();
       B bbb = new B(aaa);
       bbb.print();
    }
}
```

在这个例子中，对象A的构造函数中，用new B(this)把对象A自己作为参数传递给了对象B的构造函数。

* 当在匿名类中用this时，这个this则指的是匿名类或内部类本身。

这时如果我们要使用外部类的方法和变量的话，则应该加上外部类的类名。如：

```java
 public class HelloB {
    int i = 1;
    public HelloB() {
       Thread thread = new Thread() {
           public void run() {
              for (int j=0;j<20;j++) {
                  HelloB.this.run();//调用外部类的方法
                  try {
                     sleep(1000);
                  } catch (InterruptedException ie) {
                  }
              }
           }
       }; // 注意这里有分号
       thread.start();
    }
    public void run() {
       System.out.println("i = " + i);
       i++;
    }
    public static void main(String[] args) throws Exception {
       new HelloB();
    }
}
```

在上面这个例子中, thread 是一个匿名类对象，在它的定义中，
它的 run 函数里用到了外部类的 run 函数。这时由于函数同名，直接调用就不行了。
这时有两种办法，一种就是把外部的 run 函数换一个名字，
但这种办法对于一个开发到中途的应用来说是不可取的。
那么就可以用这个例子中的办法用外部类的类名加上 this 引用来说明要调用的是外部类的方法 run。

* 在构造函数中，通过this可以调用同一类中别的构造函数。如：

```java
public class ThisTest {
    ThisTest(String str) {
       System.out.println(str);
    }
    ThisTest() {
       this("this测试成功！");
    }
    public static void main(String[] args) {
       ThisTest thistest = new ThisTest();
    }
}
```
为了更确切的说明this用法，另外一个例子为：

```java
public class ThisTest {
    private int age;
    private String str;
    ThisTest(String str) {
       this.str=str;
       System.out.println(str);
    }
    ThisTest(String str,int age) {
       this(str);
       this.age=age;
       System.out.println(age);
    }
    public static void main(String[] args) {
       ThisTest thistest = new ThisTest("this测试成功",25);
      
    }
}
```

值得注意的是：
　　1：在构造调用另一个构造函数，调用动作必须置于最起始的位置。
　　2：不能在构造函数以外的任何函数内调用构造函数。
　　3：在一个构造函数内只能调用一个构造函数。这一点在第二个构造方法内可以看到，第一个this(str)，第二个为this.age=age；

* this同时传递多个参数

```java
public class TestClass {
    int x;
    int y;
    static void showtest(TestClass tc) {//实例化对象
       System.out.println(tc.x + " " + tc.y);
    }
    void seeit() {
       showtest(this);
    }
    public static void main(String[] args) {
       TestClass p = new TestClass();
       p.x = 9;
       p.y = 10;
       p.seeit();
    }
}
```
