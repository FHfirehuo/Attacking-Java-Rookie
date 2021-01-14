# AOP的原理

上文分析了AopProxy代理对象的创建过程，相当于为AOP运行做好了准备条件，这篇文章分析AOP如何运行的，

也就是如何通过拦截器调用运行AOP的。


## 设计原理

在Spring AOP通过JDK或CGLIB的方式生成代理对象的时候，相关的拦截器已经配置到代理对象中，拦截器在

代理对象中起作用是通过对这些方法的回调来完成的。

如果使用JDK动态代理来生成代理对象，通过InvocationHandler来设置拦截器回调；

如果使用CGLIB动态代理生成代理对象，通过DynamicAdvisedInterceptor来完成回调；

## JdkDynamicAopProxy的invoke拦截

 上一篇文章分析了Spring中通过ProxyFactoryBean生成AopProxy代理对象的过程，以及通过JDK和CGLIB

最终生成AopProxy代理对象的实现原理。回顾一下JDK生成AopProxy代理对象的最终代码位置：

```java
@Override
public Object getProxy(ClassLoader classLoader) {
   if (logger.isDebugEnabled()) {
      logger.debug("Creating JDK dynamic proxy: target source is " + this.advised.getTargetSource());
   }
   Class<?>[] proxiedInterfaces = AopProxyUtils.completeProxiedInterfaces(this.advised, true);
   findDefinedEqualsAndHashCodeMethods(proxiedInterfaces);
   return Proxy.newProxyInstance(classLoader, proxiedInterfaces, this);
}
```

Proxy.newProxyInstance(classLoader, proxiedInterfaces, this)，这里的this参数对应的是InvocationHandler对象，

InvocationHandler是JDK定义的反射类的一个接口，这个接口定义了invoke方法，而这个invoke方法时作为JDK Proxy

代理对象进行拦截的回调入口出现的。

JdkDynamicAopProxy实现了InvocationHandler接口源码：

```java
final class JdkDynamicAopProxy implements AopProxy, InvocationHandler, Serializable {
  // ...
}
```

JdkDynamicAopProxy实现了InvocationHandler接口，也就是说Proxy代理对象方法被调用时，

JdkDynamicAopProxy的invoke()方法作为Proxy对象的回调函数被触发，从而通过invoke()的具体实现来完成对

目标对象的拦截或者说功能增强的工作。

