# spring 事件



事件机制是Spring为企业级开发提供的神兵利器之一，它提供了一种低耦合、无侵入的解决方式，是我们行走江湖必备保命技能。但其实Spring事件的设计其实并不复杂，它由三部分组成：事件、发布器、监听器。事件是主体，发布器负责发布事件，监听器负责处理事件。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/d7a51c74bf644bde96569b97c743d4f5~noop.image?_iz=58558&from=article.pc_detail&x-expires=1670205544&x-signature=y2sbc4fPNjYG%2Fbr7jk7Tkxelzic%3D)



 在简单了解Spring事件的机制之后，本文将从源码的角度出发，和大家一起探讨：Spring事件的核心工作机制，并看一下作为企业级开发工具，Spring事件是如何支持全局异常处理和异步执行的。最后会和大家讨论目前Spring事件机制的一些缺陷和问题，话不多说，我们开始吧。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/d7ddfc247089491890b494c5f2ed118a~noop.image?_iz=58558&from=article.pc_detail&x-expires=1670205544&x-signature=JgWUMtPdrGbqLF8jLk8eIN3V%2Bl4%3D)



# 1. Spring事件如何使用

 所谓千里之行始于足下，在研究Spring的事件的机制之前，我们先来看一下Spring事件是如何使用的。通常情况下，我们使用自定义事件和内置事件，自定义事件主要是配合业务使用，自定义事件则多是做系统启动时的初始化工作或者收尾工作。

# 1.1 自定义事件的使用

- **定义自定义事件**

 自定义一个事件在使用上很简单，继承ApplicationEvent即可:

```
// 事件需要继承ApplicationEvent
public class MyApplicationEvent extends ApplicationEvent {
    private Long id;
    public MyApplicationEvent(Long id) {
        super(id);
        this.id = id;
    }

    public Long getId() {
        return id;
    }
}
```

- **发布自定义事件**
   现在自定义事件已经有了，该如何进行发布呢？Spring提供了ApplicationEventPublisher进行事件的发布，我们平常使用最多的ApplicationContext也继承了该发布器，所以我们可以直接使用applicationContext进行事件的发布。

```
// 发布MyApplicationEvent类型事件
applicationContext.publishEvent(new MyApplicationEvent(1L));
```

- **处理自定义事件**
   现在事件已经发布了，谁负责处理事件呢？当然是监听器了，Spring要求监听器需要实现ApplicationListener接口，同时需要通过泛型参数指定处理的事件类型。有了监听器需要处理的事件类型信息，Spring在进行事件广播的时候，就能找到需要广播的监听器了，从而准确传递事件了。

```
// 需要继承ApplicationListener，并指定事件类型
public class MyEventListener implements ApplicationListener<MyApplicationEvent> {
    // 处理指定类型的事件
    @Override
    public void onApplicationEvent(MyApplicationEvent event) {
        System.out.println(Thread.currentThread().getName() + "接受到事件:"+event.getSource());
    }
}
```

# 1.2 Spring内置事件

# 1.2.1 ContextRefreshedEvent

 在ConfigurableApplicationContext的refresh()执行完成时，会发出ContextRefreshedEvent事件。refresh()是Spring最核心的方法，该方法内部完成的Spring容器的启动，是研究Spring的重中之重。在该方法内部，当Spring容器启动完成，会在finishRefresh()发出ContextRefreshedEvent事件，通知容器刷新完成。我们一起来看一下源码：

```
// ConfigurableApplicationContext.java
public void refresh() throws BeansException, IllegalStateException {
    try {
        // ...省略部分非关键代码
        //完成普通单例Bean的实例化(非延迟的)
        this.finishBeanFactoryInitialization(beanFactory);

        // 初始化声明周期处理器,并发出对应的时间通知
        this.finishRefresh();
    }
}

protected void finishRefresh() {
    // ...省略部分非核心代码
    // 发布上下文已经刷新完成的事件
    this.publishEvent(new ContextRefreshedEvent(this));
}
```

 其实这是Spring提供给我们的拓展点，此时容器已经启动完成，容器中的bean也已经创建完成，对应的属性、init()、Aware回调等，也全部执行。很适合我们做一些系统启动后的准备工作，此时我们就可以监听该事件，作为系统启动后初始预热的契机。其实Spring内部也是这样使用ContextRefreshedEvent的， 比如我们常用的Spring内置的调度器，就是在接收到该事件后，才进行调度器的执行的。

```
public class ScheduledAnnotationBeanPostProcessor implements ApplicationListener<ContextRefreshedEvent> {
  	@Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
      if (event.getApplicationContext() == this.applicationContext) {
        finishRegistration();
      }
    }
}
```

# 1.2.2 ContextStartedEvent

 在ConfigurableApplicationContext的start()执行完成时，会发出ContextStartedEvent事件。

```
@Override
public void start() {
    this.getLifecycleProcessor().start();
    this.publishEvent(new ContextStartedEvent(this));
}
```

 ContextRefreshedEvent事件的触发是所有的单例bean创建完成后发布，此时实现了Lifecycle接口的bean还没有回调start()，当这些start()被调用后，才会发布ContextStartedEvent事件。

# 1.2.3 ContextClosedEvent

 在ConfigurableApplicationContext的close()执行完成时，会发出ContextStartedEvent事件。此时IOC容器已经关闭，但尚未销毁所有的bean。

