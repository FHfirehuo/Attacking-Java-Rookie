# BeanDefinition的载入和解析和注册


上文分析了BeanDefiniton的Resource定位过程：



这篇文章分析下BeanDefinition信息的载入过程。

载入过程就是把Resource转化为BeanDefinition作为一个Spring IOC容器内部表示的数据结构的过程。

IOC容器对Bean的管理和依赖注入功能的实现，就是通过对其持有的BeanDefinition进行各种相关操作来完成的。

这些BeanDefinition数据在IOC容器中通过一个HashMap来保护和维护。在上文中，我们从refresh()入口开始，

一直追溯到AbstractBeanDefinitionReader.loadBeanDefinitions()，找到BeanDefinition需要的Resource资源文件。

```java
public int loadBeanDefinitions(String location, Set<Resource> actualResources) throws BeanDefinitionStoreException {
	// 这里得到当前定义的ResourceLoader,默认的使用DefaultResourceLoader
	ResourceLoader resourceLoader = getResourceLoader();
	if (resourceLoader == null) {
		throw new BeanDefinitionStoreException(
				"Cannot import bean definitions from location [" + location + "]: no ResourceLoader available");
	}
	/**
	  * 这里对Resource的路径模式进行解析，得到需要的Resource集合，
	  * 这些Resource集合指向了我们定义好的BeanDefinition的信息，可以是多个文件。
	  */
	if (resourceLoader instanceof ResourcePatternResolver) {
		// Resource pattern matching available.
		try {
			// 调用DefaultResourceLoader的getResources完成具体的Resource定位
			Resource[] resources = ((ResourcePatternResolver) resourceLoader).getResources(location);
			int loadCount = loadBeanDefinitions(resources);
			if (actualResources != null) {
				for (Resource resource : resources) {
					actualResources.add(resource);
				}
			}
			if (logger.isDebugEnabled()) {
				logger.debug("Loaded " + loadCount + " bean definitions from location pattern [" + location + "]");
			}
			return loadCount;
		}
		catch (IOException ex) {
			throw new BeanDefinitionStoreException(
					"Could not resolve bean definition resource pattern [" + location + "]", ex);
		}
	}
	else {
		// Can only load single resources by absolute URL.
		// 通过ResourceLoader来完成位置定位（找水）
		Resource resource = resourceLoader.getResource(location);
         // 载入、解析（装水）
		int loadCount = loadBeanDefinitions(resource);
		if (actualResources != null) {
			actualResources.add(resource);
		}
		if (logger.isDebugEnabled()) {
			logger.debug("Loaded " + loadCount + " bean definitions from location [" + location + "]");
		}
		return loadCount;
	}
}
```

资源文件Resource有了，看下是如何将Resource文件载入到BeanDefinition中的？

## 将xml文件转换成Document对象

Resource载入的具体实现在AbstractBeanDefinitionReader.loadBeanDefinitions()，源码：

```java

@Override
public int loadBeanDefinitions(Resource... resources) throws BeanDefinitionStoreException {
	/**
	  * 如果Resource为空，则停止BeanDefinition载入，然后启动载入BeanDefinition的过程，
	  * 这个过程会遍历整个Resource集合所包含的BeanDefinition信息。
	  */
	Assert.notNull(resources, "Resource array must not be null");
	int counter = 0;
	for (Resource resource : resources) {
		counter += loadBeanDefinitions(resource);
	}
	return counter;
}
```

这里调用loadBeanDefinitions(Resource... resources)方法，但是这个方法AbstractBeanDefinitionReader中没有具体实现。
具体实现在BeanDefinitionReader的子类XmlBeanDefinitionReader中实现。

```java
@Override
public int loadBeanDefinitions(Resource resource) throws BeanDefinitionStoreException {
	return loadBeanDefinitions(new EncodedResource(resource));
}
```

```java

public int loadBeanDefinitions(EncodedResource encodedResource) throws BeanDefinitionStoreException {
	Assert.notNull(encodedResource, "EncodedResource must not be null");
	if (logger.isInfoEnabled()) {
		logger.info("Loading XML bean definitions from " + encodedResource.getResource());
	}
	// 这里是获取线程局部变量
	Set<EncodedResource> currentResources = this.resourcesCurrentlyBeingLoaded.get();
	if (currentResources == null) {
		currentResources = new HashSet<EncodedResource>(4);
		this.resourcesCurrentlyBeingLoaded.set(currentResources);
	}
	if (!currentResources.add(encodedResource)) {
		throw new BeanDefinitionStoreException(
				"Detected cyclic loading of " + encodedResource + " - check your import definitions!");
	}
	try {
		// 这里得到XML文件，新建IO文件输入流，准备从文件中读取内容
		InputStream inputStream = encodedResource.getResource().getInputStream();
		try {
			InputSource inputSource = new InputSource(inputStream);
			if (encodedResource.getEncoding() != null) {
				inputSource.setEncoding(encodedResource.getEncoding());
			}
			// 具体读取过程的方法
			return doLoadBeanDefinitions(inputSource, encodedResource.getResource());
		}
		finally {
			inputStream.close();
		}
	}
	catch (IOException ex) {
		throw new BeanDefinitionStoreException(
				"IOException parsing XML document from " + encodedResource.getResource(), ex);
	}
	finally {
		currentResources.remove(encodedResource);
		if (currentResources.isEmpty()) {
			this.resourcesCurrentlyBeingLoaded.remove();
		}
	}
}
```

