# AutowireCandidateResolver深度分析，解析@Lazy、@Qualifier注解的原理

关于AutowireCandidateResolver接口，可能绝大多数小伙伴都会觉得陌生。但若谈起@Autowired、@Primary、@Qualifier、@Value、@Lazy等注解，相信没有小伙伴是不知道的吧。

AutowireCandidateResolver用于确定特定的Bean定义是否符合特定的依赖项的候选者的策略接口。

```java
// @since 2.5   伴随着@Autowired体系出现
public interface AutowireCandidateResolver {
	
	// 判断给定的bean定义是否允许被依赖注入（bean定义的默认值都是true）
	default boolean isAutowireCandidate(BeanDefinitionHolder bdHolder, DependencyDescriptor descriptor) {
		return bdHolder.getBeanDefinition().isAutowireCandidate();
	}

	// 给定的descriptor是否是必须的~~~
	// @since 5.0
	default boolean isRequired(DependencyDescriptor descriptor) {
		return descriptor.isRequired();
	}
	// QualifierAnnotationAutowireCandidateResolver对它有实现
	//  @since 5.1 此方法出现得非常的晚
	default boolean hasQualifier(DependencyDescriptor descriptor) {
		return false;
	}
	
	// 是否给一个建议值 注入的时候~~~QualifierAnnotationAutowireCandidateResolvert有实现
	// @since 3.0
	@Nullable
	default Object getSuggestedValue(DependencyDescriptor descriptor) {
		return null;
	}

	// 如果注入点injection point需要的话，就创建一个proxy来作为最终的解决方案ContextAnnotationAutowireCandidateResolver
	// @since 4.0
	@Nullable
	default Object getLazyResolutionProxyIfNecessary(DependencyDescriptor descriptor, @Nullable String beanName) {
		return null;
	}
}



```

查看它的继承树：

```text
SimpleAutowireCandidateResolver (org.springframework.beans.factory.support)
    GenericTypeAwareAutowireCandidateResolver (org.springframework.beans.factory.support)
        QualifierAnnotationAutowireCandidateResolver (org.springframework.beans.factory.annotation)
            ContextAnnotationAutowireCandidateResolver (org.springframework.context.annotation)
                LazyRepositoryInjectionPointResolver in RepositoryConfigurationDelegate (org.springframework.data.repository.config)


```
层次特点非常明显：每一层都只有一个类，所以毫无疑问，最后一个实现类肯定是功能最全的了。

#### GenericTypeAwareAutowireCandidateResolver

从名字可以看出和泛型有关。Spring4.0后的泛型依赖注入主要是它来实现的，所以这个类也是Spring4.0后出现的
```java
//@since 4.0 它能够根据泛型类型进行匹配~~~~  【泛型依赖注入】
public class GenericTypeAwareAutowireCandidateResolver extends SimpleAutowireCandidateResolver implements BeanFactoryAware {

	// 它能处理类型  毕竟@Autowired都是按照类型匹配的
	@Nullable
	private BeanFactory beanFactory;

	// 是否允许被依赖~~~
	// 因为bean定义里默认是true，绝大多数情况下我们不会修改它~~~
	// 所以继续执行：checkGenericTypeMatch 看看泛型类型是否能够匹配上
	// 若能够匹配上   这个就会被当作候选的Bean了~~~
	@Override
	public boolean isAutowireCandidate(BeanDefinitionHolder bdHolder, DependencyDescriptor descriptor) {
		// 如果bean定义里面已经不允许了  那就不往下走了  显然我们不会这么做
		if (!super.isAutowireCandidate(bdHolder, descriptor)) {
			// If explicitly false, do not proceed with any other checks...
			return false;
		}
		// 处理泛型依赖的核心方法~~~  也是本实现类的灵魂
		// 注意：这里还兼容到了工厂方法模式FactoryMethod
		// 所以即使你返回BaseDao<T>它是能够很好的处理好类型的~~~
		return checkGenericTypeMatch(bdHolder, descriptor);
	}
	...
}

```
本实现类的主要任务就是解决了泛型依赖，此类虽然为实现类，但也不建议直接使用，因为功能还不完整~

#### QualifierAnnotationAutowireCandidateResolver

这个实现类非常非常的重要，它继承自GenericTypeAwareAutowireCandidateResolver，所以它不仅仅能处理org.springframework.beans.factory.annotation.Qualifier、@Value，还能够处理泛型依赖注入，因此功能已经很完善了~~~ 在Spring2.5之后都使用它来处理依赖关系~

    Spring4.0之前它继承自SimpleAutowireCandidateResolver，Spring4.0之后才继承自GenericTypeAwareAutowireCandidateResolver

