# BeanFactory和FactoryBean区别

## BeanFactory和FactoryBean概念

BeanFactory和FactoryBean在Spring中是两个使用频率很高的类，它们在拼写上非常相似，

需要注意的是，两者除了名字看上去像一点外，从实质上来说是一个没有多大关系的东西。

* BeanFactory是一个IOC容器或Bean对象工厂；
* FactoryBean是一个Bean；

在Spring中有两种Bean，一种是普通Bean，另一种就是像FactoryBean这样的工厂Bean，无论是那种Bean，都是由IOC容器来管理的。

FactoryBean可以说为IOC容器中Bean的实现提供了更加灵活的方式，FactoryBean在IOC容器的基础上给Bean的实现

加上了一个简单工厂模式和装饰模式，我们可以在getObject()方法中灵活配置。

## BeanFactory和FactoryBean深入源码

#### BeanFactory

BeanFactory是IOC最基本的容器，负责生产和管理bean，它为其他具体的IOC容器提供了最基本的规范，

例如DefaultListableBeanFactory，XmlBeanFactory，ApplicationContext 等具体的容器都是实现了BeanFactory，

#### FactoryBean

FactoryBean是一个接口，当在IOC容器中的Bean实现了FactoryBean后，通过getBean(String BeanName)获取

到的Bean对象并不是FactoryBean的实现类对象，而是这个实现类中的getObject()方法返回的对象。

要想获取FactoryBean的实现类，就要getBean(&BeanName)，在BeanName之前加上&。

``` java
package org.springframework.beans.factory;
public interface FactoryBean<T> {
	// 返回由FactoryBean创建的Bean的实例
	T getObject() throws Exception;
	// 返回FactoryBean创建的Bean的类型
	Class<?> getObjectType();
	// 确定由FactoryBean创建的Bean的作用域是singleton还是prototype
	boolean isSingleton();
}
```

## 实例分析

AppleBean
```java
public class AppleBean {
 
}
```

```java

@Component
public class AppleFactoryBean implements FactoryBean{
 
    @Override
    public Object getObject() throws Exception {
        return new AppleBean();
    }
 
    @Override
    public Class<?> getObjectType() {
        return AppleBean.class;
    }
 
    @Override
    public boolean isSingleton() {
        return false;
    }
}
```

```java
@Configuration
@ComponentScan
public class AppConfiguration {
 
}
```

```java

public class StartTest {
    public static void main(String[] args){
        ApplicationContext context = new AnnotationConfigApplicationContext(AppConfiguration.class);
        // 得到的是apple
        System.out.println(context.getBean("appleFactoryBean"));
        // 得到的是apple工厂
        System.out.println(context.getBean("&appleFactoryBean"));
    }

```

> com.jpeony.spring.bean.AppleBean@679b62af
>
> com.jpeony.spring.bean.AppleFactoryBean@5cdd8682

从结果可以看出第一个打印出来的是在getObject()中new的AppleBean对象，是一个普通的Bean，

第二个通过加上&获取的是实现了FactoryBean接口的AppleFactoryBean对象，是一个工厂Bean。

## 实现源码分析

前面基本使用方式已经知道了，再来看看Spring如何实现的。在使用getBean()的时候可以找到最终调用的是AbstractBeanFactory.doGetBean()