```java

protected int doLoadBeanDefinitions(InputSource inputSource, Resource resource)
			throws BeanDefinitionStoreException {
	try {
		// 将XML文件转换为DOM对象，解析过程由documentLoader实现
		Document doc = doLoadDocument(inputSource, resource);
		// 这里是启动对Bean定义解析的详细过程，该解析过程会用到Spring的Bean配置规则
		return registerBeanDefinitions(doc, resource);
	}
	catch (BeanDefinitionStoreException ex) {
		throw ex;
	}
	catch (SAXParseException ex) {
		throw new XmlBeanDefinitionStoreException(resource.getDescription(),
				"Line " + ex.getLineNumber() + " in XML document from " + resource + " is invalid", ex);
	}
	catch (SAXException ex) {
		throw new XmlBeanDefinitionStoreException(resource.getDescription(),
				"XML document from " + resource + " is invalid", ex);
	}
	catch (ParserConfigurationException ex) {
		throw new BeanDefinitionStoreException(resource.getDescription(),
				"Parser configuration exception parsing XML from " + resource, ex);
	}
	catch (IOException ex) {
		throw new BeanDefinitionStoreException(resource.getDescription(),
				"IOException parsing XML document from " + resource, ex);
	}
	catch (Throwable ex) {
		throw new BeanDefinitionStoreException(resource.getDescription(),
				"Unexpected exception parsing XML document from " + resource, ex);
	}
}
```

到这里完成了XML转化为Document对象，主要经历两个过程：资源文件转化为IO和XML转换为Document对象。

## 按照Spring的Bean规则对Document对象进行解析

在上面分析中，通过调用XML解析器将Bean定义资源文件转换得到Document对象，但是这些Document对象并没有按照Spring的Bean规则进行解析。
需要按照Spring的Bean规则对Document对象进行解析。

#### 如何对Document文件进行解析？

```java
public int registerBeanDefinitions(Document doc, Resource resource) throws BeanDefinitionStoreException {
	// 这里得到BeanDefinitionDocumentReader来对XML的BeanDefinition进行解析
	BeanDefinitionDocumentReader documentReader = createBeanDefinitionDocumentReader();
	// 获得容器中注册的Bean数量
	int countBefore = getRegistry().getBeanDefinitionCount();
	// 具体的解析过程在registerBeanDefinitions中完成
	documentReader.registerBeanDefinitions(doc, createReaderContext(resource));
	// 统计解析的Bean数量
	return getRegistry().getBeanDefinitionCount() - countBefore;
}
```

按照Spring的Bean规则对Document对象解析的过程是在接口BeanDefinitionDocumentReader的实现类DefaultBeanDefinitionDocumentReader中实现的。

```java

@Override
public void registerBeanDefinitions(Document doc, XmlReaderContext readerContext) {
	this.readerContext = readerContext;
	logger.debug("Loading bean definitions");
	// 获取根元素
	Element root = doc.getDocumentElement();
	// 具体载入过程
	doRegisterBeanDefinitions(root);
}
```

```java

protected void doRegisterBeanDefinitions(Element root) {
	// Any nested <beans> elements will cause recursion in this method. In
	// order to propagate and preserve <beans> default-* attributes correctly,
	// keep track of the current (parent) delegate, which may be null. Create
	// the new (child) delegate with a reference to the parent for fallback purposes,
	// then ultimately reset this.delegate back to its original (parent) reference.
	// this behavior emulates a stack of delegates without actually necessitating one.
	BeanDefinitionParserDelegate parent = this.delegate;
	this.delegate = createDelegate(getReaderContext(), root, parent);
 
	if (this.delegate.isDefaultNamespace(root)) {
		String profileSpec = root.getAttribute(PROFILE_ATTRIBUTE);
		if (StringUtils.hasText(profileSpec)) {
			String[] specifiedProfiles = StringUtils.tokenizeToStringArray(
					profileSpec, BeanDefinitionParserDelegate.MULTI_VALUE_ATTRIBUTE_DELIMITERS);
			if (!getReaderContext().getEnvironment().acceptsProfiles(specifiedProfiles)) {
				if (logger.isInfoEnabled()) {
					logger.info("Skipped XML bean definition file due to specified profiles [" + profileSpec +
							"] not matching: " + getReaderContext().getResource());
				}
				return;
			}
		}
	}
 
	preProcessXml(root);
	//从Document的根元素开始进行Bean定义的Document对象
	parseBeanDefinitions(root, this.delegate);
	postProcessXml(root);
 
	this.delegate = parent;
}
```
根据Element载入BeanDefinition。


