#  spi

JDK提供的SPI(Service Provider Interface)机制，可能很多人不太熟悉，因为这个机制是针对厂商或者插件的，也可以在一些框架的扩展中看到。
其核心类 java.util.ServiceLoader可以在jdk1.8的文档中看到详细的介绍。
虽然不太常见，但并不代表它不常用，恰恰相反，你无时无刻不在用它。玄乎了，莫急，思考一下你的项目中是否有用到第三方日志包，是否有用到数据库驱动？其实这些都和SPI有关。

再来思考一下，现代的框架是如何加载日志依赖，加载数据库驱动的，你可能会对class.forName("com.mysql.jdbc.Driver")这段代码不陌生，这是每个java初学者必定遇到过的，但如今的数据库驱动仍然是这样加载的吗？你还能找到这段代码吗？
这一切的疑问，将在本篇文章结束后得到解答。

##  什么是SPI机制

那么，什么是SPI机制呢？

SPI是Service Provider Interface 的简称，即服务提供者接口的意思。根据字面意思我们可能还有点困惑，SPI说白了就是一种扩展机制，我们在相应配置文件中定义好某个接口的实现类，然后再根据这个接口去这个配置文件中加载这个实例类并实例化，其实SPI就是这么一个东西。说到SPI机制，我们最常见的就是Java的SPI机制，此外，还有Dubbo和SpringBoot自定义的SPI机制。

有了SPI机制，那么就为一些框架的灵活扩展提供了可能，而不必将框架的一些实现类写死在代码里面。

那么，某些框架是如何利用SPI机制来做到灵活扩展的呢？下面举几个栗子来阐述下：

* JDBC驱动加载案例：利用Java的SPI机制，我们可以根据不同的数据库厂商来引入不同的JDBC驱动包；
* SpringBoot的SPI机制：我们可以在spring.factories中加上我们自定义的自动配置类，事件监听器或初始化器等；
* Dubbo的SPI机制：Dubbo更是把SPI机制应用的淋漓尽致，Dubbo基本上自身的每个功能点都提供了扩展点，比如提供了集群扩展，路由扩展和负载均衡扩展等差不多接近30个扩展点。如果Dubbo的某个内置实现不符合我们的需求，那么我们只要利用其SPI机制将我们的实现替换掉Dubbo的实现即可。

上面的三个栗子先让我们直观感受下某些框架利用SPI机制是如何做到灵活扩展的。

## SPI示例

新建一个项目spi-test,并且下面划分4个模块。

```xml
    <groupId>org.example</groupId>
    <artifactId>spi-test</artifactId>
    <packaging>pom</packaging>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <java.version>1.6</java.version>
    </properties>

    <modules>
        <module>interface</module>
        <module>firelog</module>
        <module>huolog</module>
        <module>test</module>
    </modules>

```

#### interface

```xml
    <parent>
        <artifactId>spi-test</artifactId>
        <groupId>org.example</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>interface</artifactId>

    <properties>
        <java.version>1.6</java.version>
    </properties>
```

```java
package io.github.fire.spi.face;

public interface Logger {

    void info(String log);
}

```


#### firelog

```xml
    <parent>
        <artifactId>spi-test</artifactId>
        <groupId>org.example</groupId>
        <version>1.0-SNAPSHOT</version>

    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>firelog</artifactId>
    

    <properties>
        <java.version>1.6</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.example</groupId>
            <artifactId>interface</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
    </dependencies>

```

```java
package io.github.fire.spi;

import io.github.fire.spi.face.Logger;

public class FireLog implements Logger {
    public void info(String log) {
        System.out.printf("fire out ->" + log);
    }
}

```

#### huolog

```xml
    <parent>
        <artifactId>spi-test</artifactId>
        <groupId>org.example</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>huolog</artifactId>

    <properties>
        <java.version>1.6</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.example</groupId>
            <artifactId>interface</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
    </dependencies>
```

```java
package io.github.fire.spi;

import io.github.fire.spi.face.Logger;

public class HuoLog implements Logger {
    public void info(String log) {
        System.out.printf("huo out -> " + log);
    }
}

```
#### test

