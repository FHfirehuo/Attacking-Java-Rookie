# bootstrap



## 说明

bootstrap.properties其实是属于spring-cloud的一个环境配置。

需要添加cloud相关的MAVEN包，否则不会加载bootstrap.properties。

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-context</artifactId>
    <version>2.0.1.RELEASE</version>
</dependency>
```

## 加载顺序

SpringBoot中有以下两种配置文件bootstrap (.yml 或者 .properties)，application (.yml 或者 .properties)

### 加载顺序上的区别
1. bootstrap.yml（bootstrap.properties）先加载
2. application.yml（application.properties）后加载
3. bootstrap.yml 用于应用程序上下文的引导阶段，由父Spring ApplicationContext加载。父ApplicationContext 被加载到使用application.yml的之前。
4. bootstrap.yml 里面的属性会优先加载，它们默认也不能被本地相同配置覆盖

## 作用

在 Spring Boot 中有两种上下文，一种是 bootstrap, 另外一种是 application, bootstrap 是应用程序的父上下文，也就是说 bootstrap.yml  加载优先于 application.yml 。

bootstrap.yml（bootstrap.properties）用来**引导程序执行**，应用于更加早期配置信息读取，如可以使用来配置application.yml中使用到参数等

application.yml（application.properties) 应用程序特有配置信息，可以用来配置后续各个模块中需使用的公共参数等。

bootstrap 主要用于从额外的资源来加载配置信息，还可以在本地外部配置文件中解密属性。这两个上下文共用一个环境，它是任何Spring应用程序的外部属性的来源。

### 应用

1. bootstrap.yml 和application.yml 都可以用来配置参数。
2. bootstrap.yml 可以理解成系统级别的一些参数配置，这些参数一般是不会变动的。
3. application 配置文件这个容易理解，application.yml 可以用来定义应用级别的，主要用于 Spring Boot 项目的自动化配置
4. bootstrap 配置文件有以下几个应用场景。
   * 使用 Spring Cloud Config 配置中心时，这时需要在 bootstrap 配置文件中添加连接到配置中心的配置属性来加载外部配置中心的配置信息；
   * 一些固定的不能被覆盖的属性
   * 一些加密/解密的场景

## 实现

bootstrap.properties文件加载是由org.springframework.cloud.bootstrap.BootstrapApplicationListener在收到ApplicationEnvironmentPreparedEvent的时间时进行处理的。

```java
@Override
	public void onApplicationEvent(ApplicationEnvironmentPreparedEvent event) {
		ConfigurableEnvironment environment = event.getEnvironment();
		if (!bootstrapEnabled(environment) && !useLegacyProcessing(environment)) {
			return;
		}
		// don't listen to events in a bootstrap context
		if (environment.getPropertySources().contains(BOOTSTRAP_PROPERTY_SOURCE_NAME)) {
			return;
		}
		ConfigurableApplicationContext context = null;
		String configName = environment.resolvePlaceholders("${spring.cloud.bootstrap.name:bootstrap}");
		for (ApplicationContextInitializer<?> initializer : event.getSpringApplication().getInitializers()) {
			if (initializer instanceof ParentContextApplicationContextInitializer) {
				context = findBootstrapContext((ParentContextApplicationContextInitializer) initializer, configName);
			}
		}
		if (context == null) {
			context = bootstrapServiceContext(environment, event.getSpringApplication(), configName);
			event.getSpringApplication().addListeners(new CloseContextOnFailureApplicationListener(context));
		}

		apply(context, event.getSpringApplication(), environment);
	}