```java
protected void parseBeanDefinitions(Element root, BeanDefinitionParserDelegate delegate) {
    // 如果使用了Spring默认的XML命名空间
	if (delegate.isDefaultNamespace(root)) {
		// 遍历根元素的所有子节点
		NodeList nl = root.getChildNodes();
		for (int i = 0; i < nl.getLength(); i++) {
			Node node = nl.item(i);
			// 如果该节点是XML元素节点
			if (node instanceof Element) {
				Element ele = (Element) node;
				// 如果该节点使用的是Spring默认的XML命名空间
				if (delegate.isDefaultNamespace(ele)) {
					// 使用Spring的Bean规则解析元素节点
					parseDefaultElement(ele, delegate);
				}
				else {
					// 没有使用Spring默认的XML命名空间，则使用用户自定义的解析规则解析元素节点
					delegate.parseCustomElement(ele);
				}
			}
		}
	}
	else {
		// Document的根节点没有使用Spring默认的命名空间，则使用用户自定义的解析规则解析Document根节点
		delegate.parseCustomElement(root);
	}
}
```

该方法作用，使用Spring的Bean规则从Document的根元素开始进行Bean定义的Document对象。

这里主要是看节点元素是否是Spring的规范，因为它允许我们自定义解析规范，那么正常我们是利用Spring的规则，
所以我们来看parseDefaultElement(ele, delegate)方法。


```java
private void parseDefaultElement(Element ele, BeanDefinitionParserDelegate delegate) {
	// 如果元素节点是<Import>导入元素，进行导入解析
	if (delegate.nodeNameEquals(ele, IMPORT_ELEMENT)) {
		importBeanDefinitionResource(ele);
	}
	// 如果元素节点是<Alias>别名元素，进行别名解析
	else if (delegate.nodeNameEquals(ele, ALIAS_ELEMENT)) {
		processAliasRegistration(ele);
	}
	// 如果普通的<Bean>元素，按照Spring的Bean规则解析元素
	else if (delegate.nodeNameEquals(ele, BEAN_ELEMENT)) {
		processBeanDefinition(ele, delegate);
	}
	// 如果普通的<Beans>元素，调用doRegisterBeanDefinitions()递归处理
	else if (delegate.nodeNameEquals(ele, NESTED_BEANS_ELEMENT)) {
		// recurse
		doRegisterBeanDefinitions(ele);
	}
}
```
根据Bean的属性，调用不同的规则解析元素，这里讨论普通Bean元素的解析规则，

调用processBeanDefinition规则进行Bean处理。

```java

protected void processBeanDefinition(Element ele, BeanDefinitionParserDelegate delegate) {
	/**
	  * BeanDefinitionHolder是对BeanDefinition对象的封装，封装了BeanDefinition、Bean的名字和别名。
 	  * 用来完成想IOC容器注册。得到BeanDefinitionHolder就意味着是通过BeanDefinitionParserDelegate
	  * 对XML元素的信息按照Spring的Bean规则进行解析得到的。
	  *
	  */
	BeanDefinitionHolder bdHolder = delegate.parseBeanDefinitionElement(ele);
	if (bdHolder != null) {
		bdHolder = delegate.decorateBeanDefinitionIfRequired(ele, bdHolder);
		try {
			// Register the final decorated instance.
			// 这里是向IOC容器注册解析得到的BeanDefinition的地方
			BeanDefinitionReaderUtils.registerBeanDefinition(bdHolder, getReaderContext().getRegistry());
		}
		catch (BeanDefinitionStoreException ex) {
			getReaderContext().error("Failed to register bean definition with name '" +
					bdHolder.getBeanName() + "'", ele, ex);
		}
		// Send registration event.
		// 在BeanDefinition向IOC容器注册以后，发送消息
		getReaderContext().fireComponentRegistered(new BeanComponentDefinition(bdHolder));
	}
}
```

## Bean资源的解析

具体解析过程委托给BeanDefinitionParserDelegate的parseBeanDefinitionElement来完成。

```java

public BeanDefinitionHolder parseBeanDefinitionElement(Element ele) {
	return parseBeanDefinitionElement(ele, null);
}
```

