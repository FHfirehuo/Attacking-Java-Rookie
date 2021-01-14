# 建造者模（构建者模式）

建造者模式（Builder Pattern）将一个复杂对象的构建与它的表示分离，使得同样的构建过程可以创建不同的表示。
一个 Builder 类会一步一步构造**复杂的**最终对象，它允许用户只通过指定复杂对象的类型和内容就可以构建它们，
用户不需要知道内部的具体构建细节。该 Builder 类是独立于其他对象的。

这种类型的设计模式属于创建型模式，它提供了一种创建对象的最佳方式。

在建造者模式的定义中提到了复杂对象，那么什么是复杂对象？
简单来说，复杂对象是指那些包含多个成员属性的对象；
这些成员属性也称为部件或零件，如汽车包括方向盘、发动机、轮胎等部件，电子邮件包括发件人、收件人、主题、内容、附件等部件

### 介绍
* 意图：将一个复杂的构建与其表示相分离，使得同样的构建过程可以创建不同的表示。
* 主要解决：主要解决在软件系统中，有时候面临着"一个复杂对象"的创建工作，其通常由各个部分的子对象用一定的算法构成；由于需求的变化，这个复杂对象的各个部分经常面临着剧烈的变化，但是将它们组合在一起的算法却相对稳定。
* 何时使用：一些基本部件不会变，而其组合经常变化的时候。
* 如何解决：将变与不变分离开。
* 关键代码：建造者：创建和提供实例，导演：管理建造出来的实例的依赖关系。

### 应用实例 

1. 去肯德基，汉堡、可乐、薯条、炸鸡翅等是不变的，而其组合是经常变化的，生成出所谓的"套餐"。 
2. JAVA 中的 StringBuilder。

### 优点
1. 建造者独立，易扩展。 
2. 便于控制细节风险。

在建造者模式中，客户端不必知道产品内部组成的细节，将产品本身与产品的创建过程解耦，
使得相同的创建过程可以创建不同的产品对象。
每一个具体建造者都相对独立，而与其他的具体建造者无关，因此可以很方便地替换具体建造者或增加新的具体建造者，用户使用不同的具体建造者即可得到不同的产品对象。
由于指挥者类针对抽象建造者编程，增加新的具体建造者无须修改原有类库的代码，系统扩展方便，符合 “开闭原则”。
可以更加精细地控制产品的创建过程。
将复杂产品的创建步骤分解在不同的方法中，使得创建过程更加清晰，也更方便使用程序来控制创建过程。

### 缺点
1. 产品必须有共同点，范围有限制。 
2. 如内部变化复杂，会有很多的建造类。

建造者模式所创建的产品一般具有较多的共同点，其组成部分相似，如果产品之间的差异性很大，例如很多组成部分都不相同，不适合使用建造者模式，因此其使用范围受到一定的限制。
如果产品的内部变化复杂，可能会导致需要定义很多具体建造者类来实现这种变化，导致系统变得很庞大，增加系统的理解难度和运行成本。

### 使用场景： 

1. 需要生成的对象具有复杂的内部结构。 
2. 需要生成的对象内部属性本身相互依赖。

需要生成的产品对象有复杂的内部结构，这些产品对象通常包含多个成员属性。
需要生成的产品对象的属性相互依赖，需要指定其生成顺序。
对象的创建过程独立于创建该对象的类。在建造者模式中通过引入了指挥者类，将创建过程封装在指挥者类中，而不在建造者类和客户类中。
隔离复杂对象的创建和使用，并使得相同的创建过程可以创建不同的产品。

### 注意事项：

### 与工厂模式的区别

建造者模式更加关注与零件装配的顺序。

#### 角色
* Builder（抽象建造者）：它为创建一个产品Product对象的各个部件指定抽象接口，在该接口中一般声明两类方法，一类方法是buildPartX()，它们用于创建复杂对象的各个部件；另一类方法是getResult()，它们用于返回复杂对象。Builder既可以是抽象类，也可以是接口。
* ConcreteBuilder（具体建造者）：它实现了Builder接口，实现各个部件的具体构造和装配方法，定义并明确它所创建的复杂对象，也可以提供一个方法返回创建好的复杂产品对象。
* Product（产品角色）：它是被构建的复杂对象，包含多个组成部件，具体建造者创建该产品的内部表示并定义它的装配过程。
* Director（指挥者）：指挥者又称为导演类，它负责安排复杂对象的建造次序，指挥者与抽象建造者之间存在关联关系，可以在其construct()建造方法中调用建造者对象的部件构造与装配方法，完成复杂对象的建造。客户端一般只需要与指挥者进行交互，在客户端确定具体建造者的类型，并实例化具体建造者对象（也可以通过配置文件和反射机制），然后通过指挥者类的构造函数或者Setter方法将该对象传入指挥者类中。

### 代码展示

抽象构建者

定义产品

```java
package designpatterns.builder;

public class Product {

    private String name;
    private String type;
    public void showProduct(){
        System.out.println("名称："+name);
        System.out.println("型号："+type);
    }
    public void setName(String name) {
        this.name = name;
    }
    public void setType(String type) {
        this.type = type;
    }
}

```

```java
package designpatterns.builder;

public abstract class Builder {

    public abstract void setPart(String arg1, String arg2);
    public abstract Product getProduct();
}

```

构建者实现
```java
package designpatterns.builder;

public class ConcreteBuilder extends Builder {

    private Product product = new Product();

    public Product getProduct() {
        return product;
    }

    public void setPart(String arg1, String arg2) {
        product.setName(arg1);
        product.setType(arg2);
    }
}

```