```java
    protected <T> T doGetBean(
            final String name, final Class<T> requiredType, final Object[] args, boolean typeCheckOnly)
            throws BeansException {
        //1.如果是FactoryBean这种Bean都是以&开头。所以需要去掉&
        //2.如果name的别名，则需要在SimpleAliasRegistry里面进行判断获取的真正的那么
        final String beanName = transformedBeanName(name);
        Object bean;

        // Eagerly check singleton cache for manually registered singletons.
        //从缓存中获取对象，避免重复创建
        Object sharedInstance = getSingleton(beanName);
        System.out.println(sharedInstance);
        if (sharedInstance != null && args == null) {
            if (logger.isDebugEnabled()) {
                if (isSingletonCurrentlyInCreation(beanName)) {
                    logger.debug("Returning eagerly cached instance of singleton bean '" + beanName +
                            "' that is not fully initialized yet - a consequence of a circular reference");
                } else {
                    logger.debug("Returning cached instance of singleton bean '" + beanName + "'");
                }
            }
            /*这里 的 getObjectForBeanInstance 完成 的 是 FactoryBean 的 相关 处理，
            以 取得 FactoryBean 的 生产 结果, BeanFactory 和 FactoryBean 的 区别 已经 在前面 讲过， 这个 过程 在后面 还会 详细 地 分析*/
            bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
        } else {
            // Fail if we're already creating this bean instance:
            // We're assumably within a circular reference.
            if (isPrototypeCurrentlyInCreation(beanName)) {
                throw new BeanCurrentlyInCreationException(beanName);
            }

            // Check if bean definition exists in this factory.
            /*
            这里 对 IoC 容器 中的 BeanDefintion 是否 存在 进行检查，
            检查 是否 能在 当前 的 BeanFactory 中 取得 需要 的 Bean。
            如果 在 当前 的 工厂 中 取 不到， 则 到 双亲 BeanFactory 中 去取；
            如果 当前 的 双亲 工厂 取 不到， 那就 顺着 双亲 BeanFactory 链 一直 向上 查找*/
            BeanFactory parentBeanFactory = getParentBeanFactory();
            if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
                // Not found -> check parent.
                String nameToLookup = originalBeanName(name);
                if (args != null) {
                    // Delegation to parent with explicit args.
                    return (T) parentBeanFactory.getBean(nameToLookup, args);
                } else {
                    // No args -> delegate to standard getBean method.
                    return parentBeanFactory.getBean(nameToLookup, requiredType);
                }
            }

            if (!typeCheckOnly) {
                markBeanAsCreated(beanName);
            }

            try {
                //通过beanName获得BeanDefinition对象  //这里 根据 Bean 的 名字 取得 BeanDefinition
                final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
                checkMergedBeanDefinition(mbd, beanName, args);

                // Guarantee initialization of beans that the current bean depends on.
                //检查bean配置是否设置了depend-on属性。即实例A需要先实例B
                //获取 当前 Bean 的 所有 依赖 Bean， 这样 会 触发 getBean 的 递归 调用， 直到 取 到 一个 没有
                // 任何 依赖 的 Bean 为止
                String[] dependsOn = mbd.getDependsOn();
                if (dependsOn != null) {
                    for (String dep : dependsOn) {
                        if (isDependent(beanName, dep)) {
                            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                    "Circular depends-on relationship between '" + beanName + "' and '" + dep + "'");
                        }
                        registerDependentBean(dep, beanName);
                        try {
                            //Bean依赖别的bean，直接递归getBean即可
                            getBean(dep);
                        } catch (NoSuchBeanDefinitionException ex) {
                            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                    "'" + beanName + "' depends on missing bean '" + dep + "'", ex);
                        }
                    }
                }
                /*这里 通过 调用 createBean 方法 创建 Singleton bean 的 实例， 这里 有一个 回 调 函数 getObject，
                会在 getSingleton 中 调用 ObjectFactory 的 createBean*/

                // Create bean instance.
                if (mbd.isSingleton()) {
                    sharedInstance = getSingleton(beanName, new ObjectFactory<Object>() {
                        @Override
                        public Object getObject() throws BeansException {
                            try {
                                return createBean(beanName, mbd, args);
                            } catch (BeansException ex) {
                                // Explicitly remove instance from singleton cache: It might have been put there
                                // eagerly by the creation process, to allow for circular reference resolution.
                                // Also remove any beans that received a temporary reference to the bean.
                                destroySingleton(beanName);
                                throw ex;
                            }
                        }
                    });
                    bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
                } else if (mbd.isPrototype()) {
                    // It's a prototype -> create a new instance.
                    Object prototypeInstance = null;
                    try {
                        beforePrototypeCreation(beanName);
                        prototypeInstance = createBean(beanName, mbd, args);
                    } finally {
                        afterPrototypeCreation(beanName);
                    }
                    bean = getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
                } else {
                    String scopeName = mbd.getScope();
                    final Scope scope = this.scopes.get(scopeName);
                    if (scope == null) {
                        throw new IllegalStateException("No Scope registered for scope name '" + scopeName + "'");
                    }
                    try {
                        Object scopedInstance = scope.get(beanName, new ObjectFactory<Object>() {
                            @Override
                            public Object getObject() throws BeansException {
                                beforePrototypeCreation(beanName);
                                try {
                                    return createBean(beanName, mbd, args);
                                } finally {
                                    afterPrototypeCreation(beanName);
                                }
                            }
                        });
                        bean = getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
                    } catch (IllegalStateException ex) {
                        throw new BeanCreationException(beanName,
                                "Scope '" + scopeName + "' is not active for the current thread; consider " +
                                        "defining a scoped proxy for this bean if you intend to refer to it from a singleton",
                                ex);
                    }
                }
            } catch (BeansException ex) {
                cleanupAfterBeanCreationFailure(beanName);
                throw ex;
            }
        }

        // Check if required type matches the type of the actual bean instance.
        // 这里 对 创建 的 Bean 进行 类型 检查， 如果 没有 问题， 就 返回 这个 新 创建 的 Bean， 这个 Bean 已经 //是 包含 了 依赖 关系 的 Bean
        if (requiredType != null && bean != null && !requiredType.isInstance(bean)) {
            try {
                return getTypeConverter().convertIfNecessary(bean, requiredType);
            } catch (TypeMismatchException ex) {
                if (logger.isDebugEnabled()) {
                    logger.debug("Failed to convert bean '" + name + "' to required type '" +
                            ClassUtils.getQualifiedName(requiredType) + "'", ex);
                }
                throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
            }
        }
        return (T) bean;
    }
```