```java

public BeanDefinitionHolder parseBeanDefinitionElement(Element ele, BeanDefinition containingBean) {
	// 在这里取得<bean>元素中定义的id、name、aliase属性值
	String id = ele.getAttribute(ID_ATTRIBUTE);
	String nameAttr = ele.getAttribute(NAME_ATTRIBUTE);
 
	List<String> aliases = new ArrayList<String>();
	if (StringUtils.hasLength(nameAttr)) {
		String[] nameArr = StringUtils.tokenizeToStringArray(nameAttr, MULTI_VALUE_ATTRIBUTE_DELIMITERS);
		aliases.addAll(Arrays.asList(nameArr));
	}
 
	String beanName = id;
	if (!StringUtils.hasText(beanName) && !aliases.isEmpty()) {
		beanName = aliases.remove(0);
		if (logger.isDebugEnabled()) {
			logger.debug("No XML 'id' specified - using '" + beanName +
					"' as bean name and " + aliases + " as aliases");
		}
	}
 
	if (containingBean == null) {
		checkNameUniqueness(beanName, aliases, ele);
	}
	// 启动对bean元素的详细解析
	AbstractBeanDefinition beanDefinition = parseBeanDefinitionElement(ele, beanName, containingBean);
	if (beanDefinition != null) {
		if (!StringUtils.hasText(beanName)) {
			try {
				if (containingBean != null) {
					beanName = BeanDefinitionReaderUtils.generateBeanName(
							beanDefinition, this.readerContext.getRegistry(), true);
				}
				else {
					beanName = this.readerContext.generateBeanName(beanDefinition);
					// Register an alias for the plain bean class name, if still possible,
					// if the generator returned the class name plus a suffix.
					// This is expected for Spring 1.2/2.0 backwards compatibility.
					String beanClassName = beanDefinition.getBeanClassName();
					if (beanClassName != null &&
							beanName.startsWith(beanClassName) && beanName.length() > beanClassName.length() &&
							!this.readerContext.getRegistry().isBeanNameInUse(beanClassName)) {
						aliases.add(beanClassName);
					}
				}
				if (logger.isDebugEnabled()) {
					logger.debug("Neither XML 'id' nor 'name' specified - " +
							"using generated bean name [" + beanName + "]");
				}
			}
			catch (Exception ex) {
				error(ex.getMessage(), ele);
				return null;
			}
		}
		String[] aliasesArray = StringUtils.toStringArray(aliases);
		return new BeanDefinitionHolder(beanDefinition, beanName, aliasesArray);
	}
 
	return null;
}
```

上面介绍了对Bean元素进行解析的过程，也即是BeanDefinition依据XML的<bean>定义被创建的过程。

这个BeanDefinition可以看成是对<bean>定义的抽象。这个数据对象中封装的数据大多都是与<bean>定义相关的，
也有很多就是我们在定义Bean时看到的那些Spring标记，比如常见的init-method、destory-method、factory-method等等，
这个BeanDefinition数据类型非常重要，它封装了很多基本数据，这些基本数据都是IOC容器需要的。
有了这些基本数据，IOC容器才能对Bean配置进行处理，才能实现相应的容器特性。

```java
public AbstractBeanDefinition parseBeanDefinitionElement(
		Element ele, String beanName, BeanDefinition containingBean) {
	
	this.parseState.push(new BeanEntry(beanName));
	/**
	  * 这里只读取定义的<bean>中设置的class名字，然后载入到BeanDefinition中去，
	  * 只是做个记录，并不涉及对象的实例化过程，对象的实例化实际上是在依赖注入时完成的。
	  */
	String className = null;
	if (ele.hasAttribute(CLASS_ATTRIBUTE)) {
		className = ele.getAttribute(CLASS_ATTRIBUTE).trim();
	}
 
	try {
		String parent = null;
		if (ele.hasAttribute(PARENT_ATTRIBUTE)) {
			parent = ele.getAttribute(PARENT_ATTRIBUTE);
		}
		// 生成需要的BeanDefinition对象，为Bean定义信息的载入做准备
		AbstractBeanDefinition bd = createBeanDefinition(className, parent);
		// 对当前的Bean元素进行属性解析，并设置description的信息
		parseBeanDefinitionAttributes(ele, beanName, containingBean, bd);
		bd.setDescription(DomUtils.getChildElementValueByTagName(ele, DESCRIPTION_ELEMENT));
		// 对Bean元素信息进行解析
		parseMetaElements(ele, bd);
		parseLookupOverrideSubElements(ele, bd.getMethodOverrides());
		parseReplacedMethodSubElements(ele, bd.getMethodOverrides());
		// 解析<bean>的构造函数设置
		parseConstructorArgElements(ele, bd);
		// 解析<bean>的property设置
		parsePropertyElements(ele, bd);
		parseQualifierElements(ele, bd);
 
		bd.setResource(this.readerContext.getResource());
		bd.setSource(extractSource(ele));
 
		return bd;
	}
	catch (ClassNotFoundException ex) {
		error("Bean class [" + className + "] not found", ele, ex);
	}
	catch (NoClassDefFoundError err) {
		error("Class that bean class [" + className + "] depends on not found", ele, err);
	}
	catch (Throwable ex) {
		error("Unexpected failure during bean definition parsing", ele, ex);
	}
	finally {
		this.parseState.pop();
	}
 
	return null;
}
```
上面是具体生成BeanDefinition的地方。在这里举一个对property进行解析的例子来完成对整个BeanDefinition载入过程的分析，还是在类BeanDefinitionParserDelegate的代码中，
一层一层的对BeanDefinition中的定义进行解析，比如从属性元素结合到具体的每一个属性元素，然后才到具体值的处理。
根据解析结果，对这些属性值的处理会被封装成PropertyValue对象并设置到BeanDefinition对象中去。