JdkDynamicAopProxy.invoke()方法源码：
```java
@Override
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
   MethodInvocation invocation;
   Object oldProxy = null;
   boolean setProxyContext = false;
 
   TargetSource targetSource = this.advised.targetSource;
   Class<?> targetClass = null;
   Object target = null;
 
   try {
      if (!this.equalsDefined && AopUtils.isEqualsMethod(method)) {
         // The target does not implement the equals(Object) method itself.
         // 如果目标对象没有实现Object类的基本方法: equals()
         return equals(args[0]);
      }
      else if (!this.hashCodeDefined && AopUtils.isHashCodeMethod(method)) {
         // The target does not implement the hashCode() method itself.
        // 如果目标对象没有实现Object类的基本方法: hashCode()
         return hashCode();
      }
      else if (method.getDeclaringClass() == DecoratingProxy.class) {
         // There is only getDecoratedClass() declared -> dispatch to proxy config.
         return AopProxyUtils.ultimateTargetClass(this.advised);
      }
      else if (!this.advised.opaque && method.getDeclaringClass().isInterface() &&
            method.getDeclaringClass().isAssignableFrom(Advised.class)) {
         // Service invocations on ProxyConfig with the proxy config...
         // 根据代理对象的配置来调用服务
         return AopUtils.invokeJoinpointUsingReflection(this.advised, method, args);
      }
 
      Object retVal;
 
      if (this.advised.exposeProxy) {
         // Make invocation available if necessary.
         oldProxy = AopContext.setCurrentProxy(proxy);
         setProxyContext = true;
      }
 
      // May be null. Get as late as possible to minimize the time we "own" the target,
      // in case it comes from a pool.
      // 获取目标对象
      target = targetSource.getTarget();
      if (target != null) {
         targetClass = target.getClass();
      }
 
      // Get the interception chain for this method.
      // 获取定义好的拦截器链
      List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, targetClass);
 
      // Check whether we have any advice. If we don't, we can fallback on direct
      // reflective invocation of the target, and avoid creating a MethodInvocation.
      // 如果没有设定拦截器，哪么就直接调用target的对应方法
      if (chain.isEmpty()) {
         // We can skip creating a MethodInvocation: just invoke the target directly
         // Note that the final invoker must be an InvokerInterceptor so we know it does
         // nothing but a reflective operation on the target, and no hot swapping or fancy proxying.
         Object[] argsToUse = AopProxyUtils.adaptArgumentsIfNecessary(method, args);
         retVal = AopUtils.invokeJoinpointUsingReflection(target, method, argsToUse);
      }
      else {
         // We need to create a method invocation...
         // 如果有拦截器的设定，那么需要调用拦截器之后才调用目标对象的对应方法
         // 通过构造一个ReflectiveMethodInvocation来实现，下面再看这个类的具体实现
         invocation = new ReflectiveMethodInvocation(proxy, target, method, args, targetClass, chain);
         // Proceed to the joinpoint through the interceptor chain.
         // 根据拦截器继续执行
         retVal = invocation.proceed();
      }
 
      // Massage return value if necessary.
      Class<?> returnType = method.getReturnType();
      if (retVal != null && retVal == target &&
            returnType != Object.class && returnType.isInstance(proxy) &&
            !RawTargetAccess.class.isAssignableFrom(method.getDeclaringClass())) {
         // Special case: it returned "this" and the return type of the method
         // is type-compatible. Note that we can't help if the target sets
         // a reference to itself in another returned object.
         retVal = proxy;
      }
      else if (retVal == null && returnType != Void.TYPE && returnType.isPrimitive()) {
         throw new AopInvocationException(
               "Null return value from advice does not match primitive return type for: " + method);
      }
      return retVal;
   }
   finally {
      if (target != null && !targetSource.isStatic()) {
         // Must have come from TargetSource.
         targetSource.releaseTarget(target);
      }
      if (setProxyContext) {
         // Restore old proxy.
         AopContext.setCurrentProxy(oldProxy);
      }
   }
}
```

## CglibAopProxy的intercept拦截

 在分析CglibAopProxy的AopProxy代理对象生成的时候，我们了解到对于AOP的拦截调用，其回调是在

DynamicAdvisedInterceptor对象中实现的，这个回调的实现在intercept()方法中。

DynamicAdvisedInterceptor.intercept()方法源码：

```java
@Override
public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) throws Throwable {
   Object oldProxy = null;
   boolean setProxyContext = false;
   Class<?> targetClass = null;
   Object target = null;
   try {
      if (this.advised.exposeProxy) {
         // Make invocation available if necessary.
         oldProxy = AopContext.setCurrentProxy(proxy);
         setProxyContext = true;
      }
      // May be null. Get as late as possible to minimize the time we
      // "own" the target, in case it comes from a pool...
      target = getTarget();
      if (target != null) {
         targetClass = target.getClass();
      }
      // 从advised中取得配置好的AOP通知链
      List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, targetClass);
      Object retVal;
      // Check whether we only have one InvokerInterceptor: that is,
      // no real advice, but just reflective invocation of the target.
      // 如果没有AOP通知配置，那么直接调用target对象方法
      if (chain.isEmpty() && Modifier.isPublic(method.getModifiers())) {
         // We can skip creating a MethodInvocation: just invoke the target directly.
         // Note that the final invoker must be an InvokerInterceptor, so we know
         // it does nothing but a reflective operation on the target, and no hot
         // swapping or fancy proxying.
         Object[] argsToUse = AopProxyUtils.adaptArgumentsIfNecessary(method, args);
         retVal = methodProxy.invoke(target, argsToUse);
      }
      else {
         // We need to create a method invocation...
         // 通过CglibMethodInvocation来启动Advice通知
         retVal = new CglibMethodInvocation(proxy, target, method, args, targetClass, chain, methodProxy).proceed();
      }
      retVal = processReturnType(proxy, target, method, retVal);
      return retVal;
   }
   finally {
      if (target != null) {
         releaseTarget(target);
      }
      if (setProxyContext) {
         // Restore old proxy.
         AopContext.setCurrentProxy(oldProxy);
      }
   }
}
```
实现过程与JdkDynamicAopProxy回调invoke()方法类似。
## 目标对象方法的调用

