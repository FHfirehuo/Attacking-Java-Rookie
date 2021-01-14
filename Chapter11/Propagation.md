# Spring事务传播

## Spring中七种Propagation类的事务属性详解
| 值 | 说明 |
| :---: | :---:|
| NOT_SUPPORTED | 以非事务方式执行操作，如果当前存在事务，就把当前事务挂起。 |
|NEVER |以非事务方式执行，如果当前存在事务，则抛出异常。 |
|NESTED | 支持当前事务，如果当前事务存在，则执行一个嵌套事务，如果当前没有事务，就新建一个事务|
|REQUIRED |支持当前事务，如果当前没有事务，就新建一个事务。这是最常见的选择  默认的传播行为|
|SUPPORTS |支持当前事务，如果当前没有事务，就以非事务方式执行 |
| MANDATORY| 支持当前事务，如果当前没有事务，就抛出异常|
| REQUIRES_NEW| 新建事务，如果当前存在事务，把当前事务挂起|

可以将其看成两大类，即是否支持当前事务：

#### 支持当前事务（在同一个事务中）：
* PROPAGATION_REQUIRED：支持当前事务，如果不存在，就新建一个事务。
* PROPAGATION_MANDATORY：支持当前事务，如果不存在，就抛出异常。
* PROPAGATION_SUPPORTS：支持当前事务，如果不存在，就不使用事务。

#### 不支持当前事务（不在同一个事务中）：
* PROPAGATION_NEVER：以非事务的方式运行，如果有事务，则抛出异常。
* PROPAGATION_NOT_SUPPORTED：以非事务的方式运行，如果有事务，则挂起当前事务。
* PROPAGATION_REQUIRES_NEW：新建事务，如果有事务，挂起当前事务（两个事务相互独立，父事务回滚不影响子事务）。
* PROPAGATION_NESTED：如果当前事务存在，则嵌套事务执行（指必须依存父事务，子事务不能单独提交且父事务回滚则子事务也必须回滚，而子事务若回滚，父事务可以回滚也可以捕获异常）。如果当前没有事务，则进行与PROPAGATION_REQUIRED类似的操作。


实际上我们主要用的是PROPAGATION_REQUIRED默认属性，一些特殊业务下可能会用到PROPAGATION_REQUIRES_NEW以及PROPAGATION_NESTED。下面我会假设一个场景，并主要分析这三个属性。

## Spring事务是如何传播的

其实之前有分析事务注解的解析过程，本质上是将事务封装为切面加入到AOP的执行链中，因此会调用到MethodInceptor的实现类的invoke方法，
而事务切面的Interceptor就是TransactionInterceptor，所以本篇直接从该类开始。

TransactionInterceptor#invoke

```java
	@Override
	@Nullable
	public Object invoke(MethodInvocation invocation) throws Throwable {
		// Work out the target class: may be {@code null}.
		// The TransactionAttributeSource should be passed the target class
		// as well as the method, which may be from an interface.
		Class<?> targetClass = (invocation.getThis() != null ? AopUtils.getTargetClass(invocation.getThis()) : null);

		// Adapt to TransactionAspectSupport's invokeWithinTransaction...
		return invokeWithinTransaction(invocation.getMethod(), targetClass, invocation::proceed);
	}


```



```java
	@Override
	@Nullable
	public Object invoke(MethodInvocation invocation) throws Throwable {
		// Work out the target class: may be {@code null}.
		// The TransactionAttributeSource should be passed the target class
		// as well as the method, which may be from an interface.
		Class<?> targetClass = (invocation.getThis() != null ? AopUtils.getTargetClass(invocation.getThis()) : null);

		// Adapt to TransactionAspectSupport's invokeWithinTransaction...
		return invokeWithinTransaction(invocation.getMethod(), targetClass, invocation::proceed);
	}
```

这个方法本身没做什么事，主要是调用了父类的invokeWithinTransaction方法，注意最后一个参数，传入的是一个lambda表达式，而这个表达式中的调用的方法应该不陌生，
在分析AOP调用链时，就是通过这个方法传递到下一个切面或是调用被代理实例的方法，忘记了的可以回去看看。

#### TransactionAspectSupport#invokeWithinTransaction