```java

public void parsePropertyElements(Element beanEle, BeanDefinition bd) {
	// 获取bean元素下定义的所有节点
	NodeList nl = beanEle.getChildNodes();
	for (int i = 0; i < nl.getLength(); i++) {
		Node node = nl.item(i);
		// 判断是property元素后对该property元素进行解析
		if (isCandidateElement(node) && nodeNameEquals(node, PROPERTY_ELEMENT)) {
			parsePropertyElement((Element) node, bd);
		}
	}
}
```

```java
public void parsePropertyElement(Element ele, BeanDefinition bd) {
  // 这里取得property的名字
   String propertyName = ele.getAttribute(NAME_ATTRIBUTE);
   if (!StringUtils.hasLength(propertyName)) {
      error("Tag 'property' must have a 'name' attribute", ele);
      return;
   }
   this.parseState.push(new PropertyEntry(propertyName));
   try {
    /**
      * 如果同一个Bean中已经有同名的property存在，则不进行解析，直接返回。
      * 如果再同一个Bean中有同名的property设置，那么起作用的只是第一个。
      */
      if (bd.getPropertyValues().contains(propertyName)) {
         error("Multiple 'property' definitions for property '" + propertyName + "'", ele);
         return;
      }
    /**
      * 这里是解析property值的地方，返回的对象对应Bean定义的property属性设置的解析结果，
      * 这个解析结果会封装到PropertyValue对象中，然后设置。
      */
      Object val = parsePropertyValue(ele, bd, propertyName);
      PropertyValue pv = new PropertyValue(propertyName, val);
      parseMetaElements(ele, pv);
      pv.setSource(extractSource(ele));
      bd.getPropertyValues().addPropertyValue(pv);
   }
   finally {
      this.parseState.pop();
   }
}
```

```java

public Object parsePropertyValue(Element ele, BeanDefinition bd, String propertyName) {
   String elementName = (propertyName != null) ?
               "<property> element for property '" + propertyName + "'" :
               "<constructor-arg> element";
 
   // Should only have one child element: ref, value, list, etc.
   NodeList nl = ele.getChildNodes();
   Element subElement = null;
   for (int i = 0; i < nl.getLength(); i++) {
      Node node = nl.item(i);
      if (node instanceof Element && !nodeNameEquals(node, DESCRIPTION_ELEMENT) &&
            !nodeNameEquals(node, META_ELEMENT)) {
         // Child element is what we're looking for.
         if (subElement != null) {
            error(elementName + " must not contain more than one sub-element", ele);
         }
         else {
            subElement = (Element) node;
         }
      }
   }
  // 判断Property的属性，是ref还是value,不允许同时出现ref和value
   boolean hasRefAttribute = ele.hasAttribute(REF_ATTRIBUTE);
   boolean hasValueAttribute = ele.hasAttribute(VALUE_ATTRIBUTE);
   if ((hasRefAttribute && hasValueAttribute) ||
         ((hasRefAttribute || hasValueAttribute) && subElement != null)) {
      error(elementName +
            " is only allowed to contain either 'ref' attribute OR 'value' attribute OR sub-element", ele);
   }
   // 如果是ref，创建一个ref的数据对象RuntimeBeanReference，这个对象封装了ref的信息
   if (hasRefAttribute) {
      String refName = ele.getAttribute(REF_ATTRIBUTE);
      if (!StringUtils.hasText(refName)) {
         error(elementName + " contains empty 'ref' attribute", ele);
      }
      RuntimeBeanReference ref = new RuntimeBeanReference(refName);
      ref.setSource(extractSource(ele));
      return ref;
   }
   // 如果是value,创建一个value的数据对象TypedStringValue，这个对象封装了value的信息
   else if (hasValueAttribute) {
      TypedStringValue valueHolder = new TypedStringValue(ele.getAttribute(VALUE_ATTRIBUTE));
      valueHolder.setSource(extractSource(ele));
      return valueHolder;
   }
   // 如果还有子元素，触发对子元素的解析
   else if (subElement != null) {
      return parsePropertySubElement(subElement, bd);
   }
   else {
      // Neither child element nor "ref" or "value" attribute found.
      error(elementName + " must specify a ref or value", ele);
      return null;
   }
}
```

