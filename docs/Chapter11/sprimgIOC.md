# 春天来了----水

春天来了，冰雪消融，加工厂（BeanFactory）带着设计图来了， 加工厂专门生产各种水（Bean）。一脸懵逼？ 这里说的就是SpringIOC。IOC做了Spring的一大基石，这里比喻成春天的水也不为过吧。

你会不会想你把IOC比喻成水，那么AOP你比喻成啥东东啊？这里其实早就想好了(春天来了----风)[]，是不是很贴切？无孔不入、见缝插针。

## 概念

这里先确认几个概念
* IOC：IInversion of Control，即“控制反转”，不是什么技术，而是一种设计思想。这里也不是Java或者Spring独有的，其它语言也有。
* DI： Dependency Injection，即“依赖注入”，组件之间依赖关系由容器在运行期决定，形象的说，即由容器动态的将某个依赖关系注入到组件之中。

Spring中的DI其实是IOC具体实现方式，及通过依赖注入完成了控制反转。而且spring官方文档上也提出要把IOC的表述改了DI。

## 创建流程
先大致说着spring创建Bean的整体流程下面在细讲:

确认这个地方是不是春天真的来了(准备环境)-> 准备工厂图纸建设空工厂 -> 找水源（寻找class对象） -> 取水工具取水  -> 填充工厂 -> 调试工程（准备工厂环境） -> 专家提出修改意见（制定工厂后置处理器）  ->  执行修改意见（执行工厂后置处理器）-> 定义产品包装方案 （定义Bean的后置处理器） -> 国际化扩张（国际化） -> 准备新闻发布会（定义事件） ->  通电运行（启动web容器） -> 邀请参会人员见证各个里程碑事件（定义监听器） -> 生产产品（实例化对象）              ->       完成工厂建设完成并对外宣布可正式提供产品 

确认这个地方是不是春天真的来了(准备环境)-> 准备工厂图纸建设空工厂 -> 找水源（寻找class对象） -> 取水工具取水  -> 填充工厂 -> 调试工程（准备工厂环境） -> 专家提出修改意见（制定工厂后置处理器）  ->  执行修改意见（执行工厂后置处理器）-> 定义产品包装方案 （定义Bean的后置处理器） -> 国际化扩张（国际化） -> 准备新闻发布会（定义事件） ->  通电运行（启动web容器） -> 邀请参会人员见证各个里程碑事件（定义监听器） -> 生产产品（实例化对象） -> 代理商加持（AOP） ->  完成工厂建设完成并对外宣布可正式提供产品 

为什么是两个线呢？其实你会发现第二条也就比第一条多了个代理商(AOP)。 因为AOP不是默认开启，需要手动开启。而且开启AOP后最终的对象也不是原来的的对象，而是代理对象。

这个很好理解，比如有些代理卖的不是原厂货而是莆田货。这里有个段子，警察问售价的人你怎么区分那个是真货那个是假货啊？用几天就坏的是真货。能用很长时间的是假货。

关于事件的定义和发布已经监听并不涉及到bean的流程创建所以上面可以精简为：

准备环境-> 建设空工厂 -> 寻找class对象 -> 获取对象并填充工厂 -> 准备工厂环境 -> 制定工厂后置处理器 ->  执行工厂后置处理器-> 定义Bean的后置处理器 -> 实例化对象 -> |AOP| ->  完成

这里不罗嗦 一切的起因来自于AbstractApplicationContext.refresh(), 我们就从这里说起。

#### 准备环境 prepareRefresh();

准备环境：获取环境变量、工程类型等

####  创建工厂并且完成找水和装水obtainFreshBeanFactory()

|水源| 用例 | 找水工具| 别名|
|:---:|:---:|:---: |:---:  |
|雨水(xml里定义的) | 古老的业务Bean 现在基本很少使用| XmlBeanDefinitionReader| |
|雪水 (@component注解修饰的)| 包含@Service、@Controller、Repository 的业务Bean|| |
|海水 (@Bean修饰的)| 被@Configuration修饰的配置类| | 海的盐 |
|泉水 (ImportBeanDefinitionRegistrar注册)| mybatis、aop、fegin等配置| 通过AnnotationAttributes直接扫描包 | 冰泉 |
|溪水 (实现FactoryBean方法)| |  | |
|河水 (properties 文件里)| | PropertiesBeanDefinitionReader| 有点甜 |
|湖水 (json 文件里)| | JsonBeanDefinitionReader | |


