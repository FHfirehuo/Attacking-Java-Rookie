# transient

##### 初识transient关键字

其实这个关键字的作用很好理解，就是简单的一句话：
将不需要序列化的属性前添加关键字transient，序列化对象的时候，
这个属性就不会被序列化。

概念也很好理解，下面使用代码去验证一下：

```java
package keyword;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.*;

public class FireTransient {

    public static void main(String[] args) throws IOException, ClassNotFoundException {
        serializeUser();
        deSerializeUser();
    }

    private static void serializeUser() throws IOException {
        File file = new File("/opt/test/");
        if (!file.exists()){
            file.mkdirs();
        }
        User u = new User();
        u.setAge(10);
        u.setName("fire");
        ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("/opt/test/template"));
        oos.writeObject(u);
        oos.close();
    }

    private static void deSerializeUser() throws IOException, ClassNotFoundException {

        File file = new File("/opt/test/template");
        ObjectInputStream ois = new ObjectInputStream(new FileInputStream(file));
        User u = (User) ois.readObject();
        System.out.println(u.toString());
    }
}

@Getter
@Setter
@ToString
class User implements Serializable{
    private transient int age;
    private String name;
}

```

从上面可以看出，在序列化SerializeUser方法中，
首先创建一个序列化user类，
然后将其写入到/opt/test/template"路径中。
在反序列化DeSerializeUser方法中，
首先创建一个File，然后读取/opt/test/template"路径中的数据。

这就是序列化和反序列化的基本实现
，而且我们看一下结果，
也就是被transient关键字修饰的age属性是否被序列化。

```console
D:\Java\jdk1.8.0_161\bin\java.exe "-javaagent:D:\JetBrains\IntelliJ IDEA 2019.3.3\lib\idea_rt.jar=62658:D:\JetBrains\IntelliJ IDEA 2019.3.3\bin" -Dfile.encoding=UTF-8 -classpath D:\Java\jdk1.8.0_161\jre\lib\charsets.jar;D:\Java\jdk1.8.0_161\jre\lib\deploy.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\access-bridge-64.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\cldrdata.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\dnsns.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\jaccess.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\jfxrt.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\localedata.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\nashorn.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunec.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunjce_provider.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunmscapi.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunpkcs11.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\zipfs.jar;D:\Java\jdk1.8.0_161\jre\lib\javaws.jar;D:\Java\jdk1.8.0_161\jre\lib\jce.jar;D:\Java\jdk1.8.0_161\jre\lib\jfr.jar;D:\Java\jdk1.8.0_161\jre\lib\jfxswt.jar;D:\Java\jdk1.8.0_161\jre\lib\jsse.jar;D:\Java\jdk1.8.0_161\jre\lib\management-agent.jar;D:\Java\jdk1.8.0_161\jre\lib\plugin.jar;D:\Java\jdk1.8.0_161\jre\lib\resources.jar;D:\Java\jdk1.8.0_161\jre\lib\rt.jar;D:\github\program\target\classes;D:\firerepository\org\projectlombok\lombok\1.16.22\lombok-1.16.22.jar keyword.FireTransient
User(age=0, name=fire)

Process finished with exit code 0
```

从上面的这张图可以看出，age属性变为了0，说明被transient关键字修饰之后没有被序列化。

#### 深入分析transient关键字

为了更加深入的去分析transient关键字，我们需要带着几个问题去解读：

1. transient底层实现的原理是什么？

2. 被transient关键字修饰过得变量真的不能被序列化嘛？

3. 静态变量能被序列化吗？被transient关键字修饰之后呢？

###### transient底层实现原理是什么？

java的serialization提供了一个非常棒的存储对象状态的机制，
说白了serialization就是把对象的状态存储到硬盘上 去，
等需要的时候就可以再把它读出来使用。
有些时候像银行卡号这些字段是不希望在网络上传输的，
transient的作用就是把这个字段的生命周期仅存于调用者的内存中而不会写到磁盘里持久化，意思是transient修饰的age字段，
他的生命周期仅仅在内存中，不会被写到磁盘中。

###### 被transient关键字修饰过得变量真的不能被序列化嘛？

想要解决这个问题，首先还要再重提一下对象的序列化方式：

Java序列化提供两种方式。

一种是实现Serializable接口

另一种是实现Exteranlizable接口。
 需要重写writeExternal和readExternal方法，
 它的效率比Serializable高一些
 ，并且可以决定哪些属性需要序列化（即使是transient修饰的），
 但是对大量对象，或者重复对象，则效率低。