这里对property子元素的解析过程，Array、List、Set、Map、Prop等各种元素都会在这里解析，生成对应的数据对象，比如ManagedList、ManagedArray、ManagedSet等等。
这些ManagedXX类是Spring对具体的BeanDefinition的数据封装。具体的解析可以从parsePropertySubElement()关于property子元素的解析深入追踪，
可以看到parseArrayElement、parseListElement、parseSetElement、parseMapElement、parsePropsElement等方法处理。

```java

public Object parsePropertySubElement(Element ele, BeanDefinition bd) {
   return parsePropertySubElement(ele, bd, null);
}
```

```java

public Object parsePropertySubElement(Element ele, BeanDefinition bd, String defaultValueType) {
   if (!isDefaultNamespace(ele)) {
      return parseNestedCustomElement(ele, bd);
   }
   else if (nodeNameEquals(ele, BEAN_ELEMENT)) {
      BeanDefinitionHolder nestedBd = parseBeanDefinitionElement(ele, bd);
      if (nestedBd != null) {
         nestedBd = decorateBeanDefinitionIfRequired(ele, nestedBd, bd);
      }
      return nestedBd;
   }
   else if (nodeNameEquals(ele, REF_ELEMENT)) {
      // A generic reference to any name of any bean.
      String refName = ele.getAttribute(BEAN_REF_ATTRIBUTE);
      boolean toParent = false;
      if (!StringUtils.hasLength(refName)) {
         // A reference to the id of another bean in the same XML file.
         refName = ele.getAttribute(LOCAL_REF_ATTRIBUTE);
         if (!StringUtils.hasLength(refName)) {
            // A reference to the id of another bean in a parent context.
            refName = ele.getAttribute(PARENT_REF_ATTRIBUTE);
            toParent = true;
            if (!StringUtils.hasLength(refName)) {
               error("'bean', 'local' or 'parent' is required for <ref> element", ele);
               return null;
            }
         }
      }
      if (!StringUtils.hasText(refName)) {
         error("<ref> element contains empty target attribute", ele);
         return null;
      }
      RuntimeBeanReference ref = new RuntimeBeanReference(refName, toParent);
      ref.setSource(extractSource(ele));
      return ref;
   }
   else if (nodeNameEquals(ele, IDREF_ELEMENT)) {
      return parseIdRefElement(ele);
   }
   else if (nodeNameEquals(ele, VALUE_ELEMENT)) {
      return parseValueElement(ele, defaultValueType);
   }
   else if (nodeNameEquals(ele, NULL_ELEMENT)) {
      // It's a distinguished null value. Let's wrap it in a TypedStringValue
      // object in order to preserve the source location.
      TypedStringValue nullHolder = new TypedStringValue(null);
      nullHolder.setSource(extractSource(ele));
      return nullHolder;
   }
   else if (nodeNameEquals(ele, ARRAY_ELEMENT)) {
      return parseArrayElement(ele, bd);
   }
   else if (nodeNameEquals(ele, LIST_ELEMENT)) {
      return parseListElement(ele, bd);
   }
   else if (nodeNameEquals(ele, SET_ELEMENT)) {
      return parseSetElement(ele, bd);
   }
   else if (nodeNameEquals(ele, MAP_ELEMENT)) {
      return parseMapElement(ele, bd);
   }
   else if (nodeNameEquals(ele, PROPS_ELEMENT)) {
      return parsePropsElement(ele);
   }
   else {
      error("Unknown property sub-element: [" + ele.getNodeName() + "]", ele);
      return null;
   }
}
```

看看一个List这样的睡醒配置是怎样被解析的？

```java

public List<Object> parseListElement(Element collectionEle, BeanDefinition bd) {
   String defaultElementType = collectionEle.getAttribute(VALUE_TYPE_ATTRIBUTE);
   NodeList nl = collectionEle.getChildNodes();
   ManagedList<Object> target = new ManagedList<Object>(nl.getLength());
   target.setSource(extractSource(collectionEle));
   target.setElementTypeName(defaultElementType);
   target.setMergeEnabled(parseMergeAttribute(collectionEle));
   // 具体的List元素解析过程
   parseCollectionElements(nl, target, bd, defaultElementType);
   return target;
}
```

```java

protected void parseCollectionElements(
      NodeList elementNodes, Collection<Object> target, BeanDefinition bd, String defaultElementType) {
  // 遍历所有的元素节点，并判断其类型是否为Element
   for (int i = 0; i < elementNodes.getLength(); i++) {
      Node node = elementNodes.item(i);
      if (node instanceof Element && !nodeNameEquals(node, DESCRIPTION_ELEMENT)) {
         //加入到Target中国，target是一个ManagedList，同时触发对下一层子元素的解析过程，
         // 这是一个递归的调用，逐层地解析
         target.add(parsePropertySubElement((Element) node, bd, defaultElementType));
      }
   }
}
```