```
@Override
public void close() {
    synchronized (this.startupShutdownMonitor) {
        this.doClose();
    }
}

protected void doClose() {
    // 发布ContextClosedEvent事件
    this.publishEvent(new ContextClosedEvent(this));
}
```

# 1.2.4 ContextStoppedEvent

 在ConfigurableApplicationContext的stop()执行完成时，会发出ContextStartedEvent事件。

```
@Override
public void stop() {
    this.getLifecycleProcessor().stop();
    this.publishEvent(new ContextStoppedEvent(this));
}
```

 该事件在ContextClosedEvent事件触发之后才会触发，此时单例bean还没有被销毁，要先把他们都停掉才可以释放资源，销毁bean。

# 2. Spring事件是如何运转的

 经过第一章节的探讨，我们已经清楚Spring事件是如何使用的，然而这只是皮毛而已，我们的目标是把Spring事件机制脱光扒净的展示给大家看。所以这一章节我们深入探讨一下，Spring事件的运行机制，重点我们看一下：

- 事件是怎么广播给监听器的？会不会发送阻塞?
- 系统中bean那么多，ApplicationListener是被如何识别为监听器的？
- 监听器处理事件的时候，是同步处理还是异步处理的？
- 处理的时候发生异常怎么办，后面的监听器还能执行吗？

 乍一看是不是问题还挺多，没事，不要着急，让我们一起来开启愉快的探索路程，看看Spring是怎么玩转事件的吧。

# 2.1 事件发布

 在第一章节，我们直接通过applicationContext发布了事件，同时也提到了，它之所以能发布事件，是因为它是ApplicationEventPublisher的子类，因此是具备事件发布能力的。但按照接口隔离原则，如果我们只需要进行事件发布，applicationContext提供的能力太多，还是推荐直接使用ApplicationEventPublisher进行操作。

# 2.1.1 获取事件发布器的方式

 我们先来ApplicationEventPublisher的提供的能力，它是一个接口，结构如下：

```
@FunctionalInterface
public interface ApplicationEventPublisher {
    //发布ApplicationEvent事件
    default void publishEvent(ApplicationEvent event) {
        publishEvent((Object) event);
    }

    //发布PayloadApplicationEvent事件
    void publishEvent(Object event);
}
```

 通过源码我们发现ApplicationEventPublisher仅仅提供了事件发布的能力，支持自定义类型和PayloadApplicationEvent类型(如果没有定义事件类型，默认包装为该类型)。那我们如何获取该发布器呢，我们最常使用的@Autowired注入是否可以呢，试一下呗。

- **通过@Autowired 注入 ApplicationEventPublisher**



![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/3c66ff78099747e694d12e58798bbc37~noop.image?_iz=58558&from=article.pc_detail&x-expires=1670205544&x-signature=5WgfAd5W3D7mfNiKkHNhVuqkExQ%3D)




 通过debug，我们可以直观的看到：是可以的，而且注入的就是ApplicationContext实例。也就是说注入ApplicationContext和注入ApplicationEventPublisher是等价的，都是一个ApplicationContext实例。

- **通过ApplicationEventPublisherAware获取 ApplicationEventPublisher**
   除了@Autowired注入，Spring还提供了使用ApplicationEventPublisherAware获取 ApplicationEventPublisher的方式，如果实现了这个感知接口，Spring会在合适的时机，回调setApplicationEventPublisher()，将applicationEventPublisher传递给我们。使用起来也很方便。代码所示：

```
public class UserService implements ApplicationEventPublisherAware {
    private ApplicationEventPublisher applicationEventPublisher;

    public void login(String username, String password){
        // 1： 进行登录处理
        ...
        // 2： 发送登录事件，用于记录操作
        applicationEventPublisher.publishEvent(new UserLoginEvent(userId));
    }

    // Aware接口回调注入applicationEventPublisher
    @Override
    public void setApplicationEventPublisher(ApplicationEventPublisher applicationEventPublisher) {
            this.applicationEventPublisher = applicationEventPublisher;
    }
}
```

 现在我们已经知道通过@Autowired和ApplicationEventPublisherAware回调都能获取到事件发布器，两种有什么区别吗? 其实区别不大，主要是调用时机的细小差别，另外就是默写特殊场景下，@Autowired注入可能无法正常注入，实际开发中完成可以忽略不计。所以优先推荐小伙伴们使用ApplicationEventPublisherAware，如果觉得麻烦，使用@Autowired也未尝不可。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/e10519e391b149a49bb279492d7352bc~noop.image?_iz=58558&from=article.pc_detail&x-expires=1670205544&x-signature=ga5X4OcXgrLCce1PF8x5y8CCMeg%3D)



> 如果使是自动注入模型，是无法通过setter()注入ApplicationEventPublisher的，因为在prepareBeanFactory时已经指定忽略此接口的注入了(
> beanFactory.ignoreDependencyInterface(ApplicationEventPublisherAware.class))。顺便说一句，@Autowired不算自动注入哦。

# 2.1.2 事件的广播方式

 现在我们已经知道，可以通过ApplicationEventPublisher发送事件了，那么这个事件发送后肯定是要分发给对应的监听器处理啊，谁处理这个分发逻辑呢？又是怎么匹配对应的监听器的呢？我们带着这两个问题来看ApplicationEventMulticaster。