```xml
    <parent>
        <artifactId>spi-test</artifactId>
        <groupId>org.example</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>



    <artifactId>test</artifactId>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <source>6</source>
                    <target>6</target>
                </configuration>
            </plugin>
        </plugins>
    </build>

    <properties>
        <java.version>1.6</java.version>
    </properties>



    <dependencies>
        <dependency>
            <groupId>org.example</groupId>
            <artifactId>interface</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>

        <dependency>
            <groupId>org.example</groupId>
            <artifactId>huolog</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>

        <dependency>
            <groupId>org.example</groupId>
            <artifactId>firelog</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
    </dependencies>
```

```test
package io.github.fire.spi;

import io.github.fire.spi.face.Logger;

import java.util.ServiceLoader;

public class Invoker {

    public static void main(String[] args) {

        ServiceLoader<Logger> LOGGER = ServiceLoader.load(Logger.class);
        for (Logger log: LOGGER){
            log.info("hello spi");
        }
        System.out.printf("？？？？？");
    }
}
```

如果直接运行的化，只会打印 *？？？？？* 。因为Logger并不能找到实现类

## 添加SPI支持

在firelog和huolog的resources\META-INF\services下添加文件 *io.github.fire.spi.face.Logger* 并分别添加如下内容

* firelog
> io.github.fire.spi.FireLog
    
* huolog
> io.github.fire.spi.HuoLog

有没有发现点什么？不错文件名为接口 *Logger* 的全路径内容为各自实现的全路径

这里需要重点说明，每一个SPI接口都需要在自己项目的静态资源目录中声明一个services文件，文件名为实现规范接口的类名全路径



再次运行

> huo out -> hello spifire out ->hello spi？？？？？

这样一个厂商的实现便完成了。

## SPI在实际项目中的应用

#### mysql
在mysql-connector-java-xxx.jar中发现了META-INF\services\java.sql.Driver文件，里面只有两行记录：

```

com.mysql.jdbc.Driver
com.mysql.fabric.jdbc.FabricMySQLDriver


```

我们可以分析出， java.sql.Driver是一个规范接口， com.mysql.jdbc.Driver com.mysql.fabric.jdbc.FabricMySQLDriver则是mysql-connector-java-xxx.jar对这个规范的实现接口。

#### slf4j
在jcl-over-slf4j-xxxx.jar中发现了META-INF\services\org.apache.commons.logging.LogFactory文件，里面只有一行记录：

```
org.apache.commons.logging.impl.SLF4JLogFactory
```

## Java的SPI机制的源码解读

通过前面扩展Developer接口的简单Demo，我们看到Java的SPI机制实现跟ServiceLoader这个类有关，那么我们先来看下ServiceLoader的类结构代码：

```java
// ServiceLoader实现了【Iterable】接口
public final class ServiceLoader<S>
    implements Iterable<S>{
    private static final String PREFIX = "META-INF/services/";
    // The class or interface representing the service being loaded
    private final Class<S> service;
    // The class loader used to locate, load, and instantiate providers
    private final ClassLoader loader;
    // The access control context taken when the ServiceLoader is created
    private final AccessControlContext acc;
    // Cached providers, in instantiation order
    private LinkedHashMap<String,S> providers = new LinkedHashMap<>();
    // The current lazy-lookup iterator
    private LazyIterator lookupIterator;
    // 构造方法
    private ServiceLoader(Class<S> svc, ClassLoader cl) {
        service = Objects.requireNonNull(svc, "Service interface cannot be null");
        loader = (cl == null) ? ClassLoader.getSystemClassLoader() : cl;
        acc = (System.getSecurityManager() != null) ? AccessController.getContext() : null;
        reload();
    }
	
    // ...暂时省略相关代码
    
    // ServiceLoader的内部类LazyIterator,实现了【Iterator】接口
    // Private inner class implementing fully-lazy provider lookup
    private class LazyIterator
        implements Iterator<S>{
        Class<S> service;
        ClassLoader loader;
        Enumeration<URL> configs = null;
        Iterator<String> pending = null;
        String nextName = null;

        private LazyIterator(Class<S> service, ClassLoader loader) {
            this.service = service;
            this.loader = loader;
        }
        // 覆写Iterator接口的hasNext方法
        public boolean hasNext() {
            // ...暂时省略相关代码
        }
        // 覆写Iterator接口的next方法
        public S next() {
            // ...暂时省略相关代码
        }
        // 覆写Iterator接口的remove方法
        public void remove() {
            // ...暂时省略相关代码
        }

    }

    // 覆写Iterable接口的iterator方法，返回一个迭代器
    public Iterator<S> iterator() {
        // ...暂时省略相关代码
    }

    // ...暂时省略相关代码

}
```

