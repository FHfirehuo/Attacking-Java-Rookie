# IOC原理

IOC的从广义范围来说，意思是控制反转，什么是控制反转呢，大家肯定都知道，以前我们要使用一个类里的方法或者属性的时候，我们先要new出这个类的对象，然后用这个对象调用里面的方法的。
这是传统方式上的使用类里的方法和属性，但是这种方式存在很大的耦合性。为了降低耦合性，Spring出了IOC控制反转，它的含义是指，Spring帮助我们来创建对象就是我们所说的bean，并且管理bean对象，当我们需要用的时候，需要Spring提供给我们创建好的bean对象。
这样就从之前我们的主动创建对象变为了，由Spring来控制创建对象，来给我们使用，也就是控制反转的意思。

对于IOC它主要设计了两个接口用来表示容器
* 一个是BeanFactory(低级容器)
* 一个是ApplicationContext(高级容器)

BeanFactory它是IOC容器的顶层的接口，对于BeanFactory这个容器来说，它相当一个HashMap，BeanName作为key，value就是这个bean的实例化对象，通常提供注册（put）和获取（get）两个功能。
这个实现主要是使用的工厂模式+反射技术，来进行对Bean的实例化，然后把这个实例化对象存到HashMap中，下面通过一个简单的例子来展现下BeanFactory是如何使用工厂模式+反射技术创建对象

创建一个接口类
```java
public interface Shape {
    public void draw();
}
```

实现这个接口类
```java
public class Circle implements Shape {
    public void draw(){
        System.out.println("画圆形");
    }
}
public class Square implements Shape {
    public void draw(){
       System.out.println("画方形");
    }
}
```

创建一个工厂类
```java
public class ReflectFactory {
    public Shape getInstance(String className) throws ClassNotFoundException, IllegalAccessException, InstantiationException {
        Shape shape =null;
        shape =(Shape)Class.forName(className).newInstance();
        return shape;
    }
}
```

创建一个Client类来进行测试
```java
public class Client {
   public static void main(String[] args){
       ShapeFactory shapeFactory = new ShapeFactory();
       Shape shape= shapeFactory.getInstance("Circle");
       shape.draw();
   }
}
```

输出的是
> 画圆形

这个简单的小例子就是BeanFactory中通过工厂模式和反射创建对象的一个简单原理，当然BeanFactory的源码要比这个复杂的多。这里就是为了方便大家理解。

而对于ApplicationContext来说，它继承了BeanFactory这个接口，并且丰富了更多了功能在里面，这其中包括回调一些方法。这其中主要的就是有个refresh()方法，这个方法主要是刷新整个容器，即重新加载或者刷新所有的bean。

接下来给大家看下refresh()方法的源码。

```java
1   public void refresh() throws BeansException, IllegalStateException {
 2        Object var1 = this.startupShutdownMonitor;
 3        //首先是synchronized加锁，加这个锁的原因是，避免如果你先调一次refresh()然后这次还没处理完又调一次，就会乱套了
 4        synchronized(this.startupShutdownMonitor) {
 5         //这个方法是做准备工作的，记录容器的启动时间、标记“已启动”状态、处理配置文件中的占位符
 6            this.prepareRefresh();
 7            //这一步是把配置文件解析成一个个Bean，并且注册到BeanFactory中，注意这里只是注册进去，并没有初始化
 8            ConfigurableListableBeanFactory beanFactory = this.obtainFreshBeanFactory();
 9            //设置 BeanFactory 的类加载器，添加几个 BeanPostProcessor，手动注册几个特殊的 bean，这里都是spring里面的特殊处理
10            this.prepareBeanFactory(beanFactory);
11
12            try {
13                //具体的子类可以在这步的时候添加一些特殊的 BeanFactoryPostProcessor 的实现类，来完成一些其他的操作
14                this.postProcessBeanFactory(beanFactory);
15                //这个方法是调用 BeanFactoryPostProcessor 各个实现类的 postProcessBeanFactory(factory)
16                this.invokeBeanFactoryPostProcessors(beanFactory);
17                //这个方法注册 BeanPostProcessor 的实现类
18                this.registerBeanPostProcessors(beanFactory);
19                //这方法是初始化当前 ApplicationContext 的 MessageSource，国际化处理
20                this.initMessageSource();
21                //这个方法初始化当前 ApplicationContext 的事件广播器
22                this.initApplicationEventMulticaster();
23                //这个方法初始化一些特殊的 Bean（在初始化 singleton beans 之前）
24                this.onRefresh();
25                //这个方法注册事件监听器，监听器需要实现 ApplicationListener 接口
26                this.registerListeners();
27
28                //初始化所有的 singleton beans（单例bean），懒加载（non-lazy-init）的除外
29                this.finishBeanFactoryInitialization(beanFactory);
30                //方法是最后一步，广播事件
31                this.finishRefresh();
32            } catch (BeansException var9) {
33                if(this.logger.isWarnEnabled()) {
34                    this.logger.warn("Exception encountered during context initialization - cancelling refresh attempt: " + var9);
35                }
36                //调用销毁bean的方法
37                this.destroyBeans();
38                this.cancelRefresh(var9);
39                throw var9;
40            } finally {
41                this.resetCommonCaches();
42            }
43
44        }
45    }
```

以上就是ApplicationContext中的refresh()这个方法所做的事，里面需要看的重点的方法是ConfigurableListableBeanFactory beanFactory = this.obtainFreshBeanFactory();和this.finishBeanFactoryInitialization(beanFactory);这两个方法，大家有兴趣可以看下里面的源码，这里面包含了bean的一个生命周期。

对上面的两大块分析完成后，那么对于IOC容器的启动过程是什么样呢，说的更直白就是ClassPathXmlApplicationContext这个类启动的时候做了啥？

简单的理解，首先访问的是“高级容器”refresh方法，这个方法是使用低级容器加载所有的BeanDefinition和properties到IOC的容器中，低级容器加载成功后，高级容器开始开始处理一些回调功能。例如Bean后置处理器，回调setBeanFactory方法，和注册监听、发布事件、实例化单例Bean。

IOC做的事其实就是，低级容器（BeanFactory）加载配置文件，解析成BeanDefinition，然后放到一个map里，BeanName作为key ，这个Bean实例化的对象作为value， 使用的时候调用getBean方法，完成依赖注入。

高级容器 （ApplicationContext），它包含了低级容器的功能，当他执行 refresh 模板方法的时候，将刷新整个容器的 Bean。同时其作为高级容器，包含了太多的功能。他支持不同信息源头，支持 BeanFactory 工具类，支持层级容器，支持访问文件资源，支持事件发布通知，支持接口回调等等。