如果没有设置拦截器，那么会对目标对象的方法直接调用。对于JdkDynamicAopProxy代理对象，从源码可以看到

对目标对象的调用方法是通过AopUtils使用反射机制在AopUtils.invokeJoinpointUsingReflection方法中实现的。

在这个调用中，首先得到调用方法的反射对象，然后使用invoke()启动对方法反射对象的调用。

AopUtils.invokeJoinpointUsingReflection()方法源码：

```java
public static Object invokeJoinpointUsingReflection(Object target, Method method, Object[] args)
      throws Throwable {
 
   // Use reflection to invoke the method.
   // 使用反射调用目标对象的方法
   try {
      ReflectionUtils.makeAccessible(method);
      return method.invoke(target, args);
   }
   catch (InvocationTargetException ex) {
      // Invoked method threw a checked exception.
      // We must rethrow it. The client won't see the interceptor.
      throw ex.getTargetException();
   }
   catch (IllegalArgumentException ex) {
      throw new AopInvocationException("AOP configuration seems to be invalid: tried calling method [" +
            method + "] on target [" + target + "]", ex);
   }
   catch (IllegalAccessException ex) {
      throw new AopInvocationException("Could not access method [" + method + "]", ex);
   }
}
```
CglibAopProxy调用目标对象方法：
```java
Object[] argsToUse = AopProxyUtils.adaptArgumentsIfNecessary(method, args);
retVal = methodProxy.invoke(target, argsToUse);
```

```java
public Object invoke(Object obj, Object[] args) throws Throwable {
    try {
        this.init();
        MethodProxy.FastClassInfo fci = this.fastClassInfo;
        return fci.f1.invoke(fci.i1, obj, args);
    } catch (InvocationTargetException var4) {
        throw var4.getTargetException();
    } catch (IllegalArgumentException var5) {
        if (this.fastClassInfo.i1 < 0) {
            throw new IllegalArgumentException("Protected method: " + this.sig1);
        } else {
            throw var5;
        }
    }
}
```
对目标对象的调用，通过CGLIB的MethodProxy对象来直接完成的，这个对象的使用是由CGLIB的设计决定的。
## AOP拦截器链的调用

上面分析的是对目标对象的调用，下面分析如何对AOP实现目标增强调用。

由于JDK和CGLIB生成不同的AopProxy代理对象，从而构造了不同的回调方法来启动对拦截器链的调用。

但是他们对拦截器链的调用都是使用ReflectiveMethodInvocation.procced()方法来完成的，追踪源码很容易明白。

ReflectiveMethodInvocation.procced()方法源码：

```java
@Override
public Object proceed() throws Throwable {
   // We start with an index of -1 and increment early.
   /** 从索引为-1的拦截器开始调用，并按序递增，
     * 如果拦截器链中的拦截器迭代调用完毕，这里开始调用target函数，
     * invokeJoinpoint()方法签名：
     * protected Object invokeJoinpoint() throws Throwable {
     *   return AopUtils.invokeJoinpointUsingReflection(this.target, this.method, this.arguments);
     * }
     * 还是通过AopUtils.invokeJoinpointUsingReflection反射调用目标方法
     */
   if (this.currentInterceptorIndex == this.interceptorsAndDynamicMethodMatchers.size() - 1) {
      return invokeJoinpoint();
   }
   // 这里按interceptorOrInterceptionAdvice定义好的拦截器链进行调用
   Object interceptorOrInterceptionAdvice =
         this.interceptorsAndDynamicMethodMatchers.get(++this.currentInterceptorIndex);
   if (interceptorOrInterceptionAdvice instanceof InterceptorAndDynamicMethodMatcher) {
      // Evaluate dynamic method matcher here: static part will already have
      // been evaluated and found to match.
      // 这里对拦截器进行动态匹配判断，这里是触发匹配的地方，如果和定义的PointCut匹配，那么这个Advice被执行
      InterceptorAndDynamicMethodMatcher dm =
            (InterceptorAndDynamicMethodMatcher) interceptorOrInterceptionAdvice;
      if (dm.methodMatcher.matches(this.method, this.targetClass, this.arguments)) {
         return dm.interceptor.invoke(this);
      }
      else {
         // Dynamic matching failed.
         // Skip this interceptor and invoke the next in the chain.
         // 如果不匹配，递归调用proceed()方法，直到所有的拦截器都被运行过为止。
         // 上面代码invokeJoinpoint的if条件上对拦截器执行做了判断，如果拦截器都执行完，就执行目标方法
         return proceed();
      }
   }
   else {
      // It's an interceptor, so we just invoke it: The pointcut will have
      // been evaluated statically before this object was constructed.
      // 如果是interceptor直接调用interceptor的方法
      return ((MethodInterceptor) interceptorOrInterceptionAdvice).invoke(this);
   }
}
```