- **事件是如何广播的**
   要探查事件是如何广播的，需要跟随事件发布后的逻辑一起看一下：

```
@Override
public void publishEvent(ApplicationEvent event) {
    this.publishEvent(event, null);
}

protected void publishEvent(Object event, @Nullable ResolvableType eventType) {
    // ...省略部分代码
    if (this.earlyApplicationEvents != null) {
      this.earlyApplicationEvents.add(applicationEvent);
    }
    else {
      // 将事件广播给Listener
      this.getApplicationEventMulticaster().multicastEvent(applicationEvent, eventType);
    }
}

// 获取事件广播器
ApplicationEventMulticaster getApplicationEventMulticaster() throws IllegalStateException {
    if (this.applicationEventMulticaster == null) {
      throw new IllegalStateException("ApplicationEventMulticaster not initialized - " +
                                      "call 'refresh' before multicasting events via the context: " + this);
    }
    return this.applicationEventMulticaster;
}
```

 通过上面源码，我们发现发布器直接把事件转交给applicationEventMulticaster了，我们再去里面看一下广播器里面做了什么。

```
// SimpleApplicationEventMulticaster.java
public void multicastEvent(final ApplicationEvent event, @Nullable ResolvableType eventType) {
    // ...省略部分代码
    // getApplicationListeners 获取符合的监听器
    for (ApplicationListener<?> listener : getApplicationListeners(event, type)) {
        // 执行每个监听器的逻辑
        invokeListener(listener, event);
    }
}

private void doInvokeListener(ApplicationListener listener, ApplicationEvent event) {
    try {
      // 调用监听器的onApplicationEvent方法进行处理
      listener.onApplicationEvent(event);
    }
}
```

 看到这里，我们发现事件的分发逻辑：先找到匹配的监听器，然后逐个调用onApplicationEvent()进行事件处理。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/6401a2527a394136a80475243cf04c73~noop.image?_iz=58558&from=article.pc_detail&x-expires=1670205544&x-signature=k%2BNuech6yGhXUMbTkjK1lBxb8FI%3D)



- **事件和监听器是如何匹配的**
   通过上述源码，我们发现通过getApplicationListeners(event, type)找到了所有匹配的监听器，我们继续跟踪看一下是如何匹配的。

```
protected Collection<ApplicationListener<?>> getApplicationListeners(
      ApplicationEvent event, ResolvableType eventType) {
   // 省略缓存相关代码
   return retrieveApplicationListeners(eventType, sourceType, newRetriever);
}


private Collection<ApplicationListener<?>> retrieveApplicationListeners(
ResolvableType eventType, @Nullable Class<?> sourceType, @Nullable CachedListenerRetriever retriever) {
    // 1: 获取所有的ApplicationListener
    Set<ApplicationListener<?>> listeners;
    Set<String> listenerBeans;
    synchronized (this.defaultRetriever) {
        listeners = new LinkedHashSet<>(this.defaultRetriever.applicationListeners);
        listenerBeans = new LinkedHashSet<>(this.defaultRetriever.applicationListenerBeans);
    }

    for (ApplicationListener<?> listener : listeners) {
        // 2: 遍历判断是否匹配
        if (supportsEvent(listener, eventType, sourceType)) {
            if (retriever != null) {
                filteredListeners.add(listener);
            }
            allListeners.add(listener);
        }
    }
}

protected boolean supportsEvent(
  ApplicationListener<?> listener, ResolvableType eventType, @Nullable Class<?> sourceType) {
  GenericApplicationListener smartListener = (listener instanceof GenericApplicationListener ?
                                              (GenericApplicationListener) listener : new GenericApplicationListenerAdapter(listener));
  // supportsEventType 根据ApplicationListener的泛型, 和事件类型,看是否匹配
  // supportsSourceType 根据事件源类型，判断是否匹配
  return (smartListener.supportsEventType(eventType) && smartListener.supportsSourceType(sourceType));
}
```

 通过源码跟踪，我们发现监听器匹配是根据事件类型匹配的，先获取容器中所有的监听器，在用supportsEvent()去判断对应的监听器是否匹配事件。这里匹配主要看两点：

1. 判断事件类型和监听器上的泛型类型，是否匹配(子类也能匹配)。
2. 监听器是否支持事件源类型，默认情况下，都是支持的。
   如果两者都匹配，就转发给处理器处理。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/2e0e28cbf1884b4782a78a2508822ac3~noop.image?_iz=58558&from=article.pc_detail&x-expires=1670205544&x-signature=YI21R0ZAibpiUHwju0ocuTJrnhw%3D)



- **ApplicationEventMulticaster是如何获取的（选读）**
   在事件广播时，Spring直接调用getApplicationEventMulticaster()去获取属性applicationEventMulticaster，并且当applicationEventMulticaster为空时，直接异常终止了。那么就要求该成员变量提早初始化，那么它是何时初始化的呢。

