# Bean对象的创建

## Bean对象创建概要 

容器初始化的工作主要是在IOC容器中建立了BeanDefinition数据映射，并通过HashMap持有数据，BeanDefinition都在beanDefinitionMap里被检索和使用。
在IOC容器BeanFactory中，有一个getBean的接口定义，通过这个接口实现可以获取到Bean对象。但是，这个Bean对象并不是一个普通的Bean对象，它是一个处理完依赖关系后的Bean对象。
所以一个getBean()实现里面，分为两个大步骤来处理返回用户需要的Bean对象：

1. 根据BeanDefinition创建Bean对象，也即Bean对象的创建。
2. 创建出来的Bean是一个还没有建立依赖关系的Bean，所有需要完成依赖关系建立，叫做Bean依赖注入。

本文先分析如何根据BeanDefinition数据结构创建用户需要的Bean，并且搞清楚Bean的创建时机，因为有些人说Bean在第一次使用时进行创建的，有些人又说在IOC容器初始化的时候就给创建好了，然而并不都对。

Bean的创建时机分为两大类：

1. 非抽象，并且单例，并且非懒加载（Spring Bean默认单例Singleton，非懒加载）的对象是在IOC容器初始化时通过refresh()#finishBeanFactoryInitialization()完成创建的，创建完后放在本地缓存里面，用的时候直接取即可，这么做是因为在初始化的时候，可能就需要使用Bean，同时，可以提高使用时获取的效率；
初始化时创建的Bean放在Map里面，private final Map<String, Object> singletonObjects = new ConcurrentHashMap<String, Object>(256);使用时直接从Map缓存获取。
2. 而非单例或懒加载对象都是在第一次使用时，getBean()的时候创建的；如果想在使用时才进行初始化，可以设置@Scope("prototype")为原型模式或者加上@Lazy默认是true懒加载。


## 创建Bean

在IOC容器初始化的refresh()方法第11大步，有个独立的方法，就是处理Bean创建的，即bean实例化处理。

refresh()#finishBeanFactoryInitialization()源码：

```java
protected void finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory) {
	// Initialize conversion service for this context.
    // 为Bean工厂设置类型转化器
	if (beanFactory.containsBean(CONVERSION_SERVICE_BEAN_NAME) &&
			beanFactory.isTypeMatch(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class)) {
		beanFactory.setConversionService(
				beanFactory.getBean(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class));
	}
 
	// Register a default embedded value resolver if no bean post-processor
	// (such as a PropertyPlaceholderConfigurer bean) registered any before:
	// at this point, primarily for resolution in annotation attribute values.
	if (!beanFactory.hasEmbeddedValueResolver()) {
		beanFactory.addEmbeddedValueResolver(new StringValueResolver() {
			@Override
			public String resolveStringValue(String strVal) {
				return getEnvironment().resolvePlaceholders(strVal);
			}
		});
	}
 
	// Initialize LoadTimeWeaverAware beans early to allow for registering their transformers early.
	String[] weaverAwareNames = beanFactory.getBeanNamesForType(LoadTimeWeaverAware.class, false, false);
	for (String weaverAwareName : weaverAwareNames) {
		getBean(weaverAwareName);
	}
 
	// Stop using the temporary ClassLoader for type matching.
	beanFactory.setTempClassLoader(null);
 
	// Allow for caching all bean definition metadata, not expecting further changes.
    //冻结所有的Bean定义 ， 至此注册的Bean定义将不被修改或任何进一步的处理
	beanFactory.freezeConfiguration();
 
	// Instantiate all remaining (non-lazy-init) singletons. 初始化时创建Bean的入口
	beanFactory.preInstantiateSingletons();
}
```