以上就是整个拦截器和target目标对象被调用的过程。

## 配置通知器

在整个AopProxy拦截器调用的过程中，我们先回到ReflectiveMethodInvocation.procceed()方法中，

源码见上面代码。我们看下如下代码：


```java
Object interceptorOrInterceptionAdvice =
         this.interceptorsAndDynamicMethodMatchers.get(++this.currentInterceptorIndex);
```
这个interceptorOrInterceptionAdvice是获得的拦截器，它通过拦截器机制对目标对象进行增强。这个拦截来自于

interceptorsAndDynamicMethodMatchers集合中的一个元素：
```java
protected final List<?> interceptorsAndDynamicMethodMatchers;
```
这个List中的拦截器是怎么生成的？

先看回放下JdkDynamicAopProxy中的invoke()方法中的代码片段：
```java
List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, targetClass);
```
取得拦截器链是由advised对象完成的，也即private final AdvisedSupport advised;

AdvisedSupport.getInterceptorsAndDynamicInterceptionAdvice()方法源码：

```java
public List<Object> getInterceptorsAndDynamicInterceptionAdvice(Method method, Class<?> targetClass) {
   // 使用了cache，通过cache获取获取interceptor链，如果没有就是生成，否则直接返回拦截器
   MethodCacheKey cacheKey = new MethodCacheKey(method);
   List<Object> cached = this.methodCache.get(cacheKey);
   if (cached == null) {
      // 这个interceptor由advisorChainFactory的getInterceptorsAndDynamicInterceptionAdvice()方法生成
      // AdvisorChainFactory advisorChainFactory = new DefaultAdvisorChainFactory();
      // 通过定义可以知道，使用DefaultAdvisorChainFactory
      cached = this.advisorChainFactory.getInterceptorsAndDynamicInterceptionAdvice(
            this, method, targetClass);
      this.methodCache.put(cacheKey, cached);
   }
   return cached;
}
```
这个方法中取得了拦截器链，为了提高效率，设置了缓存操作。