可以看到，ServiceLoader实现了Iterable接口，覆写其iterator方法能产生一个迭代器；同时ServiceLoader有一个内部类LazyIterator，而LazyIterator又实现了Iterator接口，说明LazyIterator是一个迭代器。

####  ServiceLoader.load方法，为加载服务提供者实现类做前期准备

那么我们现在开始探究Java的SPI机制的源码，
先来看JdkSPITest的第一句代码ServiceLoader<Developer> serviceLoader = ServiceLoader.load(Developer.class);中的ServiceLoader.load(Developer.class);的源码：

```java
// ServiceLoader.java

public static <S> ServiceLoader<S> load(Class<S> service) {
    //获取当前线程上下文类加载器 
    ClassLoader cl = Thread.currentThread().getContextClassLoader();
    // 将service接口类和线程上下文类加载器作为参数传入，继续调用load方法
    return ServiceLoader.load(service, cl);
}
```
我们再来看下ServiceLoader.load(service, cl);方法：
```java
// ServiceLoader.java

public static <S> ServiceLoader<S> load(Class<S> service,
                                        ClassLoader loader)
{
    // 将service接口类和线程上下文类加载器作为构造参数，新建了一个ServiceLoader对象
    return new ServiceLoader<>(service, loader);
}
```
继续看new ServiceLoader<>(service, loader);是如何构建的？

```java
// ServiceLoader.java

private ServiceLoader(Class<S> svc, ClassLoader cl) {
    service = Objects.requireNonNull(svc, "Service interface cannot be null");
    loader = (cl == null) ? ClassLoader.getSystemClassLoader() : cl;
    acc = (System.getSecurityManager() != null) ? AccessController.getContext() : null;
    reload();
}
```
可以看到在构建ServiceLoader对象时除了给其成员属性赋值外，还调用了reload方法：
```java
// ServiceLoader.java

public void reload() {
    providers.clear();
    lookupIterator = new LazyIterator(service, loader);
}
```
可以看到在reload方法中又新建了一个LazyIterator对象，然后赋值给lookupIterator。

```java
// ServiceLoader$LazyIterator.java

private LazyIterator(Class<S> service, ClassLoader loader) {
    this.service = service;
    this.loader = loader;
}
```

可以看到在构建LazyIterator对象时，也只是给其成员变量service和loader属性赋值呀，我们一路源码跟下来，也没有看到去META-INF/services文件夹加载Developer接口的实现类！这就奇怪了，我们都被ServiceLoader的load方法名骗了。

还记得分析前面的代码时新建了一个LazyIterator对象吗？Lazy顾名思义是懒的意思，Iterator就是迭代的意思。我们此时猜测那么LazyIterator对象的作用应该就是在迭代的时候再去加载Developer接口的实现类了。

#### ServiceLoader.iterator方法，实现服务提供者实现类的懒加载

我们现在再来看JdkSPITest的第二句代码serviceLoader.forEach(Developer::sayHi);，执行这句代码后最终会调用serviceLoader的iterator方法：

```java
// serviceLoader.java

public Iterator<S> iterator() {
    return new Iterator<S>() {

        Iterator<Map.Entry<String,S>> knownProviders
            = providers.entrySet().iterator();

        public boolean hasNext() {
            if (knownProviders.hasNext())
                return true;
            // 调用lookupIterator即LazyIterator的hasNext方法
            // 可以看到是委托给LazyIterator的hasNext方法来实现
            return lookupIterator.hasNext();
        }

        public S next() {
            if (knownProviders.hasNext())
                return knownProviders.next().getValue();
            // 调用lookupIterator即LazyIterator的next方法
            // 可以看到是委托给LazyIterator的next方法来实现
            return lookupIterator.next();
        }

        public void remove() {
            throw new UnsupportedOperationException();
        }

    };
}
```

可以看到调用serviceLoader的iterator方法会返回一个匿名的迭代器对象，而这个匿名迭代器对象其实相当于一个门面类，其覆写的hasNext和next方法又分别委托LazyIterator的hasNext和next方法来实现了。