```



在bootstrapServiceContext函数中会设置环境变量属性spring.config.name为bootStrap，然后会创建一个web-application-type为NULL的注解application,这个容器为springcloud生成的容器，到时会作为springboot的父容器，BEAN对象可以共享。application创建成功后，会合并属性对象。

```java
private ConfigurableApplicationContext bootstrapServiceContext(ConfigurableEnvironment environment,
			final SpringApplication application, String configName) {
		ConfigurableEnvironment bootstrapEnvironment = new AbstractEnvironment() {
		};
		MutablePropertySources bootstrapProperties = bootstrapEnvironment.getPropertySources();
		String configLocation = environment.resolvePlaceholders("${spring.cloud.bootstrap.location:}");
		String configAdditionalLocation = environment
				.resolvePlaceholders("${spring.cloud.bootstrap.additional-location:}");
  	
  	// bootstrapMap设置父容器的属性
		Map<String, Object> bootstrapMap = new HashMap<>();
		bootstrapMap.put("spring.config.name", configName);
		// if an app (or test) uses spring.main.web-application-type=reactive, bootstrap
		// will fail
		// force the environment to use none, because if though it is set below in the
		// builder
		// the environment overrides it
		bootstrapMap.put("spring.main.web-application-type", "none");
		if (StringUtils.hasText(configLocation)) {
			bootstrapMap.put("spring.config.location", configLocation);
		}
		if (StringUtils.hasText(configAdditionalLocation)) {
			bootstrapMap.put("spring.config.additional-location", configAdditionalLocation);
		}
		bootstrapProperties.addFirst(new MapPropertySource(BOOTSTRAP_PROPERTY_SOURCE_NAME, bootstrapMap));
		for (PropertySource<?> source : environment.getPropertySources()) {
			if (source instanceof StubPropertySource) {
				continue;
			}
			bootstrapProperties.addLast(source);
		}
  	//创建cloud的Application
		// TODO: is it possible or sensible to share a ResourceLoader?
		SpringApplicationBuilder builder = new SpringApplicationBuilder().profiles(environment.getActiveProfiles())
				.bannerMode(Mode.OFF).environment(bootstrapEnvironment)
				// Don't use the default properties in this builder
				.registerShutdownHook(false).logStartupInfo(false).web(WebApplicationType.NONE);
		final SpringApplication builderApplication = builder.application();
		if (builderApplication.getMainApplicationClass() == null) {
			// gh_425:
			// SpringApplication cannot deduce the MainApplicationClass here
			// if it is booted from SpringBootServletInitializer due to the
			// absense of the "main" method in stackTraces.
			// But luckily this method's second parameter "application" here
			// carries the real MainApplicationClass which has been explicitly
			// set by SpringBootServletInitializer itself already.
			builder.main(application.getMainApplicationClass());
		}
		if (environment.getPropertySources().contains("refreshArgs")) {
			// If we are doing a context refresh, really we only want to refresh the
			// Environment, and there are some toxic listeners (like the
			// LoggingApplicationListener) that affect global static state, so we need a
			// way to switch those off.
			builderApplication.setListeners(filterListeners(builderApplication.getListeners()));
		}
		builder.sources(BootstrapImportSelectorConfiguration.class);
  	//运行cloud的Application
		final ConfigurableApplicationContext context = builder.run();
		// gh-214 using spring.application.name=bootstrap to set the context id via
		// `ContextIdApplicationContextInitializer` prevents apps from getting the actual
		// spring.application.name
		// during the bootstrap phase.
		context.setId("bootstrap");
		// Make the bootstrap context a parent of the app context
		addAncestorInitializer(application, context);
		// It only has properties in it now that we don't want in the parent so remove
		// it (and it will be added back later)
		bootstrapProperties.remove(BOOTSTRAP_PROPERTY_SOURCE_NAME);
		mergeDefaultProperties(environment.getPropertySources(), bootstrapProperties);
		return context;
```

bootstrapServiceContext中创建了springcloud的SpringApplication,然后又调用了builder.run,所以会在新的Application中再次启动run()流程，会再次prepareEnviment进行预处理环境，所以会再次触发ApplicationEnvironmentPreparedEvent，接下来会通知到org.springframework.boot.context.config.ConfigFileApplicationListener.onApplicationEvent，由于bootstrapServiceContext方法中已经把spring.config.name修改为bootStrap，所以会先读取bootStrap.yaml的配置，跟之前加载application.properties原理一致。



在springcloud的应用启动完毕后，我们可以看到环境对象的资源属性列表会添加一个属性。ExtendedDefaultPropertySource {name='defaultProperties'}为BootstrapApplicationListener中的内部属性类。接下来继续springboot的ApplicationEnvironmentPreparedEvent广播到下一个listener,接下来会由springboot的这个事件通知到org.springframework.boot.context.config.ConfigFileApplicationListener.onApplicationEvent，这时会去加载application.properties