取得拦截器链的具体实现在DefaultAdvisorChainFactory.getInterceptorsAndDynamicInterceptionAdvice()方法中：
```java
@Override
public List<Object> getInterceptorsAndDynamicInterceptionAdvice(
      Advised config, Method method, Class<?> targetClass) {
 
   // This is somewhat tricky... We have to process introductions first,
   // but we need to preserve order in the ultimate list.
   // advisor链已经在config中持有，这里可以直接使用
   List<Object> interceptorList = new ArrayList<Object>(config.getAdvisors().length);
   Class<?> actualClass = (targetClass != null ? targetClass : method.getDeclaringClass());
   boolean hasIntroductions = hasMatchingIntroductions(config, actualClass);
   AdvisorAdapterRegistry registry = GlobalAdvisorAdapterRegistry.getInstance();
 
   for (Advisor advisor : config.getAdvisors()) {
      if (advisor instanceof PointcutAdvisor) {
         // Add it conditionally.
         PointcutAdvisor pointcutAdvisor = (PointcutAdvisor) advisor;
         if (config.isPreFiltered() || pointcutAdvisor.getPointcut().getClassFilter().matches(actualClass)) {
            // 拦截器链通过AdvisorAdapterRegistry加入的
            MethodInterceptor[] interceptors = registry.getInterceptors(advisor);
            MethodMatcher mm = pointcutAdvisor.getPointcut().getMethodMatcher();
            // 使用MethodMatchers.matches方法进行匹配判断
            if (MethodMatchers.matches(mm, method, actualClass, hasIntroductions)) {
               if (mm.isRuntime()) {
                  // Creating a new object instance in the getInterceptors() method
                  // isn't a problem as we normally cache created chains.
                  for (MethodInterceptor interceptor : interceptors) {
                     interceptorList.add(new InterceptorAndDynamicMethodMatcher(interceptor, mm));
                  }
               }
               else {
                  interceptorList.addAll(Arrays.asList(interceptors));
               }
            }
         }
      }
      else if (advisor instanceof IntroductionAdvisor) {
         IntroductionAdvisor ia = (IntroductionAdvisor) advisor;
         if (config.isPreFiltered() || ia.getClassFilter().matches(actualClass)) {
            Interceptor[] interceptors = registry.getInterceptors(advisor);
            interceptorList.addAll(Arrays.asList(interceptors));
         }
      }
      else {
         Interceptor[] interceptors = registry.getInterceptors(advisor);
         interceptorList.addAll(Arrays.asList(interceptors));
      }
   }
 
   return interceptorList;
}
```
判断Advisor是否符合配置要求：

```java
private static boolean hasMatchingIntroductions(Advised config, Class<?> actualClass) {
   for (int i = 0; i < config.getAdvisors().length; i++) {
      Advisor advisor = config.getAdvisors()[i];
      if (advisor instanceof IntroductionAdvisor) {
         IntroductionAdvisor ia = (IntroductionAdvisor) advisor;
         if (ia.getClassFilter().matches(actualClass)) {
            return true;
         }
      }
   }
   return false;
}
```
从源码可以看到，取得拦截器链的具体工作由DefaultAdvisorChainFactory来完成，源码逻辑：

1）首先设置一个List，长度由配置的通知器个数决定，这个配置就是XML中对ProxyFactoryBean做的InterceptNames。

2）然后通过AdvisorAdapterRegistry进行拦截器注册。

3）List中的拦截器在JDK的invoke()或CGLIB的intercept()方法中代理启动时完成切面增强。

在调用invoke()或intercept()方法中，在调用ReflectiveMethodInvocation的proceed()方法前，

通过构造器将生成的拦截器链chain作为创建ReflectiveMethodInvocation的参数，所以在procced()中

就可以直接使用拦截器链。

invocation = new ReflectiveMethodInvocation(proxy, target, method, args, targetClass, chain);

retVal = invocation.proceed();

## Advice通知的实现
 经过前面的分析，我们看到AopProxy代理对象的生成，拦截器链的建立，拦截器链的调用和最终目标方法

的实现原理。但是Spring AOP定义的通知是怎样实现目标对象的增强的？