DefaultListableBeanFactory#preInstantiateSingletons()源码：
```java
@Override
public void preInstantiateSingletons() throws BeansException {
	if (this.logger.isDebugEnabled()) {
		this.logger.debug("Pre-instantiating singletons in " + this);
	}
 
	// Iterate over a copy to allow for init methods which in turn register new bean definitions.
	// While this may not be part of the regular factory bootstrap, it does otherwise work fine.
    //获取我们容器中所有Bean定义的名称
	List<String> beanNames = new ArrayList<String>(this.beanDefinitionNames);
 
	// Trigger initialization of all non-lazy singleton beans...
	for (String beanName : beanNames) {
        //合并我们的bean定义
		RootBeanDefinition bd = getMergedLocalBeanDefinition(beanName);
        //非抽象，单例、非懒加载才会进入if逻辑
		if (!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()) {
			if (isFactoryBean(beanName)) {
                //是 给beanName+前缀 & 符号
				final FactoryBean<?> factory = (FactoryBean<?>) getBean(FACTORY_BEAN_PREFIX + beanName);
				boolean isEagerInit;
				if (System.getSecurityManager() != null && factory instanceof SmartFactoryBean) {
					isEagerInit = AccessController.doPrivileged(new PrivilegedAction<Boolean>() {
						@Override
						public Boolean run() {
							return ((SmartFactoryBean<?>) factory).isEagerInit();
						}
					}, getAccessControlContext());
				}
				else {
					isEagerInit = (factory instanceof SmartFactoryBean &&
							((SmartFactoryBean<?>) factory).isEagerInit());
				}
				if (isEagerInit) {
                     //调用真正的getBean
					getBean(beanName);
				}
			}
			else {
				// 在这里，调用getBean()进行bean实例创建
                //非工厂Bean就是普通的bean
				getBean(beanName);
			}
		}
	}
 
	// Trigger post-initialization callback for all applicable beans...
   获取所有的bean的名称 至此所有的单实例的bean已经加入到单实例Bean的缓存池中，所谓的单实例缓存池实际上就是一个ConcurrentHashMap
	for (String beanName : beanNames) {
         //从单例缓存池中获取所有的对象
		Object singletonInstance = getSingleton(beanName);
         //判断当前的bean是否实现了SmartInitializingSingleton接口
		if (singletonInstance instanceof SmartInitializingSingleton) {
			final SmartInitializingSingleton smartSingleton = (SmartInitializingSingleton) singletonInstance;
			if (System.getSecurityManager() != null) {
				AccessController.doPrivileged(new PrivilegedAction<Object>() {
					@Override
					public Object run() {
						smartSingleton.afterSingletonsInstantiated();
						return null;
					}
				}, getAccessControlContext());
			}
			else {
                //触发实例化之后的方法afterSingletonsInstantiated
				smartSingleton.afterSingletonsInstantiated();
			}
		}
	}
}
```

接下来真正创建Bean的入口就是getBean()，跟你第一次使用Bean的getBean()是一个入口，只是一个在初始化时调用，一个在第一次使用时调用，所以，是一套代码，原理一样。

下面从就从BeanFactory入手去看getBean()的实现。

```java
package org.springframework.beans.factory;
import org.springframework.beans.BeansException;
import org.springframework.core.ResolvableType;
public interface BeanFactory {
	String FACTORY_BEAN_PREFIX = "&";
	Object getBean(String name) throws BeansException;
	<T> T getBean(String name, Class<T> requiredType) throws BeansException;
	<T> T getBean(Class<T> requiredType) throws BeansException;
	Object getBean(String name, Object... args) throws BeansException;
	<T> T getBean(Class<T> requiredType, Object... args) throws BeansException;
	boolean containsBean(String name);
	boolean isSingleton(String name) throws NoSuchBeanDefinitionException;
	boolean isPrototype(String name) throws NoSuchBeanDefinitionException;
	boolean isTypeMatch(String name, ResolvableType typeToMatch) throws NoSuchBeanDefinitionException;
	boolean isTypeMatch(String name, Class<?> typeToMatch) throws NoSuchBeanDefinitionException;
	Class<?> getType(String name) throws NoSuchBeanDefinitionException;
	String[] getAliases(String name);
}
```

从getBean(String name)最简单明了的方法入手看实现，该方法在很多类中有实现，重点研究AbstractBeanFactory中的实现方法。
```java
	@Override
	public Object getBean(String name) throws BeansException {
        //真正的获取Bean的逻辑
		return doGetBean(name, null, null, false);
	}
```