它不仅仅能够处理@Qualifier注解，也能够处理通过@Value注解解析表达式得到的suggested value，也就是说它还实现了接口方法getSuggestedValue()；

    getSuggestedValue()方法是Spring3.0后提供的，因为@Value注解是Spring3.0后提供的强大注解。


```java
// @since 2.5
public class QualifierAnnotationAutowireCandidateResolver extends GenericTypeAwareAutowireCandidateResolver {

	// 支持的注解类型，默认支持@Qualifier和JSR-330的javax.inject.Qualifier注解
	private final Set<Class<? extends Annotation>> qualifierTypes = new LinkedHashSet<>(2);
	private Class<? extends Annotation> valueAnnotationType = Value.class;

	// 你可可以通过构造函数，增加你自定义的注解的支持~~~
	// 注意都是add  不是set
	public QualifierAnnotationAutowireCandidateResolver(Class<? extends Annotation> qualifierType) {
		Assert.notNull(qualifierType, "'qualifierType' must not be null");
		this.qualifierTypes.add(qualifierType);
	}
	public QualifierAnnotationAutowireCandidateResolver(Set<Class<? extends Annotation>> qualifierTypes) {
		Assert.notNull(qualifierTypes, "'qualifierTypes' must not be null");
		this.qualifierTypes.addAll(qualifierTypes);
	}
	
	// 后面讲的CustomAutowireConfigurer 它会调用这个方法来自定义注解
	public void addQualifierType(Class<? extends Annotation> qualifierType) {
		this.qualifierTypes.add(qualifierType);
	}
	//@Value注解类型Spring也是允许我们改成自己的类型的
	public void setValueAnnotationType(Class<? extends Annotation> valueAnnotationType) {
		this.valueAnnotationType = valueAnnotationType;
	}
	
	// 这个实现，比父类的实现就更加的严格了，区分度也就越高了~~~
	// checkQualifiers方法是本类的核心，灵魂
	// 它有两个方法getQualifiedElementAnnotation和getFactoryMethodAnnotation表名了它支持filed和方法
	@Override
	public boolean isAutowireCandidate(BeanDefinitionHolder bdHolder, DependencyDescriptor descriptor) {
		boolean match = super.isAutowireCandidate(bdHolder, descriptor);
		// 这里发现，及时父类都匹配上了，我本来还得再次校验一把~~~
		if (match) {
			// @Qualifier注解在此处生效  最终可能匹配出一个或者0个出来
			match = checkQualifiers(bdHolder, descriptor.getAnnotations());
			// 若字段上匹配上了还不行，还得看方法上的这个注解
			if (match) {
				// 这里处理的是方法入参们~~~~  只有方法有入参才需要继续解析
				MethodParameter methodParam = descriptor.getMethodParameter();
				if (methodParam != null) {
					Method method = methodParam.getMethod();

					// 这个处理非常有意思：methodParam.getMethod()表示这个入参它所属于的方法
					// 如果它不属于任何方法或者属于方法的返回值是void  才去看它头上标注的@Qualifier注解
					if (method == null || void.class == method.getReturnType()) {
						match = checkQualifiers(bdHolder, methodParam.getMethodAnnotations());
					}
				}
			}
		}
		return match;
	}
	
	...
	
	protected boolean isQualifier(Class<? extends Annotation> annotationType) {
		for (Class<? extends Annotation> qualifierType : this.qualifierTypes) {
			if (annotationType.equals(qualifierType) || annotationType.isAnnotationPresent(qualifierType)) {
				return true;
			}
		}
		return false;
	}

	// 这里显示的使用了Autowired 注解，我个人感觉这里是不应该的~~~~ 毕竟已经到这一步了  应该脱离@Autowired注解本身
	// 当然，这里相当于是做了个fallback~~~还算可以接受吧
	@Override
	public boolean isRequired(DependencyDescriptor descriptor) {
		if (!super.isRequired(descriptor)) {
			return false;
		}
		Autowired autowired = descriptor.getAnnotation(Autowired.class);
		return (autowired == null || autowired.required());
	}

	// 标注的所有注解里  是否有@Qualifier这个注解~
	@Override
	public boolean hasQualifier(DependencyDescriptor descriptor) {
		for (Annotation ann : descriptor.getAnnotations()) {
			if (isQualifier(ann.annotationType())) {
				return true;
			}
		}
		return false;
	}

	// @since 3.0   这是本类的另外一个核心 解析@Value注解
	// 需要注意的是此类它不负责解析占位符啥的  只复杂把字符串返回
	// 最终是交给value = evaluateBeanDefinitionString(strVal, bd);它处理~~~
	@Override
	@Nullable
	public Object getSuggestedValue(DependencyDescriptor descriptor) {
		// 拿到value注解（当然不一定是@Value注解  可以自定义嘛）  并且拿到它的注解属性value值~~~  比如#{person}
		Object value = findValue(descriptor.getAnnotations());
		if (value == null) {
			// 相当于@Value注解标注在方法入参上 也是阔仪的~~~~~
			MethodParameter methodParam = descriptor.getMethodParameter();
			if (methodParam != null) {
				value = findValue(methodParam.getMethodAnnotations());
			}
		}
		return value;
	}
	...
}

```