经过逐层地解析，我们在XML文件中定义的BeanDefinition就被整个载入到了IOC容器中，并在容器中建立了数据映射。
在IOC容器中建立了对应的数据结构，或者可以看成是POJO对象在IOC容器中的抽象，这些数据结构可以以AbstracBeanDefinition为入口，让IOC容器执行索引、查询和操作。

每一个简单的POJO操作的背后其实都含着一个复杂的抽象过程，经过以上的载入过程，IOC容器大致完成了管理Bean对象的数据准备工作也即是数据初始化过程。
严格来说，这个时候容器还没有起作用，要完全发挥容器的作用，还需要完成数据向容器的注册，也即IOC容器注册BeanDefinition。

## BeanDefinition的注册

在BeanDefinition载入和解析这些动作完成之后，用户定义的BeanDefinition信息已经在IOC容器内建立了自己的数据结构以及

相应的数据表示，但此时这些数据不能供IOC容器直接使用，需要在IOC容器中对这些BeanDefinition

数据进行注册。这个注册为IOC容器提供了更友好的使用方式，在DefaultListableBeanFactory中，

是通过一个HashMap来持有载入的BeanDefinition的，这个HashMap的定义如下：


```java
@Override
	protected final void refreshBeanFactory() throws BeansException {
		if (hasBeanFactory()) {
			destroyBeans();
			closeBeanFactory();
		}
		try {
             //创建IoC容器，这里使用的是DefaultListableBeanFactory
			DefaultListableBeanFactory beanFactory = createBeanFactory();
			beanFactory.setSerializationId(getId());
			customizeBeanFactory(beanFactory);
            /**
            		 * 启动对BeanDefinition的载入，这里使用了一个委派模式，
            		 * 在当前类中只定义了抽象的loadBeanDefinitions方法，具体的实现调用子类容器
            		 */
			loadBeanDefinitions(beanFactory);
			this.beanFactory = beanFactory;
		}
		catch (IOException ex) {
			throw new ApplicationContextException("I/O error parsing bean definition source for " + getDisplayName(), ex);
		}
	}
```

```java

private final Map<String, BeanDefinition> beanDefinitionMap = new ConcurrentHashMap<String, BeanDefinition>(256);
```

下面分析BeanDefinition如何注册到HashMap的。

从上一章节的BeanDefinition()处理开始看看IOC容器如何注册BeanDefinition。

```java

protected void processBeanDefinition(Element ele, BeanDefinitionParserDelegate delegate) {
	/**
	  * BeanDefinitionHolder是对BeanDefinition对象的封装，封装了BeanDefinition、Bean的名字和别名。
 	  * 用来完成想IOC容器注册。得到BeanDefinitionHolder就意味着是通过BeanDefinitionParserDelegate
	  * 对XML元素的信息按照Spring的Bean规则进行解析得到的。
	  *
	  */
	BeanDefinitionHolder bdHolder = delegate.parseBeanDefinitionElement(ele);
	if (bdHolder != null) {
		bdHolder = delegate.decorateBeanDefinitionIfRequired(ele, bdHolder);
		try {
			// Register the final decorated instance.
			// 这里是向IOC容器注册解析得到的BeanDefinition的地方
			BeanDefinitionReaderUtils.registerBeanDefinition(bdHolder, getReaderContext().getRegistry());
		}
		catch (BeanDefinitionStoreException ex) {
			getReaderContext().error("Failed to register bean definition with name '" +
					bdHolder.getBeanName() + "'", ele, ex);
		}
		// Send registration event.
		// 在BeanDefinition向IOC容器注册以后，发送消息
		getReaderContext().fireComponentRegistered(new BeanComponentDefinition(bdHolder));
	}
}
```

BeanDefinition注册在BeanDefinitionReaderUtils.registerBeanDefinition()方法中完成。

```java
public static void registerBeanDefinition(
      BeanDefinitionHolder definitionHolder, BeanDefinitionRegistry registry)
      throws BeanDefinitionStoreException {
 
   // Register bean definition under primary name.
   // 根据定义的唯一的beanName注册Beandefinition
   String beanName = definitionHolder.getBeanName();
   registry.registerBeanDefinition(beanName, definitionHolder.getBeanDefinition());
 
   // Register aliases for bean name, if any.
   // 如果有别名，注册别名
   String[] aliases = definitionHolder.getAliases();
   if (aliases != null) {
      for (String alias : aliases) {
         registry.registerAlias(beanName, alias);
      }
   }
}
```