我们继续调试，发现接下来会进入LazyIterator的hasNext方法：
```java
// serviceLoader$LazyIterator.java

public boolean hasNext() {
    if (acc == null) {
        // 调用hasNextService方法
        return hasNextService();
    } else {
        PrivilegedAction<Boolean> action = new PrivilegedAction<Boolean>() {
            public Boolean run() { return hasNextService(); }
        };
        return AccessController.doPrivileged(action, acc);
    }
}
```

继续跟进hasNextService方法：

```java
// serviceLoader$LazyIterator.java

private boolean hasNextService() {
    if (nextName != null) {
        return true;
    }
    if (configs == null) {
        try {
            // PREFIX = "META-INF/services/"
            // service.getName()即接口的全限定名
            // 还记得前面的代码构建LazyIterator对象时已经给其成员属性service赋值吗
            String fullName = PREFIX + service.getName();
            // 加载META-INF/services/目录下的接口文件中的服务提供者类
            if (loader == null)
                configs = ClassLoader.getSystemResources(fullName);
            else
                // 还记得前面的代码构建LazyIterator对象时已经给其成员属性loader赋值吗
                configs = loader.getResources(fullName);
        } catch (IOException x) {
            fail(service, "Error locating configuration files", x);
        }
    }
    while ((pending == null) || !pending.hasNext()) {
        if (!configs.hasMoreElements()) {
            return false;
        }
        // 返回META-INF/services/目录下的接口文件中的服务提供者类并赋值给pending属性
        pending = parse(service, configs.nextElement());
    }
    // 然后取出一个全限定名赋值给LazyIterator的成员变量nextName
    nextName = pending.next();
    return true;
}
```

可以看到在执行LazyIterator的hasNextService方法时最终将去META-INF/services/目录下加载接口文件的内容即加载服务提供者实现类的全限定名，然后取出一个服务提供者实现类的全限定名赋值给LazyIterator的成员变量nextName。到了这里，我们就明白了LazyIterator的作用真的是懒加载，在用到的时候才会去加载。

> 思考：为何这里要用懒加载呢？懒加载的思想是怎样的呢？懒加载有啥好处呢？你还能举出其他懒加载的案例吗？

同样，执行完LazyIterator的hasNext方法后，会继续执行LazyIterator的next方法：

```java
// serviceLoader$LazyIterator.java

public S next() {
    if (acc == null) {
        // 调用nextService方法
        return nextService();
    } else {
        PrivilegedAction<S> action = new PrivilegedAction<S>() {
            public S run() { return nextService(); }
        };
        return AccessController.doPrivileged(action, acc);
    }
}
```

我们继续跟进nextService方法：

```java
// serviceLoader$LazyIterator.java

private S nextService() {
    if (!hasNextService())
        throw new NoSuchElementException();
    // 还记得在hasNextService方法中为nextName赋值过服务提供者实现类的全限定名吗
    String cn = nextName;
    nextName = null;
    Class<?> c = null;
    try {
        // 【1】去classpath中根据传入的类加载器和服务提供者实现类的全限定名去加载服务提供者实现类
        c = Class.forName(cn, false, loader);
    } catch (ClassNotFoundException x) {
        fail(service,
             "Provider " + cn + " not found");
    }
    if (!service.isAssignableFrom(c)) {
        fail(service,
             "Provider " + cn  + " not a subtype");
    }
    try {
        // 【2】实例化刚才加载的服务提供者实现类，并进行转换
        S p = service.cast(c.newInstance());
        // 【3】最终将实例化后的服务提供者实现类放进providers集合
        providers.put(cn, p);
        return p;
    } catch (Throwable x) {
        fail(service,
             "Provider " + cn + " could not be instantiated",
             x);
    }
    throw new Error();          // This cannot happen
}
```

可以看到LazyIterator的nextService方法最终将实例化之前加载的服务提供者实现类，并放进providers集合中，随后再调用服务提供者实现类的方法（比如这里指JavaDeveloper的sayHi方法）。注意，这里是加载一个服务提供者实现类后，若main函数中有调用该服务提供者实现类的方法的话，紧接着会调用其方法；然后继续实例化下一个服务提供者类。

> 设计模式：可以看到，Java的SPI机制实现代码中应用了迭代器模式，迭代器模式屏蔽了各种存储对象的内部结构差异，提供一个统一的视图来遍历各个存储对象（存储对象可以为集合，数组等）。java.util.Iterator也是迭代器模式的实现：同时Java的各个集合类一般实现了Iterable接口，实现了其iterator方法从而获得Iterator接口的实现类对象（一般为集合内部类），然后再利用Iterator对象的实现类的hasNext和next方法来遍历集合元素。