构建者目录
```java
package designpatterns.builder;

public class Director {

    private Builder builder = new ConcreteBuilder();
    public Product getAProduct(){
        builder.setPart("宝马汽车","X7");
        return builder.getProduct();
    }
    public Product getBProduct(){
        builder.setPart("奥迪汽车","Q5");
        return builder.getProduct();
    }
}

```

运行
```java
package designpatterns.builder;

public class BuilderMain {
    public static void main(String[] args) {

        Director director = new Director();
        Product product1 = director.getAProduct();
        product1.showProduct();

        Product product2 = director.getBProduct();
        product2.showProduct();

    }
}

```

运行结果
```console
名称：宝马汽车
型号：X7
名称：奥迪汽车
型号：Q5
```





### 建造者模式的典型应用和源码分析

##### java.lang.StringBuilder 中的建造者模式

StringBuilder 中的 append 方法使用了建造者模式，不过装配方法只有一个，并不算复杂，append 方法返回的是 StringBuilder 自身

StringBuilder 的父类 AbstractStringBuilder 实现了 Appendable 接口

```java
abstract class AbstractStringBuilder implements Appendable, CharSequence {
    char[] value;
    int count;

    public AbstractStringBuilder append(String str) {
        if (str == null)
            return appendNull();
        int len = str.length();
        ensureCapacityInternal(count + len);
        str.getChars(0, len, value, count);
        count += len;
        return this;
    }

    private void ensureCapacityInternal(int minimumCapacity) {
        // overflow-conscious code
        if (minimumCapacity - value.length > 0) {
            value = Arrays.copyOf(value,
                    newCapacity(minimumCapacity));
        }
    }
    // ...省略...
}
```

我们可以看出，Appendable 为抽象建造者，定义了建造方法，StringBuilder 既充当指挥者角色，又充当产品角色，又充当具体建造者，建造方法的实现由 AbstractStringBuilder 完成，而 StringBuilder 继承了 AbstractStringBuilder


##### java.lang.StringBuffer 中的建造者方法

```java
public final class StringBuffer extends AbstractStringBuilder implements java.io.Serializable, CharSequence {
    @Override
    public synchronized StringBuffer append(String str) {
        toStringCache = null;
        super.append(str);
        return this;
    }
    //...省略...
}
```

看 StringBuffer 的源码如上，它们的区别就是： StringBuffer 中的 append 加了 synchronized 关键字，所以StringBuffer 是线程安全的，而 StringBuilder 是非线程安全的

StringBuffer 中的建造者模式与 StringBuilder 是一致的

##### mybatis 中的建造者模式

我们来看 org.apache.ibatis.session 包下的 SqlSessionFactoryBuilder 类

里边很多重载的 build 方法，返回值都是 SqlSessionFactory，除了最后两个所有的 build 最后都调用下面这个 build 方法

```java
    public SqlSessionFactory build(Reader reader, String environment, Properties properties) {
        SqlSessionFactory var5;
        try {
            XMLConfigBuilder parser = new XMLConfigBuilder(reader, environment, properties);
            var5 = this.build(parser.parse());
        } catch (Exception var14) {
            throw ExceptionFactory.wrapException("Error building SqlSession.", var14);
        } finally {
            ErrorContext.instance().reset();
            try {
                reader.close();
            } catch (IOException var13) {
                ;
            }
        }
        return var5;
    }
```

其中最重要的是 XMLConfigBuilder 的 parse 方法，代码如下

```java
    public SqlSessionFactory build(Reader reader, String environment, Properties properties) {
        SqlSessionFactory var5;
        try {
            XMLConfigBuilder parser = new XMLConfigBuilder(reader, environment, properties);
            var5 = this.build(parser.parse());
        } catch (Exception var14) {
            throw ExceptionFactory.wrapException("Error building SqlSession.", var14);
        } finally {
            ErrorContext.instance().reset();
            try {
                reader.close();
            } catch (IOException var13) {
                ;
            }
        }
        return var5;
    }
其中最重要的是 XMLConfigBuilder 的 parse 方法，代码如下

public class XMLConfigBuilder extends BaseBuilder {
    public Configuration parse() {
        if (this.parsed) {
            throw new BuilderException("Each XMLConfigBuilder can only be used once.");
        } else {
            this.parsed = true;
            this.parseConfiguration(this.parser.evalNode("/configuration"));
            return this.configuration;
        }
    }

    private void parseConfiguration(XNode root) {
        try {
            Properties settings = this.settingsAsPropertiess(root.evalNode("settings"));
            this.propertiesElement(root.evalNode("properties"));
            this.loadCustomVfs(settings);
            this.typeAliasesElement(root.evalNode("typeAliases"));
            this.pluginElement(root.evalNode("plugins"));
            this.objectFactoryElement(root.evalNode("objectFactory"));
            this.objectWrapperFactoryElement(root.evalNode("objectWrapperFactory"));
            this.reflectorFactoryElement(root.evalNode("reflectorFactory"));
            this.settingsElement(settings);
            this.environmentsElement(root.evalNode("environments"));
            this.databaseIdProviderElement(root.evalNode("databaseIdProvider"));
            this.typeHandlerElement(root.evalNode("typeHandlers"));
            this.mapperElement(root.evalNode("mappers"));
        } catch (Exception var3) {
            throw new BuilderException("Error parsing SQL Mapper Configuration. Cause: " + var3, var3);
        }
    }
    // ...省略...
}
```


parse 方法最终要返回一个 Configuration 对象，构建 Configuration 对象的建造过程都在 parseConfiguration 方法中，这也就是 Mybatis 解析 XML配置文件 来构建 Configuration 对象的主要过程

所以 XMLConfigBuilder 是建造者 SqlSessionFactoryBuilder 中的建造者，复杂产品对象分别是 SqlSessionFactory 和 Configuration