1. 准备工厂图纸：创建一个空的工厂 new DefaultListableBeanFactory(getInternalParentBeanFactory());
2. 找水源：通BeanDefinitionReader（这里是抽象具体需要各自的实现类）（解析xml、扫描class文件等）获取class对象
3. 取水： 或者是说装水是通过BeanDefinitionRegistry把class对象信息的包装对象BeanDefinition注册到DefaultListableBeanFactory里

找水和取水的代码在 AbstractBeanDefinitionReader的loadBeanDefinitions方法里

```java
		else {
			// Can only load single resources by absolute URL.
            // 获取资源 及 找水
			Resource resource = resourceLoader.getResource(location);
            // 加载资源 及 装水
			int count = loadBeanDefinitions(resource);
			if (actualResources != null) {
				actualResources.add(resource);
			}
			if (logger.isTraceEnabled()) {
				logger.trace("Loaded " + count + " bean definitions from location [" + location + "]");
			}
			return count;
		}
```

至此我们的水工厂()就已经彻底建设完成,而且里面的各个生产线也已经建设完成（能产生什么Bean都已经定义）。
当然如果你不满意水源的名字你个给这个生产线起个别名; 比如 “泉水”改为“冰泉”是不是就高大上了。

    这里说一个小技巧：如果方法名是以do开头的，都是真正干活的关键方法。一定要看。比如 “doLoadBeanDefinitions”，“doRegisterBeanDefinitions”，“doGetBean”
    
####### BeanDefinition 都有什么信息

写几个主要信息

```
public interface BeanDefinition extends AttributeAccessor, BeanMetadataElement {

   // 我们可以看到，默认只提供 sington 和 prototype 两种，
   // 很多读者可能知道还有 request, session, globalSession, application, websocket 这几种，
   // 不过，它们属于基于 web 的扩展。
   String SCOPE_SINGLETON = ConfigurableBeanFactory.SCOPE_SINGLETON;
   String SCOPE_PROTOTYPE = ConfigurableBeanFactory.SCOPE_PROTOTYPE;

   // 设置父 Bean，这里涉及到 bean 继承，不是 java 继承。请参见附录的详细介绍
   // 一句话就是：继承父 Bean 的配置信息而已
   void setParentName(String parentName);
   // 获取父 Bean
   String getParentName();
   // 设置 Bean 的类名称，将来是要通过反射来生成实例的
   void setBeanClassName(String beanClassName);
   // 获取 Bean 的类名称
   String getBeanClassName();
   // 设置 bean 的 scope
   void setScope(String scope);
   String getScope();
   // 设置是否懒加载
   void setLazyInit(boolean lazyInit);
   boolean isLazyInit();
   // 设置该 Bean 依赖的所有的 Bean，注意，这里的依赖不是指属性依赖(如 @Autowire 标记的)，
   // 是 depends-on="" 属性设置的值。
   void setDependsOn(String... dependsOn);
   // 返回该 Bean 的所有依赖
   String[] getDependsOn();
   // 设置该 Bean 是否可以注入到其他 Bean 中，只对根据类型注入有效，
   // 如果根据名称注入，即使这边设置了 false，也是可以的
   void setAutowireCandidate(boolean autowireCandidate);
   // 该 Bean 是否可以注入到其他 Bean 中
   boolean isAutowireCandidate();
   // 主要的。同一接口的多个实现，如果不指定名字的话，Spring 会优先选择设置 primary 为 true 的 bean
   void setPrimary(boolean primary);
   // 是否是 primary 的
   boolean isPrimary();
   // 如果该 Bean 采用工厂方法生成，指定工厂名称。对工厂不熟悉的读者，请参加附录
   // 一句话就是：有些实例不是用反射生成的，而是用工厂模式生成的
   void setFactoryBeanName(String factoryBeanName);
   // 获取工厂名称
   String getFactoryBeanName();
   // 指定工厂类中的 工厂方法名称
   void setFactoryMethodName(String factoryMethodName);
   // 获取工厂类中的 工厂方法名称
   String getFactoryMethodName();
   // 构造器参数
   ConstructorArgumentValues getConstructorArgumentValues();
   // Bean 中的属性值，后面给 bean 注入属性值的时候会说到
   MutablePropertyValues getPropertyValues();
   // 是否 singleton
   boolean isSingleton();
   // 是否 prototype
   boolean isPrototype();
   // 如果这个 Bean 是被设置为 abstract，那么不能实例化，
   // 常用于作为 父bean 用于继承，其实也很少用......
   boolean isAbstract();
```
 
####  调试工程 prepareBeanFactory