通过上面的源码可以看到先通过IOC的 createBean(beanName, mbd, args);最后都会走bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);这个方法就是FactoryBean调用getObject()方法的地方。看一下源码


```java
    protected Object getObjectForBeanInstance(
            Object beanInstance, String name, String beanName, RootBeanDefinition mbd) {

        // Don't let calling code try to dereference the factory if the bean isn't a factory.
        if (BeanFactoryUtils.isFactoryDereference(name) && !(beanInstance instanceof FactoryBean)) {
            throw new BeanIsNotAFactoryException(transformedBeanName(name), beanInstance.getClass());
        }

        // Now we have the bean instance, which may be a normal bean or a FactoryBean.
        // If it's a FactoryBean, we use it to create a bean instance, unless the
        // caller actually wants a reference to the factory.
        if (!(beanInstance instanceof FactoryBean) || BeanFactoryUtils.isFactoryDereference(name)) {
            return beanInstance;
        }

        Object object = null;
        if (mbd == null) {
            object = getCachedObjectForFactoryBean(beanName);
        }
        if (object == null) {
            // Return bean instance from factory.
            FactoryBean<?> factory = (FactoryBean<?>) beanInstance;
            // Caches object obtained from FactoryBean if it is a singleton.
            if (mbd == null && containsBeanDefinition(beanName)) {
                mbd = getMergedLocalBeanDefinition(beanName);
            }
            boolean synthetic = (mbd != null && mbd.isSynthetic());
            object = getObjectFromFactoryBean(factory, beanName, !synthetic);
        }
        return object;
    }

    
```
分析一下上面的源码。首先判断当前获得的Bean是否是FactoryBean如果不是直接返回，如果是FactoryBean那么从缓存中获得，如果缓存中没有则创建也就是最后object = getObjectFromFactoryBean(factory, beanName, !synthetic);