在上面的DefaultAdvisorChainFactory.getInterceptorsAndDynamicInterceptionAdvice()方法中：

 
```java
@Override
public List<Object> getInterceptorsAndDynamicInterceptionAdvice(
      Advised config, Method method, Class<?> targetClass) {
 
   // This is somewhat tricky... We have to process introductions first,
   // but we need to preserve order in the ultimate list.
   // advisor链已经在config中持有，这里可以直接使用
   List<Object> interceptorList = new ArrayList<Object>(config.getAdvisors().length);
   Class<?> actualClass = (targetClass != null ? targetClass : method.getDeclaringClass());
   boolean hasIntroductions = hasMatchingIntroductions(config, actualClass);
   AdvisorAdapterRegistry registry = GlobalAdvisorAdapterRegistry.getInstance();
 
   for (Advisor advisor : config.getAdvisors()) {
      if (advisor instanceof PointcutAdvisor) {
         // Add it conditionally.
         PointcutAdvisor pointcutAdvisor = (PointcutAdvisor) advisor;
         if (config.isPreFiltered() || pointcutAdvisor.getPointcut().getClassFilter().matches(actualClass)) {
            // 拦截器链通过AdvisorAdapterRegistry加入的
            MethodInterceptor[] interceptors = registry.getInterceptors(advisor);
            MethodMatcher mm = pointcutAdvisor.getPointcut().getMethodMatcher();
            // 使用MethodMatchers.matches方法进行匹配判断
            if (MethodMatchers.matches(mm, method, actualClass, hasIntroductions)) {
               if (mm.isRuntime()) {
                  // Creating a new object instance in the getInterceptors() method
                  // isn't a problem as we normally cache created chains.
                  for (MethodInterceptor interceptor : interceptors) {
                     interceptorList.add(new InterceptorAndDynamicMethodMatcher(interceptor, mm));
                  }
               }
               else {
                  interceptorList.addAll(Arrays.asList(interceptors));
               }
            }
         }
      }
      else if (advisor instanceof IntroductionAdvisor) {
         IntroductionAdvisor ia = (IntroductionAdvisor) advisor;
         if (config.isPreFiltered() || ia.getClassFilter().matches(actualClass)) {
            Interceptor[] interceptors = registry.getInterceptors(advisor);
            interceptorList.addAll(Arrays.asList(interceptors));
         }
      }
      else {
         Interceptor[] interceptors = registry.getInterceptors(advisor);
         interceptorList.addAll(Arrays.asList(interceptors));
      }
   }
 
   return interceptorList;
}
```
在上面这段代码中，GlobalAdvisorAdapterRegistry中隐藏着不少AOP实现的重要细节，它的getInterceptors方法

为AOP实现做出了很大的贡献，就是这个方法封装着advice织入实现的入口。

先看下GlobalAdvisorAdapterRegistry的源码：
```java
package org.springframework.aop.framework.adapter;
 
public abstract class GlobalAdvisorAdapterRegistry {
 
   /**
    * Keep track of a single instance so we can return it to classes that request it.
    */
   private static AdvisorAdapterRegistry instance = new DefaultAdvisorAdapterRegistry();
 
   /**
    * Return the singleton {@link DefaultAdvisorAdapterRegistry} instance.
    */
   public static AdvisorAdapterRegistry getInstance() {
      return instance;
   }
 
   /**
    * Reset the singleton {@link DefaultAdvisorAdapterRegistry}, removing any
    * {@link AdvisorAdapterRegistry#registerAdvisorAdapter(AdvisorAdapter) registered}
    * adapters.
    */
   static void reset() {
      instance = new DefaultAdvisorAdapterRegistry();
   }
 
}
```
该类非常简洁，起到一个适配器的作用，同时，也是一个单例模式的应用，为Spring AOP模块提供了一个

DefaultAdvisorAdapterRegister单件，通过DefaultAdvisorAdapterRegister完成各种通知的适配和注册工作。

DefaultAdvisorAdapterRegister类的源码：