注册registerBeanDefinition()方法的具体实现在BeanDefinitionRegistry接口的实现类DefaultListableBeanFactory中来完成。
```java
@Override
public void registerBeanDefinition(String beanName, BeanDefinition beanDefinition)
      throws BeanDefinitionStoreException {
  // BeanName和BeanDefinition不能为空，否则停止注册
   Assert.hasText(beanName, "Bean name must not be empty");
   Assert.notNull(beanDefinition, "BeanDefinition must not be null");
 
   if (beanDefinition instanceof AbstractBeanDefinition) {
      try {
         ((AbstractBeanDefinition) beanDefinition).validate();
      }
      catch (BeanDefinitionValidationException ex) {
         throw new BeanDefinitionStoreException(beanDefinition.getResourceDescription(), beanName,
               "Validation of bean definition failed", ex);
      }
   }
 
   BeanDefinition oldBeanDefinition;
  // 检查是否有相同名字的BeanDefinition已经在IOC容器中注册了，如果有同名的BeanDefinition，
   // 但又不允许覆盖，就会抛出异常，否则覆盖BeanDefinition。
   oldBeanDefinition = this.beanDefinitionMap.get(beanName);
   if (oldBeanDefinition != null) {
      if (!isAllowBeanDefinitionOverriding()) {
         throw new BeanDefinitionStoreException(beanDefinition.getResourceDescription(), beanName,
               "Cannot register bean definition [" + beanDefinition + "] for bean '" + beanName +
               "': There is already [" + oldBeanDefinition + "] bound.");
      }
      else if (oldBeanDefinition.getRole() < beanDefinition.getRole()) {
         // e.g. was ROLE_APPLICATION, now overriding with ROLE_SUPPORT or ROLE_INFRASTRUCTURE
         if (this.logger.isWarnEnabled()) {
            this.logger.warn("Overriding user-defined bean definition for bean '" + beanName +
                  "' with a framework-generated bean definition: replacing [" +
                  oldBeanDefinition + "] with [" + beanDefinition + "]");
         }
      }
      else if (!beanDefinition.equals(oldBeanDefinition)) {
         if (this.logger.isInfoEnabled()) {
            this.logger.info("Overriding bean definition for bean '" + beanName +
                  "' with a different definition: replacing [" + oldBeanDefinition +
                  "] with [" + beanDefinition + "]");
         }
      }
      else {
         if (this.logger.isDebugEnabled()) {
            this.logger.debug("Overriding bean definition for bean '" + beanName +
                  "' with an equivalent definition: replacing [" + oldBeanDefinition +
                  "] with [" + beanDefinition + "]");
         }
      }
      this.beanDefinitionMap.put(beanName, beanDefinition);
   }
   else {
      // 检查下容器是否进入了Bean的创建阶段，即是否同时创建了任何bean
      if (hasBeanCreationStarted()) { // 已经创建了Bean，容器中已经有Bean了，是在启动注册阶段创建的。
         // Cannot modify startup-time collection elements anymore (for stable iteration)
         // 注册过程中需要线程同步，以保证数据一致性
         synchronized (this.beanDefinitionMap) {
            this.beanDefinitionMap.put(beanName, beanDefinition);
            List<String> updatedDefinitions = new ArrayList<String>(this.beanDefinitionNames.size() + 1);
            updatedDefinitions.addAll(this.beanDefinitionNames);
            updatedDefinitions.add(beanName);
            this.beanDefinitionNames = updatedDefinitions;
            if (this.manualSingletonNames.contains(beanName)) {
               Set<String> updatedSingletons = new LinkedHashSet<String>(this.manualSingletonNames);
               updatedSingletons.remove(beanName);
               this.manualSingletonNames = updatedSingletons;
            }
         }
      }
      else {// 正在启动注册阶段，容器这个时候还是空的。
         // Still in startup registration phase
         this.beanDefinitionMap.put(beanName, beanDefinition);
         this.beanDefinitionNames.add(beanName);
         this.manualSingletonNames.remove(beanName);
      }
      this.frozenBeanDefinitionNames = null;
   }
  // 重置所有已经注册过的BeanDefinition或单例模式的BeanDefinition的缓存
   if (oldBeanDefinition != null || containsSingleton(beanName)) {
      resetBeanDefinition(beanName);
   }
}
```

到这里完成了BeanDefinition的注册，就算完了IOC容器的初始化过程。
此时，在使用的IOC容器DefaultListableBeanFactory中已经建立了整个Bean的配置信息，而且这些BeanDefinition已经可以被容器使用了，
它们都在beanDefinitionMap里被检索和使用。容器的作用就是对这些信息进行处理和维护。
这些信息就是容器建立依赖反转的基础，有了这些基础数据，就可以进一步完成依赖注入，
下一篇讨论依赖注入的实现原理Bean的创建，Bean依赖注入。