```
public void refresh() throws BeansException, IllegalStateException {
    // ...省略无关代码
    // 初始化事件广播器(转发ApplicationEvent给对应的ApplicationListener处理)
    this.initApplicationEventMulticaster();
}

protected void initApplicationEventMulticaster() {
    ConfigurableListableBeanFactory beanFactory = this.getBeanFactory();
    // spring容器中存在，直接返回
    if (beanFactory.containsLocalBean(APPLICATION_EVENT_MULTICASTER_BEAN_NAME)) {
        this.applicationEventMulticaster =
      beanFactory.getBean(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, ApplicationEventMulticaster.class);
        if (this.logger.isTraceEnabled()) {
            this.logger.trace("Using ApplicationEventMulticaster [" + this.applicationEventMulticaster + "]");
        }
    }
    else {
        // 容器中不存在，创建SimpleApplicationEventMulticaster，放入容器
        this.applicationEventMulticaster = new SimpleApplicationEventMulticaster(beanFactory);
        beanFactory.registerSingleton(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, this.applicationEventMulticaster);
        if (this.logger.isTraceEnabled()) {
            this.logger.trace("No '" + APPLICATION_EVENT_MULTICASTER_BEAN_NAME + "' bean, using " +
                                "[" + this.applicationEventMulticaster.getClass().getSimpleName() + "]");
        }
    }
}
复制代码
```

 看到这里，是不是豁然开朗，原来在容器启动的时候，专门调用了initApplicationEventMulticaster()对applicationEventMulticaster进行了初始化，并放到了spring容器中。

> 其实这里还有个问题，就是事件整体的初始化流程在BeanFactoryPostProcessor之后，如果在自定义的BeanFactoryPostProcessor发布事件，此时
> applicationEventMulticaster还没有初始化，监听器也没有注册，是无法进行事件的广播的。该问题在Spring3之前普遍存在，在最近的版本已经解决，其思路是：先将早期事件放入集合中，待广播器、监听器注册后，再从集合中取出进行广播。

# 2.2 事件监听器

 监听器是负责处理事件的，在广播器将对应的事件广播给它之后，它正式上岗开始处理事件。Spring默认的监听器是同步执行的，并且支持一个事件由多个监听器处理，并可通过@Order指定监听器处理顺序。

# 2.2.1 定义监听器的方式

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/28c0e7c491234132a4617ba8f326d5d3~noop.image?_iz=58558&from=article.pc_detail&x-expires=1670205544&x-signature=yZ8jQF2B5K11mCSv6LI5rFeNK1g%3D)



- **实现ApplicationListener定义监听器**
   第一种方式定义的方式当然是通过直接继承ApplicationListener，同时不要忘记通过泛型指定事件类型，它可是将事件广播给监听器的核心匹配标志。

```
public class MyEventListener implements ApplicationListener<MyApplicationEvent> {
    @Override
    public void onApplicationEvent(MyApplicationEvent event) {
            System.out.println(Thread.currentThread().getName() + "接受到事件:"+event.getSource());
    }
}
```

> 通过ApplicationListener定义的监听器，本质上是一个单事件监听器，也就是只能处理一种类型的事件。

- **使用@EventListener定义监听器**
   第二种方式我们还可以使用@EventListener标注方法为监听器，该注解标注的方法上，方法参数为事件类型，标注该监听器要处理的事件类型。

```
public class AnnotationEventListener {
    // 使用@EventListener标注方法为监听器，参数类型为事件类型
    @EventListener
    public void onApplicationEvent(MyApplicationEvent event) {
        System.out.println(Thread.currentThread().getName() + "接受到事件:"+event.getSource());
    }

    @EventListener
    public void onApplicationEvent(PayloadApplicationEvent payloadApplicationEvent) {
        System.out.println(Thread.currentThread().getName() + "接受到事件:"+payloadApplicationEvent.getPayload());
    }
}
```

> 通过广播器分发事件的逻辑，我们知道事件只能分发给ApplicationListener类型的监听器实例处理，这里仅仅是标注了@EventListener的方法，也能被是识别成ApplicationListener类型的监听器吗？答案是肯定的，只是Spring在底层进行了包装，偷偷把@EventListener标注的方法包装成了
> ApplicationListenerMethodAdapter，它也是ApplicationListener的子类，这样就成功的把方法转换成ApplicationListener实例了，后续章节我们会详细揭露Spring偷梁换柱的小把戏，小伙伴们稍安勿躁。

# 2.2.2 ApplicationListener监听器是如何被识别的

 本小节我们一起看一下监听器是如何被是识别的，毕竟大多数情况下，我们只是直接加了@Component注解，然后实现了一下ApplicationListener接口，并没有特殊指定为监听器。那有没有可能就是基于这个继承关系，Spring自己在容器中进行类型查找呢？

```
public void refresh() throws BeansException, IllegalStateException {
  try {
    // ...省略部分代码
    // 初始化各种监听器
    this.registerListeners();
  }
}

// 注册监听器
protected void registerListeners() {
  // 1: 处理context.addApplicationListener(new MyEventListener()) 方式注册的监听器，并将监听器注册到广播器中，
  for (ApplicationListener<?> listener : this.getApplicationListeners()) {
    this.getApplicationEventMulticaster().addApplicationListener(listener);
  }

  // 2: 去Spring容器中获取监听器（处理扫描的或者register方式注册的）,同样也是添加到广播器中
  String[] listenerBeanNames = this.getBeanNamesForType(ApplicationListener.class, true, false);
  for (String listenerBeanName : listenerBeanNames) {
    this.getApplicationEventMulticaster().addApplicationListenerBean(listenerBeanName);
  }
}
复制代码
```

 通过上述源码跟踪，我们发现原来在容器refresh()的时候，专门有个步骤是用来初始化各种监听器的。它的具体实现是：先把通过addApplicationListener()直接指定的注册为监听器 -> 再通过类型查找，把当做普通bean注册到容器中，类似是ApplicationListener的找了出来 -> 缓存到ApplicationEventMulticaster中的监听器集合中了。一路跟踪下来，确实是根据类型查找的，和我们的猜想完全一致。