从上面的这两种序列化方式，我想你已经看到了，
使用Exteranlizable接口实现序列化时，
我们自己指定那些属性是需要序列化的，即使是transient修饰的。
下面就验证一下

首先我们定义User1类：这个类是被Externalizable接口修饰的

```java

package keyword;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.*;

public class FireTransient {

    public static void main(String[] args) throws IOException, ClassNotFoundException {
        serializeUser1();
        deSerializeUser1();
    }

    private static void serializeUser1() throws IOException {
        File file = new File("/opt/test/");
        if (!file.exists()){
            file.mkdirs();
        }
        User1 u = new User1();
        u.setAge(18);
        u.setName("fire");
        ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("/opt/test/template1"));
        oos.writeObject(u);
        oos.close();
    }

    private static void deSerializeUser1() throws IOException, ClassNotFoundException {

        File file = new File("/opt/test/template1");
        ObjectInputStream ois = new ObjectInputStream(new FileInputStream(file));
        User1 u = (User1) ois.readObject();
        System.out.println(u.toString());
    }
}



@Getter
@Setter
@ToString
class User1 implements Externalizable{
    private transient int age;
    private String name;

    //由于实现了Externalizable接口的类，会调用构造函数，
    // 而User1的构造函数是私有的。无法訪问，从而导致抛出异常。
    public User1(){

    }

    @Override
    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeObject(age);
        out.writeObject(name);
    }

    @Override
    public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
        age = (int)in.readObject();
        name = (String) in.readObject();
    }
}

```

上面，代码分了两个方法，一个是序列化，一个是反序列化。

然后看一下结果：

```console
D:\Java\jdk1.8.0_161\bin\java.exe "-javaagent:D:\JetBrains\IntelliJ IDEA 2019.3.3\lib\idea_rt.jar=63203:D:\JetBrains\IntelliJ IDEA 2019.3.3\bin" -Dfile.encoding=UTF-8 -classpath D:\Java\jdk1.8.0_161\jre\lib\charsets.jar;D:\Java\jdk1.8.0_161\jre\lib\deploy.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\access-bridge-64.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\cldrdata.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\dnsns.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\jaccess.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\jfxrt.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\localedata.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\nashorn.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunec.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunjce_provider.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunmscapi.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\sunpkcs11.jar;D:\Java\jdk1.8.0_161\jre\lib\ext\zipfs.jar;D:\Java\jdk1.8.0_161\jre\lib\javaws.jar;D:\Java\jdk1.8.0_161\jre\lib\jce.jar;D:\Java\jdk1.8.0_161\jre\lib\jfr.jar;D:\Java\jdk1.8.0_161\jre\lib\jfxswt.jar;D:\Java\jdk1.8.0_161\jre\lib\jsse.jar;D:\Java\jdk1.8.0_161\jre\lib\management-agent.jar;D:\Java\jdk1.8.0_161\jre\lib\plugin.jar;D:\Java\jdk1.8.0_161\jre\lib\resources.jar;D:\Java\jdk1.8.0_161\jre\lib\rt.jar;D:\github\program\target\classes;D:\firerepository\org\projectlombok\lombok\1.16.22\lombok-1.16.22.jar keyword.FireTransient
User1(age=18, name=fire)

Process finished with exit code 0
```

结果基本上验证了我们的猜想，也就是说，
实现了Externalizable接口，哪一个属性被序列化使我们手动去指定的，
即使是transient关键字修饰也不起作用。

###### 静态变量能被序列化吗？没被transient关键字修饰之后呢？

这个我可以提前先告诉结果，静态变量是不会被序列化的，
即使没有transient关键字修饰。下面去验证一下，然后再解释原因。

首先，在User类中对age属性添加transient关键字和static关键字修饰。

结果已经很明显了。现在解释一下，为什么会是这样，其实在前面已经提到过了。因为静态变量在全局区,本来流里面就没有写入静态变量,我打印静态变量当然会去全局区查找,而我们的序列化是写到磁盘上的，所以JVM查找这个静态变量的值，是从全局区查找的，而不是磁盘上。user.setAge(18);年龄改成18之后，被写到了全局区，其实就是方法区，只不过被所有的线程共享的一块空间。因此可以总结一句话：

静态变量不管是不是transient关键字修饰，都不会被序列化

#### transient关键字总结

java 的transient关键字为我们提供了便利，
你只需要实现Serilizable接口，
将不需要序列化的属性前添加关键字transient，
序列化对象的时候，这个属性就不会序列化到指定的目的地中。
像银行卡、密码等等这些数据。这个需要根据业务情况了。