```java
package org.springframework.aop.framework.adapter;
 
import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
 
import org.aopalliance.aop.Advice;
import org.aopalliance.intercept.MethodInterceptor;
 
import org.springframework.aop.Advisor;
import org.springframework.aop.support.DefaultPointcutAdvisor;
 
@SuppressWarnings("serial")
public class DefaultAdvisorAdapterRegistry implements AdvisorAdapterRegistry, Serializable {
   // 持有一个AdvisorAdapter的List，这个List中的Adapter是与实现Spring AOP的advice增强功能相对应的
   private final List<AdvisorAdapter> adapters = new ArrayList<AdvisorAdapter>(3);
 
   /**
    * Create a new DefaultAdvisorAdapterRegistry, registering well-known adapters.
    * 把已有的advice实现的Adapter加入进来，主要有MethodBeforeAdvice、AfterReturningAdvice、
    * ThrowsAdvice这些AOP的advice封装实现
    */
   public DefaultAdvisorAdapterRegistry() {
      registerAdvisorAdapter(new MethodBeforeAdviceAdapter());
      registerAdvisorAdapter(new AfterReturningAdviceAdapter());
      registerAdvisorAdapter(new ThrowsAdviceAdapter());
   }
 
   @Override
   public Advisor wrap(Object adviceObject) throws UnknownAdviceTypeException {
      if (adviceObject instanceof Advisor) {
         return (Advisor) adviceObject;
      }
      if (!(adviceObject instanceof Advice)) {
         throw new UnknownAdviceTypeException(adviceObject);
      }
      Advice advice = (Advice) adviceObject;
      if (advice instanceof MethodInterceptor) {
         // So well-known it doesn't even need an adapter.
         return new DefaultPointcutAdvisor(advice);
      }
      for (AdvisorAdapter adapter : this.adapters) {
         // Check that it is supported.
         if (adapter.supportsAdvice(advice)) {
            return new DefaultPointcutAdvisor(advice);
         }
      }
      throw new UnknownAdviceTypeException(advice);
   }
 
   /**
     * 在DefaultAdvisorChainFactory中启动getInterceptors()方法
     */
   @Override
   public MethodInterceptor[] getInterceptors(Advisor advisor) throws UnknownAdviceTypeException {
      List<MethodInterceptor> interceptors = new ArrayList<MethodInterceptor>(3);
      // 从Advisor通知器配置中取得advice通知
      Advice advice = advisor.getAdvice();
      // 如果通知是MethodInterceptor类型的通知，直接加入interceptors中，无需适配
      if (advice instanceof MethodInterceptor) {
         interceptors.add((MethodInterceptor) advice);
      }
      // 对通知进行适配，使用已经配置好的Adapter:MethodBeforeAdviceAdapter、AfterReturningAdviceAdapter、
      // ThrowsAdviceAdapter，从配置好的Adapter中取出封装好AOP编织功能的
      for (AdvisorAdapter adapter : this.adapters) {
         if (adapter.supportsAdvice(advice)) {
            interceptors.add(adapter.getInterceptor(advisor));
         }
      }
      if (interceptors.isEmpty()) {
         throw new UnknownAdviceTypeException(advisor.getAdvice());
      }
      return interceptors.toArray(new MethodInterceptor[interceptors.size()]);
   }
 
   @Override
   public void registerAdvisorAdapter(AdvisorAdapter adapter) {
      this.adapters.add(adapter);
   }
 
}
```
在DefaultAdvisorAdapterRegistry源码中我们看到了一序列在AOP应用中与用到的Spring AOP的advice通知相对应

的adapter适配实现，并看到了对这些adapter的具体使用。具体来说，对它们的使用主要体现在以下两个方面：

1）调用adapter的supportsAdvice方法，通过这个方法判断advice类型注册不同的AdviceInterceptor。

2）在getInterceptors方法中实现代理对象的织入功能。

以MethodBeforeAdviceAdapter为了，源码如下：

```java
class MethodBeforeAdviceAdapter implements AdvisorAdapter, Serializable {
 
   @Override
   public boolean supportsAdvice(Advice advice) {
      return (advice instanceof MethodBeforeAdvice);
   }
 
   @Override
   public MethodInterceptor getInterceptor(Advisor advisor) {
      MethodBeforeAdvice advice = (MethodBeforeAdvice) advisor.getAdvice();
      return new MethodBeforeAdviceInterceptor(advice);
   }
 
}
```
源码并不复杂，supportAdvice方法对Advice类型进行判断；而getInterceptor把advice从通知器中取出，

然后创建一个MethodBeforAdviceInterceptor对象将advice包裹起来并返回。

    Spring AOP为了实现advice的织入，设计了特定的拦截器对这些功能进行了封装。虽然应用不会直接用

到这些拦截器，但却是advice发挥作用比不可少的准备。以MethodBeforAdviceInterceptor为例，看看它

是如何完成advice的封装的。