# 2.2.3 @EventListener标注的处理器是如何识别注册的

 本小节我们探究一下，标注了@EventListener的方法是如何被包装成ApplicationListener实例的。我们直接从源码入手，Spring在实例化bean后，调用了afterSingletonsInstantiated()对@EventListener的方法进行了保证，我们一起看一下。

```
public void refresh() throws BeansException, IllegalStateException {
  try {
    // ...省略部分代码
    //完成普通单例Bean的实例化(非延迟的)
    this.finishBeanFactoryInitialization(beanFactory);
    // ...省略部分代码
  }
}

protected void finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory) {
    // ...省略部分代码
    // 初始化非延迟加载的单例bean
    beanFactory.preInstantiateSingletons();
}

@Override
public void preInstantiateSingletons() throws BeansException {
    List<String> beanNames = new ArrayList<>(this.beanDefinitionNames);
    // 1: 完成bean的实例化
    for (String beanName : beanNames) {
        //通过beanName获取bean,bean不存在会创建bean
        getBean(beanName);
    }
    
    // 2: 调用bean的后置处理方法
    for (String beanName : beanNames) {
        // ...省略部分代码
        // 调用到EventListenerMethodProcessor的afterSingletonsInstantiated()，完成@EventListener的方法的转换注册
        smartSingleton.afterSingletonsInstantiated();
    }
}

// EventListenerMethodProcessor.java
public void afterSingletonsInstantiated() {
    // ...省略部分代码
    for (String beanName : beanNames) {
        // ...省略部分代码
        processBean(beanName, type);
    }
}

private void processBean(final String beanName, final Class<?> targetType) {
    // 1: 解析bean上加了@EventListener的方法
    Map<Method, EventListener> annotatedMethods = null;
    try {
        annotatedMethods = MethodIntrospector.selectMethods(targetType,
                        (MethodIntrospector.MetadataLookup<EventListener>) method ->
        AnnotatedElementUtils.findMergedAnnotation(method, EventListener.class));
    }
    
    // ...省略部分代码
    // 2: 遍历加了@EventListener的方法，注册为事件监听器
    for (Method method : annotatedMethods.keySet()) {
        for (EventListenerFactory factory : factories) {
            if (factory.supportsMethod(method)) {
                Method methodToUse = AopUtils.selectInvocableMethod(method, context.getType(beanName));
                // 2.1 通过EventListenerFactory，将方法创建为监听器实例(ApplicationListenerMethodAdapter)
                ApplicationListener<?> applicationListener = factory.createApplicationListener(beanName, targetType, methodToUse);
                if (applicationListener instanceof ApplicationListenerMethodAdapter) {
                        ((ApplicationListenerMethodAdapter) applicationListener).init(context, this.evaluator);
                }
                // 2.2 注册为ApplicationListener
                context.addApplicationListener(applicationListener);
                break;
            }
        }
    }
    // ...省略部分代码
}
```

 我们整理一下调用关系：refresh() -> finishBeanFactoryInitialization(beanFactory) -> beanFactory.preInstantiateSingletons() -> eventListenerMethodProcessor.afterSingletonsInstantiated() -> eventListenerMethodProcessor.processBean()；在容器中所有的bean实例化后，会再次遍历遍历所有bean，调用SmartInitializingSingleton类型的bean的afterSingletonsInstantiated()的方法，此时符合条件的EventListenerMethodProcessor就会被调用，进而通过processBean()，先找出标注了@EventListener的方法，然后遍历这些方法，通过EventListenerFactory工厂，包装方法为EventListener实例，最后在注册到容器中。至此，完成了查找，转换的过程。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/204d36cb6a914abe96768ba5aea70bbb~noop.image?_iz=58558&from=article.pc_detail&x-expires=1670205544&x-signature=nh0RhkIsAUiKcLdsAlbMyiFimCs%3D)



> 关于@EventListener标注方法的解析时机，笔者首先想到的应该和@Bean的处理时机一致，在扫描类的时候，就解析出来加了@EventListener的方法，抽象为BeanDefinition放到容器中，后面实例化时候，和正常扫描出来的bean是一样的实例化流程。但是查找下来发现Spring并没有这样处理，而是在bean初始化后回调阶段处理的。究其原因，大概是@Bean真的是需要托付给Spring管理，而@EventListener只是一个标识，无需放入放入容器，防止对完暴露所致吧。

- **EventListenerMethodProcessors是如何注册的**
   通过上述的源码分析，我们清楚对于@EventListener的方法的处理，EventListenerMethodProcessor可谓是至关重要，那么他是怎么注册到Spring中的。而且我们也没有通过@EnableXXX进行开启啊。其实Spring除了管理我们定义的bean，还会有一些内置的bean，来承接一些Spring核心工作，这些内置的bean一般在application容器创建的时候，就放入到Spring容器中了。下面我们来看一下是不是这样：