这个注解的功能已经非常强大了，Spring4.0之前都是使用的它去解决候选、依赖问题，但也不建议直接使用，因为下面这个，也就是它的子类更为强大~

#### ContextAnnotationAutowireCandidateResolver

官方把这个类描述为：策略接口的完整实现。它不仅仅支持上面所有描述的功能，还支持@Lazy懒处理~~~(注意此处懒处理(延迟处理)，不是懒加载~)

    @Lazy一般含义是懒加载，它只会作用于BeanDefinition.setLazyInit()。而此处给它增加了一个能力：延迟处理（代理处理）

```java
// @since 4.0 出现得挺晚，它支持到了@Lazy  是功能最全的AutowireCandidateResolver
public class ContextAnnotationAutowireCandidateResolver extends QualifierAnnotationAutowireCandidateResolver {
	// 这是此类本身唯一做的事，此处精析	
	// 返回该 lazy proxy 表示延迟初始化，实现过程是查看在 @Autowired 注解处是否使用了 @Lazy = true 注解 
	@Override
	@Nullable
	public Object getLazyResolutionProxyIfNecessary(DependencyDescriptor descriptor, @Nullable String beanName) {
		// 如果isLazy=true  那就返回一个代理，否则返回null
		// 相当于若标注了@Lazy注解，就会返回一个代理（当然@Lazy注解的value值不能是false）
		return (isLazy(descriptor) ? buildLazyResolutionProxy(descriptor, beanName) : null);
	}

	// 这个比较简单，@Lazy注解标注了就行（value属性默认值是true）
	// @Lazy支持标注在属性上和方法入参上~~~  这里都会解析
	protected boolean isLazy(DependencyDescriptor descriptor) {
		for (Annotation ann : descriptor.getAnnotations()) {
			Lazy lazy = AnnotationUtils.getAnnotation(ann, Lazy.class);
			if (lazy != null && lazy.value()) {
				return true;
			}
		}
		MethodParameter methodParam = descriptor.getMethodParameter();
		if (methodParam != null) {
			Method method = methodParam.getMethod();
			if (method == null || void.class == method.getReturnType()) {
				Lazy lazy = AnnotationUtils.getAnnotation(methodParam.getAnnotatedElement(), Lazy.class);
				if (lazy != null && lazy.value()) {
					return true;
				}
			}
		}
		return false;
	}

	// 核心内容，是本类的灵魂~~~
	protected Object buildLazyResolutionProxy(final DependencyDescriptor descriptor, final @Nullable String beanName) {
		Assert.state(getBeanFactory() instanceof DefaultListableBeanFactory,
				"BeanFactory needs to be a DefaultListableBeanFactory");

		// 这里毫不客气的使用了面向实现类编程，使用了DefaultListableBeanFactory.doResolveDependency()方法~~~
		final DefaultListableBeanFactory beanFactory = (DefaultListableBeanFactory) getBeanFactory();

		//TargetSource 是它实现懒加载的核心原因，在AOP那一章节了重点提到过这个接口，此处不再叙述
		// 它有很多的著名实现如HotSwappableTargetSource、SingletonTargetSource、LazyInitTargetSource、
		//SimpleBeanTargetSource、ThreadLocalTargetSource、PrototypeTargetSource等等非常多
		// 此处因为只需要自己用，所以采用匿名内部类的方式实现~~~ 此处最重要是看getTarget方法，它在被使用的时候（也就是代理对象真正使用的时候执行~~~）
		TargetSource ts = new TargetSource() {
			@Override
			public Class<?> getTargetClass() {
				return descriptor.getDependencyType();
			}
			@Override
			public boolean isStatic() {
				return false;
			}
	
			// getTarget是调用代理方法的时候会调用的，所以执行每个代理方法都会执行此方法，这也是为何doResolveDependency
			// 我个人认为它在效率上，是存在一定的问题的~~~所以此处建议尽量少用@Lazy~~~   
			//不过效率上应该还好，对比http、序列化反序列化处理，简直不值一提  所以还是无所谓  用吧
			@Override
			public Object getTarget() {
				Object target = beanFactory.doResolveDependency(descriptor, beanName, null, null);
				if (target == null) {
					Class<?> type = getTargetClass();
					// 对多值注入的空值的友好处理（不要用null）
					if (Map.class == type) {
						return Collections.emptyMap();
					} else if (List.class == type) {
						return Collections.emptyList();
					} else if (Set.class == type || Collection.class == type) {
						return Collections.emptySet();
					}
					throw new NoSuchBeanDefinitionException(descriptor.getResolvableType(),
							"Optional dependency not present for lazy injection point");
				}
				return target;
			}
			@Override
			public void releaseTarget(Object target) {
			}
		};


		// 使用ProxyFactory  给ts生成一个代理
		// 由此可见最终生成的代理对象的目标对象其实是TargetSource,而TargetSource的目标才是我们业务的对象
		ProxyFactory pf = new ProxyFactory();
		pf.setTargetSource(ts);
		Class<?> dependencyType = descriptor.getDependencyType();
		
		// 如果注入的语句是这么写的private AInterface a;  那这类就是借口 值是true
		// 把这个接口类型也得放进去（不然这个代理都不属于这个类型，反射set的时候岂不直接报错了吗？？？？）
		if (dependencyType.isInterface()) {
			pf.addInterface(dependencyType);
		}
		return pf.getProxy(beanFactory.getBeanClassLoader());
	}
}

```