## 画外题

既然说到了数据库驱动，索性再多说一点，还记得一道经典的面试题：class.forName("com.mysql.jdbc.Driver")到底做了什么事？

先思考下：自己会怎么回答？

都知道class.forName与类加载机制有关，会触发执行com.mysql.jdbc.Driver类中的静态方法，从而使主类加载数据库驱动。
如果再追问，为什么它的静态块没有自动触发？可答：因为数据库驱动类的特殊性质，JDBC规范中明确要求Driver类必须向DriverManager注册自己，导致其必须由class.forName手动触发，这可以在java.sql.Driver中得到解释。
完美了吗？还没，来到最新的DriverManager源码中，可以看到这样的注释,翻译如下：

> DriverManager 类的方法 getConnection 和 getDrivers 已经得到提高以支持 Java Standard Edition Service Provider 机制。 
> JDBC 4.0 Drivers 必须包括 META-INF/services/java.sql.Driver 文件。此文件包含 java.sql.Driver 的 JDBC 驱动程序实现的名称。
> 例如，要加载 my.sql.Driver 类， META-INF/services/java.sql.Driver 文件需要包含下面的条目：
  
    my.sql.Driver
  
> 应用程序不再需要使用 Class.forName() 显式地加载 JDBC 驱动程序。当前使用 Class.forName() 加载 JDBC 驱动程序的现有程序将在不作修改的情况下继续工作。

可以发现，Class.forName已经被弃用了，所以，这道题目的最佳回答，应当是和面试官牵扯到JAVA中的SPI机制，进而聊聊加载驱动的演变历史。

```java
java.sql.DriverManager

```

在JdbcTest的main函数调用DriverManager的getConnection方法时，此时必然会先执行DriverManager类的静态代码块的代码，然后再执行getConnection方法，那么先来看下DriverManager的静态代码块：

```java
// DriverManager.java

static {
    // 加载驱动实现类
    loadInitialDrivers();
    println("JDBC DriverManager initialized");
}
```

继续跟进loadInitialDrivers的代码：

```java
// DriverManager.java

private static void loadInitialDrivers() {
    String drivers;
    try {
        drivers = AccessController.doPrivileged(new PrivilegedAction<String>() {
            public String run() {
                return System.getProperty("jdbc.drivers");
            }
        });
    } catch (Exception ex) {
        drivers = null;
    }
    AccessController.doPrivileged(new PrivilegedAction<Void>() {
        public Void run() {
            // 来到这里，是不是感觉似曾相识，对，没错，我们在前面的JdkSPITest代码中执行过下面的两句代码
            // 这句代码前面已经分析过，这里不会真正加载服务提供者实现类
            // 而是实例化一个ServiceLoader对象且实例化一个LazyIterator对象用于懒加载
            ServiceLoader<Driver> loadedDrivers = ServiceLoader.load(Driver.class);
            // 调用ServiceLoader的iterator方法，在迭代的同时，也会去加载并实例化META-INF/services/java.sql.Driver文件
            // 的com.mysql.jdbc.Driver和com.mysql.fabric.jdbc.FabricMySQLDriver两个驱动类
            /****************【主线，重点关注】**********************/
            Iterator<Driver> driversIterator = loadedDrivers.iterator();
            try{
                while(driversIterator.hasNext()) {
                    driversIterator.next();
                }
            } catch(Throwable t) {
            // Do nothing
            }
            return null;
        }
    });

    println("DriverManager.initialize: jdbc.drivers = " + drivers);

    if (drivers == null || drivers.equals("")) {
        return;
    }
    String[] driversList = drivers.split(":");
    println("number of Drivers:" + driversList.length);
    for (String aDriver : driversList) {
        try {
            println("DriverManager.Initialize: loading " + aDriver);
            Class.forName(aDriver, true,
                    ClassLoader.getSystemClassLoader());
        } catch (Exception ex) {
            println("DriverManager.Initialize: load failed: " + ex);
        }
    }
}
```

在上面的代码中，我们可以看到Mysql的驱动类加载主要是利用Java的SPI机制实现的，即利用ServiceLoader来实现加载并实例化Mysql的驱动类。

#### 注册Mysql的驱动类