```
// 构造方法
public AnnotationConfigApplicationContext() {
    // 1: 初始化BeanDefinition渲染器，注册一下Spring内置的BeanDefinition
    this.reader = new AnnotatedBeanDefinitionReader(this);
    this.scanner = new ClassPathBeanDefinitionScanner(this);
}

// AnnotatedBeanDefinitionReader.java
public class AnnotatedBeanDefinitionReader {
    public AnnotatedBeanDefinitionReader(BeanDefinitionRegistry registry, Environment environment) {
        // ...省略部分代码
        // 注册一些内置后置处理器的BeanDefinition,是spring这两个最核心的功能类
        AnnotationConfigUtils.registerAnnotationConfigProcessors(this.registry);
    }
}


// AnnotationConfigUtils.java
public static Set<BeanDefinitionHolder> registerAnnotationConfigProcessors(
                BeanDefinitionRegistry registry, @Nullable Object source) {
    // ...省略部分代码
    // 注册EventListenerMethodProcessor
    if (!registry.containsBeanDefinition(EVENT_LISTENER_PROCESSOR_BEAN_NAME)) {
        RootBeanDefinition def = new RootBeanDefinition(EventListenerMethodProcessor.class);
        def.setSource(source);
        beanDefs.add(registerPostProcessor(registry, def, EVENT_LISTENER_PROCESSOR_BEAN_NAME));
    }
}
```

# 2.3 异步处理事件

 通过上面的分析，我们知道事件在广播时是同步执行的，广播流程为：先找到匹配的监听器 -> 逐个调用onApplicationEvent()进行事件处理，整个过程是同步处理的。下面我们做一个测试验证一下：

```
public void applicationListenerTest(){
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext();
    context.register(AnnotationEventListener.class);
    context.refresh();
    System.out.printf("线程:[%s],时间:[%s],开始发布事件\n", new Date(), Thread.currentThread().getName());
    context.publishEvent(new MyApplicationEvent(1L));
    System.out.printf("线程:[%s],时间:[%s],发布事件完成\n", new Date(), Thread.currentThread().getName());
    context.stop();
}

public class AnnotationEventListener {
    @EventListener
    @Order(1)
    public void onApplicationEvent(MyApplicationEvent event) {
        Date start = new Date();
        Thread.sleep(3000);
        System.out.printf("线程:[%s],监听器1,接收时间:[%s],处理完成时间:[%s],接收到事件:%s\n", Thread.currentThread().getName(), start, new Date(), event.getSource());
    }

    @EventListener
    @Order(2)
    public void onApplicationEvent2(MyApplicationEvent event) {
        Date start = new Date();
        System.out.printf("线程:[%s],监听器2,接收时间:[%s],处理完成时间:[%s],接收到事件:%s\n", Thread.currentThread().getName(), start, new Date(), event.getSource());
    }
}

// 输出信息:
// 线程:[main],时间[22:59:24],开始发布事件
// 线程:[main],监听器1,接收时间:[22:59:24]，处理完成时间:[22:59:27],接收到事件:1
// 线程:[main],监听器1,接收时间:[22:59:27]，处理完成时间:[22:59:27],接收到事件:1
// 线程:[main],时间[22:59:27],，发布事件完成
```

 通过上述示例代码，发现确实是同步调用的，处理线程都是main，监听器1处理缓慢，监听器2只能默默等待监听器1处理后才能接收到事件。这能满足我们的需求吗，毕竟现在系统动辄就要求毫秒计返回，QPS没有1000+你都不好意思出门，哪怕只有十个用户。

 除了性能问题，我们基于真实业务场景出发，考虑一下什么场景下，我们使用事件比较合适。个人使用最多的场景是：在执行某个业务时，需要通知别的业务方，该业务的执行情况时，会使用事件机制进行通知。就拿这个场景来说，我们考虑几个问题：

1. 我们是否关心监听者的执行时机？
2. 我们是否关心监听者的执行结果？

 大多数情况下，其实我们并不关心的监听者什么时候执行，执行结果如何的。如果对执行结果有依赖，通常直接调用了，如果有可能，还能享受事务的便利，还借助事件干什么呢。所以这里其实有个需求，希望Spring事件的处理是异步的，那如何实现呢？

# 2.3.1 通过注入taskExecutor，异步处理事件

 通过前文的分析，我们知道事件的广播是由ApplicationEventMulticaster进行处理的，那我们去看看，是否支持异步处理呢。

```
@Override
public void multicastEvent(final ApplicationEvent event, @Nullable ResolvableType eventType) {
    // 获取执行线程池
    Executor executor = getTaskExecutor();
    for (ApplicationListener<?> listener : getApplicationListeners(event, type)) {
        // 如果存在线程池，使用线程池异步执行
        if (executor != null) {
            executor.execute(() -> invokeListener(listener, event));
        }
        // 如果不存在线程池，同步执行
        else {
            invokeListener(listener, event);
        }
    }
}

// 获取线程池
protected Executor getTaskExecutor() {
    return this.taskExecutor;
}

// 设置线程池
public void setTaskExecutor(@Nullable Executor taskExecutor) {
    this.taskExecutor = taskExecutor;
}
```

 通过源码我们发现，其实Spring提供了使用线程池异步执行的逻辑，前提是需要先设置线程池，只是这里设置线程池的方式稍微麻烦些，需要通过applicationEventMulticaster实例的setTaskExecutor()设置，下面我们试一下是否可行。