准别工厂的基础环境可以理解为通电、通气、通交通（水工厂就不写通水了） 
 
####  提出修改意见 postProcessBeanFactory

这个是个扩展方法，因为spring是面向扩展的。所以这个可以留给子类实现。

Spring之所以强大，为世人所推崇，除了它功能上为大家提供了便利外，还有一方面是它的完美架构，开放式的架构让使用它的程序员很容易根据业务需要扩展已经存在的功能。
这种开放式 的设计在Spring中随处可见，例如在本例中就提供了一个空的函数实现postProcessBeanFactory来 方便程序猿在业务上做进一步扩展 

###### 使用方式
比如我有俩个个类
``` java
@Component
public class UserService {
    // 普通user类
}

@Component
public class UserExtService {
    //扩展User类
}
```
如果我创建一个类进行如下操作

```
@Component
public class UserServiceBeanFactoryPostProcessor implements BeanFactoryPostProcessor {

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {

        BeanDefinition userServiceBeanDefinition = beanFactory.getBeanDefinition("userService");

        userServiceBeanDefinition.setBeanClassName("userExtService");

    }
}
```

那么如下代码中context.getBean("userService");或获取什么实例

```
@SpringBootApplication
public class Application {

    public static void main(String[] args) {

         ConfigurableApplicationContext context= new SpringApplicationBuilder(Application.class)
                        .run(args);
         
         context.getBean("userService");
    }
}
```

答案是**userExtService**。

这就是 BeanFactoryPostProcessor的作用。我们可以从加载完成的beanFactory中获取并修改已有的BeanDefinition信息

那么就有人会提出。既然这里我们可以操作beanFactory中BeanDefinition信息，是不是就可以在这里进行新的BeanDefinition信息的注册（载入）呢？

比如现在有个排污水是不是可以在这里偷偷放到beanFactory中

|水源| 用例 | 找水工具| 别名|
|:---:|:---:|:---: |:---:|
|排污水 | | | |

**答案是不能**

因为BeanFactoryPostProcessor作为beanFactory后置处理器。它的执行时机是在beanFactory已经组装完成。里面有什么都已经确定了。所以不能添加但是可以修改和删除。

顺便提一下**BeanDefinitionRegistryPostProcessor**这个类

前面已经总结出BeanFactoryPostProcessor接口是Spring初始化BeanFactory时对外暴露的扩展点，SpringIoC容器允许BeanFactoryPostProcessor在容器实例化任何bean之前读取bean的定义，并可以修改它。

BeanDefinitionRegistryPostProcessor继承自 BeanFactoryPostProcessor，比BeanFactoryPostProcessor具有更高的优先级，主要用来在常规的BeanFactoryPostProcessor检测开始之前注册其他bean定义。
特别是，你可以通过BeanDefinitionRegistryPostProcessor来注册一些常规的BeanFactoryPostProcessor，因为此时所有常规的BeanFactoryPostProcessor都还没开始被处理。 

    注：这边的 “常规 BeanFactoryPostProcessor” 主要用来跟BeanDefinitionRegistryPostProcessor区分。

#### 执行修改意见 invokeBeanFactoryPostProcessors
 
有一个疑问 上面都已经注册了问什么不直接执行要单独拿出来执行呢？
 
其实你想一下，现实中有很多专家，每个专家提的意见可能都不一样。 甚至可以不着专家评审提意见。这是不是就是上面说的面向扩展。

看看invokeBeanFactoryPostProcessors的注释和postProcessBeanFactory的注释
* postProcessBeanFactory： 标准初始化后，修改应用程序上下文的内部bean工厂。所有bean定义都将被加载，但是尚未实例化任何bean。这允许在某些ApplicationContext实现中注册特殊的BeanPostProcessor等。
* invokeBeanFactoryPostProcessors： 实例化并调用所有注册BeanFactoryPostProcessor的Bean，并遵循显式顺序（如果给定的话）。必须在单例实例化之前调用
 
我们在obtainFreshBeanFactory介绍中看到的的词是 **“加载”**、**“装载”**、**“beanFactory”**。这里出现了新词 **“ApplicationContext”** 和 **“注册”** 以及 **“实例化”**。

先说说beanFactory和ApplicationContext的区别吧
* beanFactory：是Spring里面最低层、最核心的接口，提供了最简单的容器的功能，只提供了实例化对象和拿对象的功能；BeanFactory在启动的时候不会去实例化Bean，只有从容器中拿Bean的时候才会去实例化；
* ApplicationContext：应用上下文，继承BeanFactory接口、建立在BeanFactory基础之上，它是Spring更高级的容器，提供了更多的有用的功能；
   ApplicationContext在启动的时候就把所有的Bean全部实例化了。它还可以为Bean配置lazy-init=true来让Bean延迟实例化； 