那么，上面的代码只是Mysql驱动类的加载和实例化，那么，驱动类又是如何被注册进DriverManager的registeredDrivers集合的呢？

这时，我们注意到com.mysql.jdbc.Driver类里面也有个静态代码块，即实例化该类时肯定会触发该静态代码块代码的执行，那么我们直接看下这个静态代码块做了什么事情：

```java
// com.mysql.jdbc.Driver.java

// Register ourselves with the DriverManager
static {
    try {
        // 将自己注册进DriverManager类的registeredDrivers集合
        java.sql.DriverManager.registerDriver(new Driver());
    } catch (SQLException E) {
        throw new RuntimeException("Can't register driver!");
    }
}
```

可以看到，原来就是Mysql驱动类com.mysql.jdbc.Driver在实例化的时候，利用执行其静态代码块的时机时将自己注册进DriverManager的registeredDrivers集合中。

好，继续跟进DriverManager的registerDriver方法：

```java
// DriverManager.java

public static synchronized void registerDriver(java.sql.Driver driver)
    throws SQLException {
    // 继续调用registerDriver方法
    registerDriver(driver, null);
}

public static synchronized void registerDriver(java.sql.Driver driver,
        DriverAction da)
    throws SQLException {

    /* Register the driver if it has not already been added to our list */
    if(driver != null) {
        // 将driver驱动类实例注册进registeredDrivers集合
        registeredDrivers.addIfAbsent(new DriverInfo(driver, da));
    } else {
        // This is for compatibility with the original DriverManager
        throw new NullPointerException();
    }
    println("registerDriver: " + driver);
}
```

分析到了这里，我们就明白了Java的SPI机制是如何加载Mysql的驱动类的并如何将Mysql的驱动类注册进DriverManager的registeredDrivers集合中的。

#### 使用之前注册的Mysql驱动类连接数据库

既然Mysql的驱动类已经被注册进来了，那么何时会被用到呢？

我们要连接Mysql数据库，自然需要用到Mysql的驱动类，对吧。此时我们回到JDBC的测试代码JdbcTest类的connection = DriverManager.getConnection("jdbc:mysql://localhost:3306/jdbc", "root", "123456");这句代码中，看一下getConnection的源码：


```java
// DriverManager.java

@CallerSensitive
public static Connection getConnection(String url,
    String user, String password) throws SQLException {
    java.util.Properties info = new java.util.Properties();

    if (user != null) {
        info.put("user", user);
    }
    if (password != null) {
        info.put("password", password);
    }
    // 继续调用getConnection方法来连接数据库
    return (getConnection(url, info, Reflection.getCallerClass()));
}
```

继续跟进getConnection方法：

```java
// DriverManager.java

private static Connection getConnection(
        String url, java.util.Properties info, Class<?> caller) throws SQLException {
        
        ClassLoader callerCL = caller != null ? caller.getClassLoader() : null;
        synchronized(DriverManager.class) {
            // synchronize loading of the correct classloader.
            if (callerCL == null) {
                callerCL = Thread.currentThread().getContextClassLoader();
            }
        }
        if(url == null) {
            throw new SQLException("The url cannot be null", "08001");
        }
        println("DriverManager.getConnection(\"" + url + "\")");
        // Walk through the loaded registeredDrivers attempting to make a connection.
        // Remember the first exception that gets raised so we can reraise it.
        SQLException reason = null;
        // 遍历registeredDrivers集合，注意之前加载的Mysql驱动类实例被注册进这个集合
        for(DriverInfo aDriver : registeredDrivers) {
            // If the caller does not have permission to load the driver then
            // skip it.
            // 判断有无权限
            if(isDriverAllowed(aDriver.driver, callerCL)) {
                try {
                    println("    trying " + aDriver.driver.getClass().getName());
                    // 利用Mysql驱动类来连接数据库
                    /*************【主线，重点关注】*****************/
                    Connection con = aDriver.driver.connect(url, info);
                    // 只要连接上，那么加载的其余驱动类比如FabricMySQLDriver将会忽略，因为下面直接返回了
                    if (con != null) {
                        // Success!
                        println("getConnection returning " + aDriver.driver.getClass().getName());
                        return (con);
                    }
                } catch (SQLException ex) {
                    if (reason == null) {
                        reason = ex;
                    }
                }

            } else {
                println("    skipping: " + aDriver.getClass().getName());
            }

        }

        // if we got here nobody could connect.
        if (reason != null)    {
            println("getConnection failed: " + reason);
            throw reason;
        }

        println("getConnection: no suitable driver found for "+ url);
        throw new SQLException("No suitable driver found for "+ url, "08001");
    }
```