它很好的用到了TargetSource这个接口，结合动态代理来支持到了@Lazy注解。
标注有@Lazy注解完成注入的时候，最终注入只是一个此处临时生成的代理对象，只有在真正执行目标方法的时候才会去容器内拿到真是的bean实例来执行目标方法。

     特别注意：此代理对象非彼代理对象，这个一定一定一定要区分开来~

通过@Lazy注解能够解决很多情况下的循环依赖问题，它的基本思想是先'随便'给你创建一个代理对象先放着，等你真正执行方法的时候再实际去容器内找出目标实例执行~

    我们要明白这种解决问题的思路带来的好处是能够解决很多场景下的循环依赖问题，但是要知道它每次执行目标方法的时候都会去执行TargetSource.getTarget()方法，所以需要做好缓存，避免对执行效率的影响（实测执行效率上的影响可以忽略不计）

ContextAnnotationAutowireCandidateResolver这个处理器才是被Bean工厂最终最终使用的，因为它的功能是最全的~

回顾一下，注册进Bean工厂的参考代码处：

```java
public abstract class AnnotationConfigUtils {
	...
	public static Set<BeanDefinitionHolder> registerAnnotationConfigProcessors(BeanDefinitionRegistry registry, @Nullable Object source) {
		DefaultListableBeanFactory beanFactory = unwrapDefaultListableBeanFactory(registry);
		if (beanFactory != null) {
			// 设置默认的排序器  支持@Order等
			if (!(beanFactory.getDependencyComparator() instanceof AnnotationAwareOrderComparator)) {
				beanFactory.setDependencyComparator(AnnotationAwareOrderComparator.INSTANCE);
			}
			// 设置依赖注入的候选处理器
			// 可以看到只要不是ContextAnnotationAutowireCandidateResolver类型  直接升级为最强类型
			if (!(beanFactory.getAutowireCandidateResolver() instanceof ContextAnnotationAutowireCandidateResolver)) {
				beanFactory.setAutowireCandidateResolver(new ContextAnnotationAutowireCandidateResolver());
			}
		}
		... // ====下面是大家熟悉的注册默认6大后置处理器：====
		// 1.ConfigurationClassPostProcessor
		// 2.AutowiredAnnotationBeanPostProcessor 
		// 3.CommonAnnotationBeanPostProcessor
		// 4.Jpa的PersistenceAnnotationProcessor（没导包就不会注册）
		// 5.EventListenerMethodProcessor
		// 6.DefaultEventListenerFactory
	}
	...
}

```

此段代码执行还是非常早的，在容器的刷新时的ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();这一步就完成了~

最后，把这个四个哥们 从上至下 简单总结如下：

1. SimpleAutowireCandidateResolver 相当于一个简单的适配器
2. GenericTypeAwareAutowireCandidateResolver 判断泛型是否匹配，支持泛型依赖注入（From Spring4.0）
3. QualifierAnnotationAutowireCandidateResolver 处理 @Qualifier 和 @Value 注解
4. ContextAnnotationAutowireCandidateResolver 处理 @Lazy 注解，重写了 getLazyResolutionProxyIfNecessary 方法。