```java
    protected Object getObjectFromFactoryBean(FactoryBean<?> factory, String beanName, boolean shouldPostProcess) {
        if (factory.isSingleton() && containsSingleton(beanName)) {
            synchronized (getSingletonMutex()) {
                Object object = this.factoryBeanObjectCache.get(beanName);
                if (object == null) {
                    object = doGetObjectFromFactoryBean(factory, beanName);
                    // Only post-process and store if not put there already during getObject() call above
                    // (e.g. because of circular reference processing triggered by custom getBean calls)
                    Object alreadyThere = this.factoryBeanObjectCache.get(beanName);
                    if (alreadyThere != null) {
                        object = alreadyThere;
                    }
                    else {
                        if (object != null && shouldPostProcess) {
                            if (isSingletonCurrentlyInCreation(beanName)) {
                                // Temporarily return non-post-processed object, not storing it yet..
                                return object;
                            }
                            beforeSingletonCreation(beanName);
                            try {
                                object = postProcessObjectFromFactoryBean(object, beanName);
                            }
                            catch (Throwable ex) {
                                throw new BeanCreationException(beanName,
                                        "Post-processing of FactoryBean's singleton object failed", ex);
                            }
                            finally {
                                afterSingletonCreation(beanName);
                            }
                        }
                        if (containsSingleton(beanName)) {
                            this.factoryBeanObjectCache.put(beanName, (object != null ? object : NULL_OBJECT));
                        }
                    }
                }
                return (object != NULL_OBJECT ? object : null);
            }
        }
        else {
            Object object = doGetObjectFromFactoryBean(factory, beanName);
            if (object != null && shouldPostProcess) {
                try {
                    object = postProcessObjectFromFactoryBean(object, beanName);
                }
                catch (Throwable ex) {
                    throw new BeanCreationException(beanName, "Post-processing of FactoryBean's object failed", ex);
                }
            }
            return object;
        }
    }
```
上面的源码会做一些前置后置处理。主要创建Object的方法是object = doGetObjectFromFactoryBean(factory, beanName);
```java
    private Object doGetObjectFromFactoryBean(final FactoryBean<?> factory, final String beanName)
            throws BeanCreationException {

        Object object;
        try {
            if (System.getSecurityManager() != null) {
                AccessControlContext acc = getAccessControlContext();
                try {
                    object = AccessController.doPrivileged(new PrivilegedExceptionAction<Object>() {
                        @Override
                        public Object run() throws Exception {
                                return factory.getObject();
                            }
                        }, acc);
                }
                catch (PrivilegedActionException pae) {
                    throw pae.getException();
                }
            }
            else {
                object = factory.getObject();
            }
        }
        catch (FactoryBeanNotInitializedException ex) {
            throw new BeanCurrentlyInCreationException(beanName, ex.toString());
        }
        catch (Throwable ex) {
            throw new BeanCreationException(beanName, "FactoryBean threw exception on object creation", ex);
        }

        // Do not accept a null value for a FactoryBean that's not fully
        // initialized yet: Many FactoryBeans just return null then.
        if (object == null && isSingletonCurrentlyInCreation(beanName)) {
            throw new BeanCurrentlyInCreationException(
                    beanName, "FactoryBean which is currently in creation returned null from getObject");
        }
        return object;
    }

```
看上面的源码object = factory.getObject();最终都是通过你自己写的FactoryBean里面的getObject()来返回你需要的对象
```java
```

## 总结

1. BeanFactory是一个IOC基础容器。
2. FactoryBean是一个Bean，不是一个普通Bean，是一个工厂Bean。
3. FactoryBean实现与工厂模式和装饰模式类似。
4. 通过转义符&来区分获取FactoryBean产生的对象和FactoryBean对象本身（FactoryBean实现类）