可以看到，DriverManager的getConnection方法会从registeredDrivers集合中拿出刚才加载的Mysql驱动类来连接数据库。

好了，到了这里，JDBC驱动加载的源码就基本分析完了。

## 线程上下文类加载器

前面基本分析完了JDBC驱动加载的源码，但是还有一个很重要的知识点还没讲解，那就是破坏类加载机制的双亲委派模型的线程上下文类加载器。

我们都知道，JDBC规范的相关类（比如前面的java.sql.Driver和java.sql.DriverManager）都是在Jdk的rt.jar包下，意味着这些类将由启动类加载器(BootstrapClassLoader)加载；而Mysql的驱动类由外部数据库厂商实现，当驱动类被引进项目时也是位于项目的classpath中,此时启动类加载器肯定是不可能加载这些驱动类的呀，此时该怎么办？

由于类加载机制的双亲委派模型在这方面的缺陷，因此只能打破双亲委派模型了。因为项目classpath中的类是由应用程序类加载器(AppClassLoader)来加载，所以我们可否"逆向"让启动类加载器委托应用程序类加载器去加载这些外部数据库厂商的驱动类呢？如果可以，我们怎样才能做到让启动类加载器委托应用程序类加载器去加载
classpath中的类呢？

答案肯定是可以的，我们可以将应用程序类加载器设置进线程里面，即线程里面新定义一个类加载器的属性contextClassLoader，然后在某个时机将应用程序类加载器设置进线程的contextClassLoader这个属性里面，如果没有设置的话，那么默认就是应用程序类加载器。然后启动类加载器去加载java.sql.Driver和java.sql.DriverManager等类时，同时也会从当前线程中取出contextClassLoader即应用程序类加载器去classpath中加载外部厂商提供的JDBC驱动类。因此，通过破坏类加载机制的双亲委派模型，利用线程上下文类加载器完美的解决了该问题。

此时我们再回过头来看下在加载Mysql驱动时是什么时候获取的线程上下文类加载器呢？

答案就是在DriverManager的loadInitialDrivers方法调用了ServiceLoader<Driver> loadedDrivers = ServiceLoader.load(Driver.class);这句代码，而取出线程上下文类加载器就是在ServiceLoader的load方法中取出：

```java
public static <S> ServiceLoader<S> load(Class<S> service) {
    // 取出线程上下文类加载器取出的是contextClassLoader，而contextClassLoader装的应用程序类加载器
    ClassLoader cl = Thread.currentThread().getContextClassLoader();
    // 把刚才取出的线程上下文类加载器作为参数传入，用于后去加载classpath中的外部厂商提供的驱动类
    return ServiceLoader.load(service, cl);
}
```

因此，到了这里，我们就明白了线程上下文类加载器在加载JDBC驱动包中充当的作用了。此外，我们应该知道，Java的绝大部分涉及SPI的加载都是利用线程上下文类加载器来完成的，比如JNDI,JCE,JBI等。

扩展：打破类加载机制的双亲委派模型的还有代码的热部署等，另外，Tomcat的类加载机制也值得一读。


```java

```

## 扩展：Dubbo的SPI机制

前面也讲到Dubbo框架身上处处是SPI机制的应用，可以说处处都是扩展点，真的是把SPI机制应用的淋漓尽致。但是Dubbo没有采用默认的Java的SPI机制，而是自己实现了一套SPI机制。
   
那么，Dubbo为什么没有采用Java的SPI机制呢？
   
原因主要有两个：
   
* Java的SPI机制会一次性实例化扩展点所有实现，如果有扩展实现初始化很耗时，但如果没用上也加载，会很浪费资源;
* Java的SPI机制没有Ioc和AOP的支持，因此Dubbo用了自己的SPI机制：增加了对扩展点IoC和AOP的支持，一个扩展点可以直接setter注入其它扩展点。
   
由于以上原因，Dubbo自定义了一套SPI机制，用于加载自己的扩展点。关于Dubbo的SPI机制这里不再详述，感兴趣的小伙伴们可以去Dubbo官网看看是如何扩展Dubbo的SPI的？还有其官网也有Duboo的SPI的源码分析文章。