MethodBeforAdviceInterceptor源码：
```java
public class MethodBeforeAdviceInterceptor implements MethodInterceptor, Serializable {
 
   private MethodBeforeAdvice advice;
 
 
   /**
    * Create a new MethodBeforeAdviceInterceptor for the given advice.
    * @param advice the MethodBeforeAdvice to wrap
    */
   public MethodBeforeAdviceInterceptor(MethodBeforeAdvice advice) {
      Assert.notNull(advice, "Advice must not be null");
      this.advice = advice;
   }
 
   @Override
   public Object invoke(MethodInvocation mi) throws Throwable {
      this.advice.before(mi.getMethod(), mi.getArguments(), mi.getThis() );
      return mi.proceed();
   }
 
}
```

MethodBeforAdviceInterceptor完成的是对MethodBeforAdvice通知的封装，可以在invoke()回调方法中，

看到首先触发了advice的before回调，然后才是MethodInvocation的proceed方法调用，看到这里，就已经

和前面在ReflectiveMethodInvocation的proceed分析中联系起来了。在前面我们说过，在AopProxy代理

对象触发的ReflectiveMethodInvocation的proceed方法中，在取得拦截器以后，启动了对拦截器invoke方法

的调用。按照AOP的配置规则，ReflectiveMethodInvocation触发的拦截器invoke()方法中，最终会根据不同

的advice类型，触发Spring对不同的advice的拦截封装，比如对MethodBeforeAdvice，最终会触发

MethodBeforAdviceInterceptor的invoke方法在MethodBeforeAdviceInterceptor方法中，会先调用

advice的before方法，这就是MethodBeforeAdvice所需要的对目标对象的增强效果：在方法调用之前

完成通知增强。

如果了解了MethodBeforAdviceInterceptor的实现原理，其余类型的通知实现类似。
    
## ProxyFactory实现AOP

在前面的分析中，我们了解了以ProxyFactoryBean为例Spring AOP的实现线索。还可以使用ProxyFactory

来实现Spring AOP的功能，只是在使用ProxyFactory的时候，需要编程式地完成AOP应用的设置。

对于ProxyFactory实现AOP功能，其实现原理与ProxyFactoryBean的实现原理是一样的，只是在最外层的表现

形式上有所不同。

ProxyFactory源码：
```java
package org.springframework.aop.framework;
 
import org.aopalliance.intercept.Interceptor;
 
import org.springframework.aop.TargetSource;
import org.springframework.util.ClassUtils;
 
@SuppressWarnings("serial")
public class ProxyFactory extends ProxyCreatorSupport {
 
   public ProxyFactory() {
   }
   public ProxyFactory(Object target) {
      setTarget(target);
      setInterfaces(ClassUtils.getAllInterfaces(target));
   }
   public ProxyFactory(Class<?>... proxyInterfaces) {
      setInterfaces(proxyInterfaces);
   }
   public ProxyFactory(Class<?> proxyInterface, Interceptor interceptor) {
      addInterface(proxyInterface);
      addAdvice(interceptor);
   }
   public ProxyFactory(Class<?> proxyInterface, TargetSource targetSource) {
      addInterface(proxyInterface);
      setTargetSource(targetSource);
   }
   public Object getProxy() {
      return createAopProxy().getProxy();
   }
   public Object getProxy(ClassLoader classLoader) {
      return createAopProxy().getProxy(classLoader);
   }
   @SuppressWarnings("unchecked")
   public static <T> T getProxy(Class<T> proxyInterface, Interceptor interceptor) {
      return (T) new ProxyFactory(proxyInterface, interceptor).getProxy();
   }
   @SuppressWarnings("unchecked")
   public static <T> T getProxy(Class<T> proxyInterface, TargetSource targetSource) {
      return (T) new ProxyFactory(proxyInterface, targetSource).getProxy();
   }
   public static Object getProxy(TargetSource targetSource) {
      if (targetSource.getTargetClass() == null) {
         throw new IllegalArgumentException("Cannot create class proxy for TargetSource with null target class");
      }
      ProxyFactory proxyFactory = new ProxyFactory();
      proxyFactory.setTargetSource(targetSource);
      proxyFactory.setProxyTargetClass(true);
      return proxyFactory.getProxy();
   }
 
}
```

ProxyFactory没有使用FactoryBean的IOC封装，而是直接集成了ProxyCreatorSupport的功能来完成AOP的属性

```java

```

```java

```