这里举一个例子就是spring整合mybatis的配置类 **MapperScannerConfigurer**

#### 定时产品包装 registerBeanPostProcessors

注册产品后置处理器，这是只是注册并没有真正执行。

#### 国际化 initMessageSource

就是之前的in18

#### 准备新闻发布会 initApplicationEventMulticaster 

事件发布不涉及到对象的管理

####  onRefresh

对外预留扩展。web容器就是在这里初始化的。

#### 邀请参会人员见证 registerListeners

事件监听

####  生产产品 finishBeanFactoryInitialization

在这里真正完成对象的实例化.

有一个关键点 AbstractAutowireCapableBeanFactory.resolveBeforeInstantiation(String beanName, RootBeanDefinition mbd)
应用实例化之前的后处理器，以解决指定bean是否存在实例化之前的快捷方式。
```java
	@Nullable
	protected Object resolveBeforeInstantiation(String beanName, RootBeanDefinition mbd) {
		Object bean = null;
		if (!Boolean.FALSE.equals(mbd.beforeInstantiationResolved)) {
			// Make sure bean class is actually resolved at this point.
			if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
				Class<?> targetType = determineTargetType(beanName, mbd);
				if (targetType != null) {
					bean = applyBeanPostProcessorsBeforeInstantiation(targetType, beanName);
					if (bean != null) {
						bean = applyBeanPostProcessorsAfterInitialization(bean, beanName);
					}
				}
			}
			mbd.beforeInstantiationResolved = (bean != null);
		}
		return bean;
	}
```

* applyBeanPostProcessorsBeforeInstantiation: 将InstantiationAwareBeanPostProcessors应用于指定的bean定义（按类和名称），调用其postProcessBeforeInstantiation方法。任何返回的对象都将用作bean，而不是实际实例化目标bean。 后处理器返回的空值将导致目标Bean被实例化。
* applyBeanPostProcessorsAfterInitialization: 从接口AutowireCapableBeanFactory复制的描述,将BeanPostProcessors应用于给定的现有bean实例，调用其postProcessAfterInitialization方法。 返回的Bean实例可能是原始实例的包装。

如果上面创建的对象是空的话就进入了AbstractAutowireCapableBeanFactory.doCreateBean,之前提过这是一个真正干活的方法。

继续深入进入initializeBean方法

``` java
	protected Object initializeBean(String beanName, Object bean, @Nullable RootBeanDefinition mbd) {
		if (System.getSecurityManager() != null) {
			AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
				invokeAwareMethods(beanName, bean);
				return null;
			}, getAccessControlContext());
		}
		else {
			invokeAwareMethods(beanName, bean);
		}

		Object wrappedBean = bean;
		if (mbd == null || !mbd.isSynthetic()) {
            // 好熟悉啊
			wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
		}

		try {
             //关键的实现
			invokeInitMethods(beanName, wrappedBean, mbd);
		}
		catch (Throwable ex) {
			throw new BeanCreationException(
					(mbd != null ? mbd.getResourceDescription() : null),
					beanName, "Invocation of init method failed", ex);
		}
		if (mbd == null || !mbd.isSynthetic()) {
              // 又好熟悉啊
			wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
		}

		return wrappedBean;
	}
```

深入到invokeCustomInitMethod方法

```` java
if (System.getSecurityManager() != null) {
			AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
               //反射
				ReflectionUtils.makeAccessible(methodToInvoke);
				return null;
			});
			try {
				AccessController.doPrivileged((PrivilegedExceptionAction<Object>)
						() -> methodToInvoke.invoke(bean), getAccessControlContext());
			}
			catch (PrivilegedActionException pae) {
				InvocationTargetException ex = (InvocationTargetException) pae.getException();
				throw ex.getTargetException();
			}
		}
		else {
			try {
               //反射
				ReflectionUtils.makeAccessible(methodToInvoke);
				methodToInvoke.invoke(bean);
			}
			catch (InvocationTargetException ex) {
				throw ex.getTargetException();
			}
		}
````

对象就是通过**ReflectionUtils**反射进行完成的

#### 完成工厂建设完成并对外宣布可正式提供产品 finishRefresh

完成此上下文的刷新，调用LifecycleProcessor的onRefresh（）方法并发布。


## 总结

这里只是大概说了下bean的加载顺序，先理清思路。后面进行代码的逐行解读。