```java

protected <T> T doGetBean(
      final String name, final Class<T> requiredType, final Object[] args, boolean typeCheckOnly)
      throws BeansException {
 
   //在这里传入进来的name可能是别名、也有可能是工厂beanName,所以在这里需要转换
   final String beanName = transformedBeanName(name);
   Object bean;
 
   // Eagerly check singleton cache for manually registered singletons.
   // 先从缓存中获得Bean，处理那些已经被创建过的单例模式的Bean,对这种Bean的请求不需要重复地创建
   Object sharedInstance = getSingleton(beanName);
   if (sharedInstance != null && args == null) {
      if (logger.isDebugEnabled()) {
         if (isSingletonCurrentlyInCreation(beanName)) {
            logger.debug("Returning eagerly cached instance of singleton bean '" + beanName +
                  "' that is not fully initialized yet - a consequence of a circular reference");
         }
         else {
            logger.debug("Returning cached instance of singleton bean '" + beanName + "'");
         }
      }
    // 这里的getObjectForBeanInstance完成的是FactoryBean的相关处理，以取得FactoryBean的生产结果
/**
             * 如果sharedInstance是普通的单例bean，下面的方法会直接返回。但如果
             * sharedInstance是FactoryBean类型的，则需调用getObject工厂方法获取真正的
             * bean实例。如果用户想获取 FactoryBean 本身，这里也不会做特别的处理，直接返回
             * 即可。毕竟 FactoryBean 的实现类本身也是一种 bean，只不过具有一点特殊的功能而已。
             */
      bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
   }
 
   else {
      // Fail if we're already creating this bean instance:
      // We're assumably within a circular reference.
      //Spring只能解决单例对象的setter注入的循环依赖,不能解决构造器注入，也不能解决多实例的循环依赖
      if (isPrototypeCurrentlyInCreation(beanName)) {
         throw new BeanCurrentlyInCreationException(beanName);
      }
 
      // Check if bean definition exists in this factory.
      /**
       * 对IOC容器中的BeanDefinition是否存在进行检查，检查是否能在当前的BeanFactory中取得需要的Bean。  
       * 如果在当前的工厂中取不到，则到双亲BeanFactory中去取；
       * 如果当前的双亲工厂取不到，就顺着双亲BeanFactory链一直向上查找
       */
       //判断是否有父工厂
      BeanFactory parentBeanFactory = getParentBeanFactory();
       //若存在父工厂,切当前的bean工厂不存在当前的bean定义,那么bean定义是存在于父beanFactory中
      if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
         // Not found -> check parent.
         //获取bean的原始名称
         String nameToLookup = originalBeanName(name);
         if (args != null) {
            // Delegation to parent with explicit args.
            // 委托给构造函数getBean()处理
            return (T) parentBeanFactory.getBean(nameToLookup, args);
         }
         else {
             // 没有args，委托给标准的getBean()处理
            // No args -> delegate to standard getBean method.
            return parentBeanFactory.getBean(nameToLookup, requiredType);
         }
      }
 
      /**
                   * 方法参数typeCheckOnly ，是用来判断调用getBean(...) 方法时，表示是否为仅仅进行类型检查获取Bean对象
                   * 如果不是仅仅做类型检查，而是创建Bean对象，则需要调用markBeanAsCreated(String beanName) 方法，进行记录
                   */
      if (!typeCheckOnly) {
         markBeanAsCreated(beanName);
      }
 
      try {
     // 根据Bean的名字获取BeanDefinition
         //从容器中获取beanName相应的GenericBeanDefinition对象，并将其转换为RootBeanDefinition对象
         final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
            //检查当前创建的bean定义是不是抽象的bean定义
         checkMergedBeanDefinition(mbd, beanName, args);
 
         // Guarantee initialization of beans that the current bean depends on.
     // 获取当前Bean的所有依赖Bean，这样会触发getBean的递归调用，直到渠道一个没有任何依赖的Bean为止
          //处理dependsOn的依赖(这个不是我们所谓的循环依赖 而是bean创建前后的依赖)
                          //依赖bean的名称
         String[] dependsOn = mbd.getDependsOn();
         if (dependsOn != null) {
            for (String dep : dependsOn) {
               //beanName是当前正在创建的bean,dep是正在创建的bean的依赖的bean的名称
               if (isDependent(beanName, dep)) {
                  throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                        "Circular depends-on relationship between '" + beanName + "' and '" + dep + "'");
               }
                 //保存的是依赖beanName之间的映射关系：依赖beanName -> beanName的集合
               registerDependentBean(dep, beanName);
                //获取dependsOn的bean
               getBean(dep);
            }
         }
     
         // Create bean instance.
      // 以下是创建Bean实例
       // 创建sigleton bean
         if (mbd.isSingleton()) {
             //把beanName和一个singletonFactory匿名内部类传入用于回调
            sharedInstance = getSingleton(beanName, new ObjectFactory<Object>() {
               @Override
               public Object getObject() throws BeansException {
                  try {
                     //创建bean的逻辑
                     return createBean(beanName, mbd, args);
                  }
                  catch (BeansException ex) {
                     // Explicitly remove instance from singleton cache: It might have been put there
                     // eagerly by the creation process, to allow for circular reference resolution.
                     // Also remove any beans that received a temporary reference to the bean.
                    //创建bean的过程中发生异常,需要销毁关于当前bean的所有信息
                     destroySingleton(beanName);
                     throw ex;
                  }
               }
            });
            bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
         }
     // 创建prototype bean
         else if (mbd.isPrototype()) {
            // It's a prototype -> create a new instance.
            Object prototypeInstance = null;
            try {
               beforePrototypeCreation(beanName);
               prototypeInstance = createBean(beanName, mbd, args);
            }
            finally {
               afterPrototypeCreation(beanName);
            }
            bean = getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
         }
     
         else {
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
                     }
                     finally {
                        afterPrototypeCreation(beanName);
                     }
                  }
               });
               bean = getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
            }
            catch (IllegalStateException ex) {
               throw new BeanCreationException(beanName,
                     "Scope '" + scopeName + "' is not active for the current thread; consider " +
                     "defining a scoped proxy for this bean if you intend to refer to it from a singleton",
                     ex);
            }
         }
      }
      catch (BeansException ex) {
         cleanupAfterBeanCreationFailure(beanName);
         throw ex;
      }
   }
 
   // Check if required type matches the type of the actual bean instance.
  // 对创建的Bean进行类型检查，如果没有问题，就返回这个新创建的Bean，这个Bean已经是包含依赖关系的Bean
   if (requiredType != null && bean != null && !requiredType.isAssignableFrom(bean.getClass())) {
      try {
         return getTypeConverter().convertIfNecessary(bean, requiredType);
      }
      catch (TypeMismatchException ex) {
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

getBean()方法只是创建对象的起点，doGetBean()只是getBean()的具体执行，在doGetBean()中会调用createBean()方法，在这个过程中，Bean对象会依据BeanDefinition定义的要求生成。
AbstractBeanFactory中的createBean是一个抽象方法，具体的实现在AbstractAutowireCapableBeanFactory中。

```java
@Override
protected Object createBean(String beanName, RootBeanDefinition mbd, Object[] args) throws BeanCreationException {
   if (logger.isDebugEnabled()) {
      logger.debug("Creating instance of bean '" + beanName + "'");
   }
   RootBeanDefinition mbdToUse = mbd;
 
   // Make sure bean class is actually resolved at this point, and
   // clone the bean definition in case of a dynamically resolved Class
   // which cannot be stored in the shared merged bean definition.
   // 判断需要创建的Bean是否可以实例化，
   Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
   if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
      mbdToUse = new RootBeanDefinition(mbd);
      mbdToUse.setBeanClass(resolvedClass);
   }
 
   // Prepare method overrides.
   try {
      mbdToUse.prepareMethodOverrides();
   }
   catch (BeanDefinitionValidationException ex) {
      throw new BeanDefinitionStoreException(mbdToUse.getResourceDescription(),
            beanName, "Validation of method overrides failed", ex);
   }
 
   try {
      // Give BeanPostProcessors a chance to return a proxy instead of the target bean instance.
      // 如果Bean配置了PostProcessor，则返回一个proxy代理对象
      Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
      if (bean != null) {
         return bean;
      }
   }
   catch (Throwable ex) {
      throw new BeanCreationException(mbdToUse.getResourceDescription(), beanName,
            "BeanPostProcessor before instantiation of bean failed", ex);
   }
  // 创建Bean的调用
   Object beanInstance = doCreateBean(beanName, mbdToUse, args);
   if (logger.isDebugEnabled()) {
      logger.debug("Finished creating instance of bean '" + beanName + "'");
   }
   return beanInstance;
}
```

```java

protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final Object[] args)
      throws BeanCreationException {
 
   // Instantiate the bean.
   // 这个BeanWrapper是用来持有创建出来的Bean对象
   //BeanWrapper是对Bean的包装，其接口中所定义的功能很简单包括设置获取被包装的对象，获取被包装bean的属性描述器
   BeanWrapper instanceWrapper = null;
   // 如果是Singleton，先把缓存中的同名Bean清除
   if (mbd.isSingleton()) {
       //从没有完成的FactoryBean中移除
      instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
   }
   // 通过createBeanInstance()创建Bean
   if (instanceWrapper == null) {
      //使用合适的实例化策略来创建新的实例：工厂方法、构造函数自动注入、简单初始化 比较复杂也很重要
      instanceWrapper = createBeanInstance(beanName, mbd, args);
   }
    //从beanWrapper中获取我们的早期对象
   final Object bean = (instanceWrapper != null ? instanceWrapper.getWrappedInstance() : null);
   Class<?> beanType = (instanceWrapper != null ? instanceWrapper.getWrappedClass() : null);
   mbd.resolvedTargetType = beanType;
 
   // Allow post-processors to modify the merged bean definition.
   synchronized (mbd.postProcessingLock) {
      if (!mbd.postProcessed) {
         try {
               //进行后置处理@AutoWired的注解的预解析
            applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
         }
         catch (Throwable ex) {
            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                  "Post-processing of merged bean definition failed", ex);
         }
         mbd.postProcessed = true;
      }
   }
 
   // Eagerly cache singletons to be able to resolve circular references
   // even when triggered by lifecycle interfaces like BeanFactoryAware.
  
        /**
         * 该对象进行判断是否能够暴露早期对象的条件
         * 单实例 this.allowCircularReferences 默认为true
         * isSingletonCurrentlyInCreation(表示当前的bean对象正在创建singletonsCurrentlyInCreation包含当前正在创建的bean)
         */
   boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
         isSingletonCurrentlyInCreation(beanName));
      //上述条件满足，允许中期暴露对象
   if (earlySingletonExposure) {
      if (logger.isDebugEnabled()) {
         logger.debug("Eagerly caching bean '" + beanName +
               "' to allow for resolving potential circular references");
      }
      //把我们的早期对象包装成一个singletonFactory对象 该对象提供了一个getObject方法,该方法内部调用getEarlyBeanReference方法
      addSingletonFactory(beanName, new ObjectFactory<Object>() {
         @Override
         public Object getObject() throws BeansException {
            return getEarlyBeanReference(beanName, mbd, bean);
         }
      });
   }
 
   // Initialize the bean instance.
   // 对Bean进行初始化，这个exposedObject在初始化以后会返回作为依赖注入完成后的Bean
   Object exposedObject = bean;
   try {
       //给我们的属性进行赋值(调用set方法进行赋值)
      populateBean(beanName, mbd, instanceWrapper);
      if (exposedObject != null) {
         //进行对象初始化操作(在这里可能生成代理对象)
         exposedObject = initializeBean(beanName, exposedObject, mbd);
      }
   }
   catch (Throwable ex) {
      if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
         throw (BeanCreationException) ex;
      }
      else {
         throw new BeanCreationException(
               mbd.getResourceDescription(), beanName, "Initialization of bean failed", ex);
      }
   }
   //允许早期对象的引用
   if (earlySingletonExposure) {
        /**
                     * 去缓存中获取到我们的对象 由于传递的allowEarlyReference 是false 要求只能在一级二级缓存中去获取
                     * 正常普通的bean(不存在循环依赖的bean) 创建的过程中，压根不会把三级缓存提升到二级缓存中
                     */
      Object earlySingletonReference = getSingleton(beanName, false);

//能够获取到
      if (earlySingletonReference != null) {
           //经过后置处理的bean和早期的bean引用还相等的话(表示当前的bean没有被代理过)
         if (exposedObject == bean) {
            exposedObject = earlySingletonReference;
         }
//处理依赖的bean
         else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
            String[] dependentBeans = getDependentBeans(beanName);
            Set<String> actualDependentBeans = new LinkedHashSet<String>(dependentBeans.length);
            for (String dependentBean : dependentBeans) {
               if (!removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
                  actualDependentBeans.add(dependentBean);
               }
            }
            if (!actualDependentBeans.isEmpty()) {
               throw new BeanCurrentlyInCreationException(beanName,
                     "Bean with name '" + beanName + "' has been injected into other beans [" +
                     StringUtils.collectionToCommaDelimitedString(actualDependentBeans) +
                     "] in its raw version as part of a circular reference, but has eventually been " +
                     "wrapped. This means that said other beans do not use the final version of the " +
                     "bean. This is often the result of over-eager type matching - consider using " +
                     "'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.");
            }
         }
      }
   }
 
   // Register bean as disposable.
   try {
//注册销毁的bean的销毁接口
      registerDisposableBeanIfNecessary(beanName, bean, mbd);
   }
   catch (BeanDefinitionValidationException ex) {
      throw new BeanCreationException(
            mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
   }
 
   return exposedObject;
}
```


看下真正创建Bean对象的方法createBeanInstance()，该方法会生成包含Java对象的Bean，这个Bean生成有很多中方式，可以通过工厂方法生成，也可以通过容器的Autowire特性生成，
这些生成方式都是由相关的BeanDefinition来指定的。看下以下正在创建对象的源码。

```java
protected BeanWrapper createBeanInstance(String beanName, RootBeanDefinition mbd, Object[] args) {
   // Make sure bean class is actually resolved at this point.
   // 确认需要创建的Bean实例的类可以实例化
 //从bean定义中解析出当前bean的class对象
   Class<?> beanClass = resolveBeanClass(mbd, beanName);
  // 以下通过工厂方法对Bean进行实例化
//检测类的访问权限。默认情况下，对于非 public 的类，是允许访问的。若禁止访问，这里会抛出异常
   if (beanClass != null && !Modifier.isPublic(beanClass.getModifiers()) && !mbd.isNonPublicAccessAllowed()) {
      throw new BeanCreationException(mbd.getResourceDescription(), beanName,
            "Bean class isn't public, and non-public access not allowed: " + beanClass.getName());
   }
  //工厂方法,我们通过配置类来进行配置的话 采用的就是工厂方法
   if (mbd.getFactoryMethodName() != null)  {
      return instantiateUsingFactoryMethod(beanName, mbd, args);
   }
   
   // Shortcut when re-creating the same bean...
   // 重新创建Bean的快捷方式
   //判断当前构造函数是否被解析过
   boolean resolved = false;
  //有没有必须进行依赖注入
   boolean autowireNecessary = false;
 /**
         * 通过getBean传入进来的构造函数是否来指定需要推断构造函数
         * 若传递进来的args不为空，那么就可以直接选出对应的构造函数
         */
   if (args == null) {

      //判断我们的bean定义信息中的resolvedConstructorOrFactoryMethod(用来缓存我们的已经解析的构造函数或者工厂方法)
      synchronized (mbd.constructorArgumentLock) {
         if (mbd.resolvedConstructorOrFactoryMethod != null) {
            //修改已经解析过的构造函数的标志
            resolved = true;
             //修改标记为ture 标识构造函数或者工厂方法已经解析过
            autowireNecessary = mbd.constructorArgumentsResolved;
         }
      }
   }
    //若被解析过
   if (resolved) {
      if (autowireNecessary) {
         //通过有参的构造函数进行反射调用
         return autowireConstructor(beanName, mbd, null, null);
      }
      else {
          //调用无参数的构造函数进行创建对象
         return instantiateBean(beanName, mbd);
      }
   }
 
   // Need to determine the constructor...
   // 以下使用构造函数对Bean进行实例化
//通过bean的后置处理器进行选举出合适的构造函数对象
   Constructor<?>[] ctors = determineConstructorsFromBeanPostProcessors(beanClass, beanName);
 //通过后置处理器解析出构造器对象不为null或获取bean定义中的注入模式是构造器注入或bean定义信息ConstructorArgumentValues或获取通过getBean的方式传入的构造器函数参数类型不为null
   if (ctors != null ||
         mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_CONSTRUCTOR ||
         mbd.hasConstructorArgumentValues() || !ObjectUtils.isEmpty(args))  {
//通过构造函数创建对象
      return autowireConstructor(beanName, mbd, ctors, args);
   }
 
   // No special handling: simply use no-arg constructor.
   // 使用默认的构造器函数对Bean进行实例化
//使用无参数的构造函数调用创建对象
   return instantiateBean(beanName, mbd);
}
```

instantiateBean()方法采用默认构造器实例化bean的过程。

```java
protected BeanWrapper instantiateBean(final String beanName, final RootBeanDefinition mbd) {
   try {
      Object beanInstance;
      final BeanFactory parent = this;
      if (System.getSecurityManager() != null) {
         beanInstance = AccessController.doPrivileged(new PrivilegedAction<Object>() {
            @Override
            public Object run() {
               return getInstantiationStrategy().instantiate(mbd, beanName, parent);
            }
         }, getAccessControlContext());
      }
      else {
         beanInstance = getInstantiationStrategy().instantiate(mbd, beanName, parent);
      }
      BeanWrapper bw = new BeanWrapperImpl(beanInstance);
      initBeanWrapper(bw);
      return bw;
   }
   catch (Throwable ex) {
      throw new BeanCreationException(
            mbd.getResourceDescription(), beanName, "Instantiation of bean failed", ex);
   }
}
```

类中使用默认的实例化策略进行实例化，默认采用CGLIB对Bean进行实例化。CGLIB是一个常用的字节码生成器的类库，它提供了一些列的API来提供生成和转换Java的字节码的功能。

```java
@Override
public Object instantiate(RootBeanDefinition bd, String beanName, BeanFactory owner) {
   // Don't override the class with CGLIB if no overrides.
   if (bd.getMethodOverrides().isEmpty()) {
      // 获取指定的构造器或者生产对象工厂方法来对Bean进行实例化
      Constructor<?> constructorToUse;
      synchronized (bd.constructorArgumentLock) {
         constructorToUse = (Constructor<?>) bd.resolvedConstructorOrFactoryMethod;
         if (constructorToUse == null) {
            final Class<?> clazz = bd.getBeanClass();
            if (clazz.isInterface()) {
               throw new BeanInstantiationException(clazz, "Specified class is an interface");
            }
            try {
               if (System.getSecurityManager() != null) {
                  constructorToUse = AccessController.doPrivileged(new PrivilegedExceptionAction<Constructor<?>>() {
                     @Override
                     public Constructor<?> run() throws Exception {
                        return clazz.getDeclaredConstructor((Class[]) null);
                     }
                  });
               }
               else {
                  constructorToUse = clazz.getDeclaredConstructor((Class[]) null);
               }
               bd.resolvedConstructorOrFactoryMethod = constructorToUse;
            }
            catch (Throwable ex) {
               throw new BeanInstantiationException(clazz, "No default constructor found", ex);
            }
         }
      }
    // 通过BeanUtils进行实例化，这个BeanUtils实例化通过Constructor来实例化Bean，
      // 在BeanUtils中可以看到具体的调用ctor.newInstance(args)
      return BeanUtils.instantiateClass(constructorToUse);
   }
   else {
      // Must generate CGLIB subclass.
    // 使用CGLIB进行实例化
      return instantiateWithMethodInjection(bd, beanName, owner);
   }
}
```

```java

public static <T> T instantiateClass(Constructor<T> ctor, Object... args) throws BeanInstantiationException {
   Assert.notNull(ctor, "Constructor must not be null");
   try {
      ReflectionUtils.makeAccessible(ctor);
      return ctor.newInstance(args);
   }
   catch (InstantiationException ex) {
      throw new BeanInstantiationException(ctor, "Is it an abstract class?", ex);
   }
   catch (IllegalAccessException ex) {
      throw new BeanInstantiationException(ctor, "Is the constructor accessible?", ex);
   }
   catch (IllegalArgumentException ex) {
      throw new BeanInstantiationException(ctor, "Illegal arguments for constructor", ex);
   }
   catch (InvocationTargetException ex) {
      throw new BeanInstantiationException(ctor, "Constructor threw exception", ex.getTargetException());
   }
}
```

如果感兴趣，可以一直追溯newInstance()方法，最后调用一个Native方法创建对象。

到此，Bean对象创建完成。