```
public void applicationListenerTest(){
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext();
    context.register(AnnotationEventListener.class);
    context.refresh();
    ApplicationEventMulticaster multicaster = context.getBean(AbstractApplicationContext.APPLICATION_EVENT_MULTICASTER_BEAN_NAME, ApplicationEventMulticaster.class);
    if (multicaster instanceof SimpleApplicationEventMulticaster) {
        ((SimpleApplicationEventMulticaster) multicaster).setTaskExecutor(Executors.newFixedThreadPool(10));
    }
    System.out.printf("线程:[%s],时间:[%s],开始发布事件\n", new Date(), Thread.currentThread().getName());
    context.publishEvent(new MyApplicationEvent(1L));
    System.out.printf("线程:[%s],时间:[%s],发布事件完成\n", new Date(), Thread.currentThread().getName());
    context.stop();
}

public class AnnotationEventListener {
    @EventListener
    @Order(1)
    public void onApplicationEvent(MyApplicationEvent event) {
        Date start = new Date();
        Thread.sleep(3000);
        System.out.printf("线程:[%s],监听器1,接收时间:[%s],处理完成时间:[%s],接收到事件:%s\n", Thread.currentThread().getName(), start, new Date(), event.getSource());
    }

    @EventListener
    @Order(2)
    public void onApplicationEvent2(MyApplicationEvent event) {
        Date start = new Date();
        System.out.printf("线程:[%s],监听器2,接收时间:[%s],处理完成时间:[%s],接收到事件:%s\n", Thread.currentThread().getName(), start, new Date(), event.getSource());
    }
}

// 输出信息:
// 线程:[main],时间[22:57:13],开始发布事件
// 线程:[main],时间[22:57:13],，发布事件完成
// 线程:[pool-2-thread-1],监听器2,接收时间:[22:57:13]，处理完成时间:[22:57:13],接收到事件:1
// 线程:[pool-2-thread-2],监听器1,接收时间:[22:57:13]，处理完成时间:[22:57:16],接收到事件:1
```

 经过测试发现：设置了线程池之后，监听器确实是异步执行的，并且是全局生效，对所有类型的监听器都适用。只是这里的设置稍显不便，需要先获取到applicationEventMulticaster这个bean之后，再使用内置方法设置。

# 2.3.2 使用@Async，异步处理事件

 通过注入线程池，是全局生效的。如果我们项目中有些事件需要异步处理，又有些事件需要同步执行的，怎么办，总不能告诉你的leader做不了吧。NO，那不是显得我很没有用。面对这种情况，我们可以借助@Async注解，使单个监听器异步执行。我们测试一下：

```
// 使用@EnableAsync开启异步
@EnableAsync
public class AnnotationEventListener {

    @EventListener
    @Order(1)
    public void onApplicationEvent(MyApplicationEvent event) {
        Date start = new Date();
        Thread.sleep(3000);
        System.out.printf("线程:[%s],监听器1,接收时间:[%s],处理完成时间:[%s],接收到事件:%s\n", Thread.currentThread().getName(), start, new Date(), event.getSource());
    }

    @EventListener
    @Order(2)
    public void onApplicationEvent2(MyApplicationEvent event) {
        Date start = new Date();
        Thread.sleep(1000);
        System.out.printf("线程:[%s],监听器2,接收时间:[%s],处理完成时间:[%s],接收到事件:%s\n", Thread.currentThread().getName(), start, new Date(), event.getSource());
    }
}

// 输出信息:
// 线程:[main],时间[23:18:32],开始发布事件
// 线程:[main],监听器1,接收时间:[23:18:32]，处理完成时间:[23:18:35],接收到事件:1
// 线程:[main],时间[23:18:35],，发布事件完成
// 线程:[SimpleAsyncTaskExecutor-1],监听器2,接收时间:[23:18:35]，处理完成时间:[23:18:36],接收到事件:1
```

 经过测试发现：在@Async的加持下，确实可以控制某个监听器异步执行。其实@Async也是使用了线程池执行的，对@Async感兴趣的同学可以自行查阅资料，这里我们不做展开了。