```java
	@Nullable
	protected Object invokeWithinTransaction(Method method, @Nullable Class<?> targetClass,
			final InvocationCallback invocation) throws Throwable {

		// If the transaction attribute is null, the method is non-transactional.
//获取事务属性类 AnnotationTransactionAttributeSource
		TransactionAttributeSource tas = getTransactionAttributeSource();
//TransactionAttributeSource#getTransactionAttribute 获取事务相关的信息(TransactionAttribute)，以注解型事务为例，看方法获取类上有没有标注@Transactional注解。
		final TransactionAttribute txAttr = (tas != null ? tas.getTransactionAttribute(method, targetClass) : null);
		final TransactionManager tm = determineTransactionManager(txAttr);

//获取事务管理器
		if (this.reactiveAdapterRegistry != null && tm instanceof ReactiveTransactionManager) {
			ReactiveTransactionSupport txSupport = this.transactionSupportCache.computeIfAbsent(method, key -> {
				if (KotlinDetector.isKotlinType(method.getDeclaringClass()) && KotlinDelegate.isSuspend(method)) {
					throw new TransactionUsageException(
							"Unsupported annotated transaction on suspending function detected: " + method +
							". Use TransactionalOperator.transactional extensions instead.");
				}
				ReactiveAdapter adapter = this.reactiveAdapterRegistry.getAdapter(method.getReturnType());
				if (adapter == null) {
					throw new IllegalStateException("Cannot apply reactive transaction to non-reactive return type: " +
							method.getReturnType());
				}
				return new ReactiveTransactionSupport(adapter);
			});
			return txSupport.invokeWithinTransaction(
					method, targetClass, invocation, txAttr, (ReactiveTransactionManager) tm);
		}

//获取到 Spring 容器中配置的事务管理器 (PlatformTransactionManager)，后面就是真正的事务处理
		PlatformTransactionManager ptm = asPlatformTransactionManager(tm);
		final String joinpointIdentification = methodIdentification(method, targetClass, txAttr);

		if (txAttr == null || !(ptm instanceof CallbackPreferringPlatformTransactionManager)) {
			// Standard transaction demarcation with getTransaction and commit/rollback calls.
//创建事务信息(TransactionInfo)，里面包含事务管理器(PlatformTransactionManager) 以及事务相关信息(TransactionAttribute)
			TransactionInfo txInfo = createTransactionIfNecessary(ptm, txAttr, joinpointIdentification);

			Object retVal;
			try {
				// This is an around advice: Invoke the next interceptor in the chain.
				// This will normally result in a target object being invoked.
// 调用proceed方法
				retVal = invocation.proceedWithInvocation();
			}
			catch (Throwable ex) {
				// target invocation exception
//事务回滚
				completeTransactionAfterThrowing(txInfo, ex);
				throw ex;
			}
			finally {
				cleanupTransactionInfo(txInfo);
			}

			if (retVal != null && vavrPresent && VavrDelegate.isVavrTry(retVal)) {
				// Set rollback-only in case of Vavr failure matching our rollback rules...
				TransactionStatus status = txInfo.getTransactionStatus();
				if (status != null && txAttr != null) {
					retVal = VavrDelegate.evaluateTryFailure(retVal, txAttr, status);
				}
			}
//事务提交
			commitTransactionAfterReturning(txInfo);
			return retVal;
		}

		else {
			Object result;
			final ThrowableHolder throwableHolder = new ThrowableHolder();

			// It's a CallbackPreferringPlatformTransactionManager: pass a TransactionCallback in.
			try {
				result = ((CallbackPreferringPlatformTransactionManager) ptm).execute(txAttr, status -> {
					TransactionInfo txInfo = prepareTransactionInfo(ptm, txAttr, joinpointIdentification, status);
					try {
						Object retVal = invocation.proceedWithInvocation();
						if (retVal != null && vavrPresent && VavrDelegate.isVavrTry(retVal)) {
							// Set rollback-only in case of Vavr failure matching our rollback rules...
							retVal = VavrDelegate.evaluateTryFailure(retVal, txAttr, status);
						}
						return retVal;
					}
					catch (Throwable ex) {
						if (txAttr.rollbackOn(ex)) {
							// A RuntimeException: will lead to a rollback.
							if (ex instanceof RuntimeException) {
								throw (RuntimeException) ex;
							}
							else {
								throw new ThrowableHolderException(ex);
							}
						}
						else {
							// A normal return value: will lead to a commit.
							throwableHolder.throwable = ex;
							return null;
						}
					}
					finally {
						cleanupTransactionInfo(txInfo);
					}
				});
			}
			catch (ThrowableHolderException ex) {
				throw ex.getCause();
			}
			catch (TransactionSystemException ex2) {
				if (throwableHolder.throwable != null) {
					logger.error("Application exception overridden by commit exception", throwableHolder.throwable);
					ex2.initApplicationException(throwableHolder.throwable);
				}
				throw ex2;
			}
			catch (Throwable ex2) {
				if (throwableHolder.throwable != null) {
					logger.error("Application exception overridden by commit exception", throwableHolder.throwable);
				}
				throw ex2;
			}

			// Check result state: It might indicate a Throwable to rethrow.
			if (throwableHolder.throwable != null) {
				throw throwableHolder.throwable;
			}
			return result;
		}
	}
```

这个方法逻辑很清晰，一目了然，if里面就是对声明式事务的处理，先调用createTransactionIfNecessary方法开启事务，然后通过invocation.proceedWithInvocation调用下一个切面，
如果没有其它切面了，就是调用被代理类的方法，出现异常就回滚，否则提交事务，这就是Spring事务切面的执行过程。但是，我们主要要搞懂的就是在这些方法中是如何管理事务以及事务在多个方法之间是如何传播的。


## Spring 事务的扩展 – TransactionSynchronization

> 数据库的事务是基于连接的，Spring 对于多个数据库操作的事务实现是基于 ThreadLocal。所以在事务操作当中不能使用多线程

我们回到正题， Spring 通过创建事务信息(TransactionInfo)，把数据库连接通过 TransactionSynchronizationManager#bindResource 绑定到 ThreadLocal 变量当中。
然后标注到一个事务当中的其它数据库操作就可以通过TransactionSynchronizationManager#getResource 获取到这个连接。


## Spring 事务扩展 – @TransactionalEventListener
```java

```

```java

```

```java

```

```java

```

```java

```

```java

```

```java

```

```java

```

```java

```

## 总结
本篇详细分析了事务的传播原理，另外还有隔离级别，这在Spring中没有体现，需要我们自己结合数据库的知识进行分析设置。最后我们还需要考虑声明式事务和编程式事务的优缺点，声明式事务虽然简单，但不适合用在长事务中，
会占用大量连接资源，这时就需要考虑利用编程式事务的灵活性了。总而言之，事务的使用并不是一律默认就好，接口的一致性和吞吐量与事务有着直接关系，严重情况下可能会导致系统崩溃。