![img](https://p3-sign.toutiaoimg.com/tos-cn-i-qvj2lq49k0/f0af2a8e821242468862490af3b8efdc~noop.image?_iz=58558&from=article.pc_detail&x-expires=1670205544&x-signature=7yk9gZcei65UFV6XZS7Qcz1dVw4%3D)



# 2.4 全局异常处理

 通过我们长时间的啰嗦，聪明的你肯定清楚：Spring事件的处理，默认是同步依次执行。那如果前面的监听器出现了异常，并且没有处理异常，会对后续的监听器还能顺利接收该事件吗？其实不能的，因为异常中断了事件的发送了，这里我们不做演示了，有兴趣的同学们可以自行验证一下。

> 那如果我们设置了异步执行呢，还会有影响吗，对线程池有所了解的同学肯定可以给出答案：不会，因为不是一个线程执行，是不会互相影响的。

 难道同步执行我们就要在每个监听器都try catch一下，避免相互影响吗，不能全局处理吗？当前可以了，贴心的Spring为了简化我们的开发逻辑，特意提供了ErrorHandler来统一处理，话不多说，我们赶紧来试一下吧。

```
public class AnnotationEventListener {

    @EventListener
    @Order(1)
    public void onApplicationEvent(MyApplicationEvent event) {
        Date start = new Date();
        // 制造异常
        int i = 1/0;
        System.out.printf("线程:[%s],监听器1,接收时间:[%s],处理完成时间:[%s],接收到事件:%s\n", Thread.currentThread().getName(), start, new Date(), event.getSource());
    }

    @EventListener
    @Order(2)
    public void onApplicationEvent2(MyApplicationEvent event) {
        Date start = new Date();
        System.out.printf("线程:[%s],监听器2,接收时间:[%s],处理完成时间:[%s],接收到事件:%s\n", Thread.currentThread().getName(), start, new Date(), event.getSource());
    }
}

// 测试方法
public void applicationListenerTest() throws InterruptedException {
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext();
    context.register(AnnotationEventListener.class);
    context.refresh();
    ApplicationEventMulticaster multicaster = context.getBean(AbstractApplicationContext.APPLICATION_EVENT_MULTICASTER_BEAN_NAME, ApplicationEventMulticaster.class);
    if (multicaster instanceof SimpleApplicationEventMulticaster) {
      	// 简单打印异常信息
      	((SimpleApplicationEventMulticaster) multicaster).setErrorHandler(t -> System.out.println(t));
    }
   System.out.printf("线程:[%s],时间:[%s],开始发布事件\n", new Date(), Thread.currentThread().getName());
    context.publishEvent(new MyApplicationEvent(1L));
    System.out.printf("线程:[%s],时间:[%s],发布事件完成\n", new Date(), Thread.currentThread().getName());
    context.stop();
}

// 输出信息:
// 线程:[main],时间[23:35:15],开始发布事件
// java.lang.ArithmeticException: / by zero
// 线程:[main],监听器2,接收时间:[23:35:15]，处理完成时间:[23:35:15],接收到事件:1
// 线程:[main],时间[23:35:15],，发布事件完成
```

 经过测试发现：设置了ErrorHandler之后，确实可以对异常进行统一的管理了，再也不用繁琐的try catch了，今天又多了快乐划水五分钟的理由呢。老规矩，我们不光要做到知其然，还要做到知其所以然，我们探究一下为什么加了ErrorHandler之后，就可以全局处理呢？

```
protected void invokeListener(ApplicationListener<?> listener, ApplicationEvent event) {
    // 获取ErrorHandler
    ErrorHandler errorHandler = getErrorHandler();
    // 如果ErrorHandler存在，监听器执行出现异常，交给errorHandler处理，不会传递向上抛出异常。
    if (errorHandler != null) {
        try {
            doInvokeListener(listener, event);
        }
        catch (Throwable err) {
            errorHandler.handleError(err);
        }
    }
    else {
        // 调用监听器处理
        doInvokeListener(listener, event);
    }
}
```

 经过阅读源码，我们发现：Sring先查找是否配置了ErrorHandler，如果配置了，在发生异常的时候，把异常信息转交给errorHandler处理，并且不会在向上传递异常了。这样可以达到异常全局处理的效果了。

# 3. Spring事件机制存在什么问题

# 3.1 发布阻塞

 Spring发布事件的时候，由applicationEventMulticaster来处理分发逻辑，这是单线程处理，处理逻辑我们分析过，就是：找到事件对应的监听器(有缓存) -> 逐个分发给监听器处理(默认同步，可异步)。我们考虑一下这种设计会不会有性能问题了？同步执行的情况我们就不讨论了，对应的场景一定是事件发生频率较低，这种场景讨论性能没有意义。

 我们主要讨论异步模式，无论是@Async还是注入线程池，本质都是：通过线程池执行，并且线程池的线程是所有监听器共同使用的(@Async对应的线程池供所有加了@Async的方法使用)。我们都清楚线程池的执行流程：先创建线程执行任务，之后会放到缓冲队列，最后可能直接拒绝。

 基于共享线程池执行的监听器的模式，有什么问题呢？最严重的问题就是：监听器的执行速度会互相影响、甚至会发生阻塞。假如某一个监听器执行的很慢，把线程池中线程都占用了，此时其他的事件虽然发布但没有资源执行，只能在缓存队列等待线程释放，哪怕该事件的处理很快、很重要，也不行。

 其实这里可以参考Netty的boss-work工作模型，广播器只负责分发事件，调度执行监听器的逻辑交给由具体的work线程负责会更合适。

# 3.2 无法订制监听器执行线程数

 正是由于每种事件产生的数量、处理逻辑、处理速度差异化可能很大，所以每个监听器都有适合自己场景的线程数，所以为每个监听器配置线程池就显得尤为重要。Spring事件机制，无法单独为事件(或者监听器)设置线程池，只能共用线程池，无法做到精准控制，线程拥堵或者线程浪费出现的几率极大。当然，我们也可以在监听器内部，接收到事件后使用自定义的线程池处理，但是我们更希望简单化配置就能支持

 关于Spring事件机制存在的问题，笔者在项目中借助内存队列Disruptor存储事件，采用双总线的思想实现自研项目event-bus，解决了Spring事件机制不完美的部分。后续有机会再和大家分享该项目的详细情况。