# Bean依赖注入


从上文“Bean对象的创建”中提到过，BeanFactory中getBean方法不仅是bean创建分析的入口，也是依赖注入分析的入口，因为只有完成这两个步，才能返回给用户一个预期的Bean对象。

回顾一下上文中的AbstractAutowireCapableBeanFactory.doCreateBean()方法源码：

```java
protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final Object[] args)
      throws BeanCreationException {
 
   // Instantiate the bean.
   // 这个BeanWrapper是用来持有创建出来的Bean对象
   BeanWrapper instanceWrapper = null;
   // 如果是Singleton，先把缓存中的同名Bean清除
   if (mbd.isSingleton()) {
      instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
   }
   // 通过createBeanInstance()创建Bean
   if (instanceWrapper == null) {
      instanceWrapper = createBeanInstance(beanName, mbd, args);
   }
   final Object bean = (instanceWrapper != null ? instanceWrapper.getWrappedInstance() : null);
   Class<?> beanType = (instanceWrapper != null ? instanceWrapper.getWrappedClass() : null);
   mbd.resolvedTargetType = beanType;
 
   // Allow post-processors to modify the merged bean definition.
   synchronized (mbd.postProcessingLock) {
      if (!mbd.postProcessed) {
         try {
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
   boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
         isSingletonCurrentlyInCreation(beanName));
   if (earlySingletonExposure) {
      if (logger.isDebugEnabled()) {
         logger.debug("Eagerly caching bean '" + beanName +
               "' to allow for resolving potential circular references");
      }
      addSingletonFactory(beanName, new ObjectFactory<Object>() {
         @Override
         public Object getObject() throws BeansException {
            return getEarlyBeanReference(beanName, mbd, bean);
         }
      });
   }
 
   // Initialize the bean instance.
   // 对Bean进行初始化，这个exposedObject在初始化以后会返回座位依赖注入完成后的Bean
   Object exposedObject = bean;
   try {
      populateBean(beanName, mbd, instanceWrapper);
      if (exposedObject != null) {
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
 
   if (earlySingletonExposure) {
      Object earlySingletonReference = getSingleton(beanName, false);
      if (earlySingletonReference != null) {
         if (exposedObject == bean) {
            exposedObject = earlySingletonReference;
         }
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
      registerDisposableBeanIfNecessary(beanName, bean, mbd);
   }
   catch (BeanDefinitionValidationException ex) {
      throw new BeanCreationException(
            mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
   }
 
   return exposedObject;
}
```

这个doCreateBean()中有两个方法，在上文已经从createBeanInstance()方法分析了Bean的创建过程，还有另外一个populateBean()方法，这个是依赖注入的分析入口。

```java

protected void populateBean(String beanName, RootBeanDefinition mbd, BeanWrapper bw) {
  // 获取BeanDefinition中设置的property值
   PropertyValues pvs = mbd.getPropertyValues();
 
   if (bw == null) {
      if (!pvs.isEmpty()) {
         throw new BeanCreationException(
               mbd.getResourceDescription(), beanName, "Cannot apply property values to null instance");
      }
      else {
         // Skip property population phase for null instance.
         return;
      }
   }
 
   // Give any InstantiationAwareBeanPostProcessors the opportunity to modify the
   // state of the bean before properties are set. This can be used, for example,
   // to support styles of field injection.
   boolean continueWithPropertyPopulation = true;
 
   if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
      for (BeanPostProcessor bp : getBeanPostProcessors()) {
         if (bp instanceof InstantiationAwareBeanPostProcessor) {
            InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
            if (!ibp.postProcessAfterInstantiation(bw.getWrappedInstance(), beanName)) {
               continueWithPropertyPopulation = false;
               break;
            }
         }
      }
   }
 
   if (!continueWithPropertyPopulation) {
      return;
   }
   // 开始进行依赖注入过程，先处理autowire的注入
   if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_NAME ||
         mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_TYPE) {
      MutablePropertyValues newPvs = new MutablePropertyValues(pvs);
 
      // Add property values based on autowire by name if applicable.
      // 根据Bean的名字，完成Bean的autowire
      if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_NAME) {
         autowireByName(beanName, mbd, bw, newPvs);
      }
 
      // Add property values based on autowire by type if applicable.
      // 根据Bean的类型，完成Bean的autowire
      if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_TYPE) {
         autowireByType(beanName, mbd, bw, newPvs);
      }
 
      pvs = newPvs;
   }
 
   boolean hasInstAwareBpps = hasInstantiationAwareBeanPostProcessors();
   boolean needsDepCheck = (mbd.getDependencyCheck() != RootBeanDefinition.DEPENDENCY_CHECK_NONE);
 
   if (hasInstAwareBpps || needsDepCheck) {
      PropertyDescriptor[] filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
      if (hasInstAwareBpps) {
         for (BeanPostProcessor bp : getBeanPostProcessors()) {
            if (bp instanceof InstantiationAwareBeanPostProcessor) {
               InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
               pvs = ibp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
               if (pvs == null) {
                  return;
               }
            }
         }
      }
      if (needsDepCheck) {
         checkDependencies(beanName, mbd, filteredPds, pvs);
      }
   }
   // 对属性进行注入
   applyPropertyValues(beanName, mbd, bw, pvs);
}
```

看这块代码有几点我们要明确：

1. 后面所讲的内容全部是bean在xml中的定义的内容，我们平时用的@Resource @Autowired并不是在这里解析的，那些属于Spring注解的内容。
2。 这里的autowire跟@Autowired不一样，autowire是Spring配置文件中的一个配置，@Autowired是一个注解。

<bean id="personFactory" class="com.xx.PersonFactory" autowire="byName">

一般Spring不建议autowire的配置。

下面分析applyPropertyValues()方法实现了属性注入的解析过程。

```java
protected void applyPropertyValues(String beanName, BeanDefinition mbd, BeanWrapper bw, PropertyValues pvs) {
   if (pvs == null || pvs.isEmpty()) {
      return;
   }
 
   MutablePropertyValues mpvs = null;
   List<PropertyValue> original;
 
   if (System.getSecurityManager() != null) {
      if (bw instanceof BeanWrapperImpl) {
         ((BeanWrapperImpl) bw).setSecurityContext(getAccessControlContext());
      }
   }
 
   if (pvs instanceof MutablePropertyValues) {
      mpvs = (MutablePropertyValues) pvs;
      if (mpvs.isConverted()) {
         // Shortcut: use the pre-converted values as-is.
         try {
            bw.setPropertyValues(mpvs);
            return;
         }
         catch (BeansException ex) {
            throw new BeanCreationException(
                  mbd.getResourceDescription(), beanName, "Error setting property values", ex);
         }
      }
      original = mpvs.getPropertyValueList();
   }
   else {
      original = Arrays.asList(pvs.getPropertyValues());
   }
 
   TypeConverter converter = getCustomTypeConverter();
   if (converter == null) {
      converter = bw;
   }
   // BeanDefinition在BeanDefinitionValueResolver中完成
   BeanDefinitionValueResolver valueResolver = new BeanDefinitionValueResolver(this, beanName, mbd, converter);
 
   // Create a deep copy, resolving any references for values.
   // 为解析值创建一个副本，副本的数据将会被注入到Bean中
   List<PropertyValue> deepCopy = new ArrayList<PropertyValue>(original.size());
   boolean resolveNecessary = false;
   for (PropertyValue pv : original) {
      if (pv.isConverted()) {
         deepCopy.add(pv);
      }
      else {
         String propertyName = pv.getName();
         Object originalValue = pv.getValue();
         Object resolvedValue = valueResolver.resolveValueIfNecessary(pv, originalValue);
         Object convertedValue = resolvedValue;
         boolean convertible = bw.isWritableProperty(propertyName) &&
               !PropertyAccessorUtils.isNestedOrIndexedProperty(propertyName);
         if (convertible) {
            convertedValue = convertForProperty(resolvedValue, propertyName, bw, converter);
         }
         // Possibly store converted value in merged bean definition,
         // in order to avoid re-conversion for every created bean instance.
         if (resolvedValue == originalValue) {
            if (convertible) {
               pv.setConvertedValue(convertedValue);
            }
            deepCopy.add(pv);
         }
         else if (convertible && originalValue instanceof TypedStringValue &&
               !((TypedStringValue) originalValue).isDynamic() &&
               !(convertedValue instanceof Collection || ObjectUtils.isArray(convertedValue))) {
            pv.setConvertedValue(convertedValue);
            deepCopy.add(pv);
         }
         else {
            resolveNecessary = true;
            deepCopy.add(new PropertyValue(pv, convertedValue));
         }
      }
   }
   if (mpvs != null && !resolveNecessary) {
      mpvs.setConverted();
   }
 
   // Set our (possibly massaged) deep copy.
   try {
      // 这里是依赖注入放生的地方，将副本依赖注入，具体实现在BeanWrapperImpl中完成
      bw.setPropertyValues(new MutablePropertyValues(deepCopy));
   }
   catch (BeansException ex) {
      throw new BeanCreationException(
            mbd.getResourceDescription(), beanName, "Error setting property values", ex);
   }
}
```

通过使用BeanDefinitionValueResolver来对BeanDefinition进行解析，然后注入到property中。

下面分析下BeanDefinitionValueResolver中如何解析，以对Bean Reference进行解析为例。

BeanDefinitionValueResolver.resolveValueIfNecessary()方法源码：

```java

public Object resolveValueIfNecessary(Object argName, Object value) {
   // We must check each value to see whether it requires a runtime reference
   // to another bean to be resolved.
   // 检查每个值，看看它是否需要一个运行时引用来解析另一个bean
   if (value instanceof RuntimeBeanReference) {
      RuntimeBeanReference ref = (RuntimeBeanReference) value;
      return resolveReference(argName, ref);
   }
   else if (value instanceof RuntimeBeanNameReference) {
      String refName = ((RuntimeBeanNameReference) value).getBeanName();
      refName = String.valueOf(doEvaluate(refName));
      if (!this.beanFactory.containsBean(refName)) {
         throw new BeanDefinitionStoreException(
               "Invalid bean name '" + refName + "' in bean reference for " + argName);
      }
      return refName;
   }
   else if (value instanceof BeanDefinitionHolder) {
      // Resolve BeanDefinitionHolder: contains BeanDefinition with name and aliases.
      BeanDefinitionHolder bdHolder = (BeanDefinitionHolder) value;
      return resolveInnerBean(argName, bdHolder.getBeanName(), bdHolder.getBeanDefinition());
   }
   else if (value instanceof BeanDefinition) {
      // Resolve plain BeanDefinition, without contained name: use dummy name.
      BeanDefinition bd = (BeanDefinition) value;
      String innerBeanName = "(inner bean)" + BeanFactoryUtils.GENERATED_BEAN_NAME_SEPARATOR +
            ObjectUtils.getIdentityHexString(bd);
      return resolveInnerBean(argName, innerBeanName, bd);
   }
   // 对ManagedArray进行解析
   else if (value instanceof ManagedArray) {
      // May need to resolve contained runtime references.
      ManagedArray array = (ManagedArray) value;
      Class<?> elementType = array.resolvedElementType;
      if (elementType == null) {
         String elementTypeName = array.getElementTypeName();
         if (StringUtils.hasText(elementTypeName)) {
            try {
               elementType = ClassUtils.forName(elementTypeName, this.beanFactory.getBeanClassLoader());
               array.resolvedElementType = elementType;
            }
            catch (Throwable ex) {
               // Improve the message by showing the context.
               throw new BeanCreationException(
                     this.beanDefinition.getResourceDescription(), this.beanName,
                     "Error resolving array type for " + argName, ex);
            }
         }
         else {
            elementType = Object.class;
         }
      }
      return resolveManagedArray(argName, (List<?>) value, elementType);
   }
  // 对ManagedList进行解析
   else if (value instanceof ManagedList) {
      // May need to resolve contained runtime references.
      return resolveManagedList(argName, (List<?>) value);
   }
   // 对ManagedSet进行解析
   else if (value instanceof ManagedSet) {
      // May need to resolve contained runtime references.
      return resolveManagedSet(argName, (Set<?>) value);
   }
   // 对ManagedMap进行解析
   else if (value instanceof ManagedMap) {
      // May need to resolve contained runtime references.
      return resolveManagedMap(argName, (Map<?, ?>) value);
   }
   // 对ManagedProperties进行解析
   else if (value instanceof ManagedProperties) {
      Properties original = (Properties) value;
      Properties copy = new Properties();
      for (Map.Entry<Object, Object> propEntry : original.entrySet()) {
         Object propKey = propEntry.getKey();
         Object propValue = propEntry.getValue();
         if (propKey instanceof TypedStringValue) {
            propKey = evaluate((TypedStringValue) propKey);
         }
         if (propValue instanceof TypedStringValue) {
            propValue = evaluate((TypedStringValue) propValue);
         }
         copy.put(propKey, propValue);
      }
      return copy;
   }
   // 对TypedStringValue进行解析
   else if (value instanceof TypedStringValue) {
      // Convert value to target type here.
      TypedStringValue typedStringValue = (TypedStringValue) value;
      Object valueObject = evaluate(typedStringValue);
      try {
         Class<?> resolvedTargetType = resolveTargetType(typedStringValue);
         if (resolvedTargetType != null) {
            return this.typeConverter.convertIfNecessary(valueObject, resolvedTargetType);
         }
         else {
            return valueObject;
         }
      }
      catch (Throwable ex) {
         // Improve the message by showing the context.
         throw new BeanCreationException(
               this.beanDefinition.getResourceDescription(), this.beanName,
               "Error converting typed String value for " + argName, ex);
      }
   }
   else {
      return evaluate(value);
   }
}
```

第一个if条件中的代码，表示对于RuntimeBeanReference类型的注入在resolveReference中。

```java

private Object resolveReference(Object argName, RuntimeBeanReference ref) {
   try {
      // 从reference名字，这个refName实在载入BeanDefinition时根据配置生成的
      String refName = ref.getBeanName();
      refName = String.valueOf(doEvaluate(refName));
      // 如果ref是在双亲IOC容器中，那就到双亲IOC容器中获取
      if (ref.isToParent()) {
         if (this.beanFactory.getParentBeanFactory() == null) {
            throw new BeanCreationException(
                  this.beanDefinition.getResourceDescription(), this.beanName,
                  "Can't resolve reference to bean '" + refName +
                  "' in parent factory: no parent factory available");
         }
         return this.beanFactory.getParentBeanFactory().getBean(refName);
      }
      // 在当前IOC容器中获取Bean，这里会触发一个getBean的过程，如果依赖注入没有发生，
      // 这里会触发相应的依赖注入的发生
      else {
         Object bean = this.beanFactory.getBean(refName);
         this.beanFactory.registerDependentBean(refName, this.beanName);
         return bean;
      }
   }
   catch (BeansException ex) {
      throw new BeanCreationException(
            this.beanDefinition.getResourceDescription(), this.beanName,
            "Cannot resolve reference to bean '" + ref.getBeanName() + "' while setting " + argName, ex);
   }
}
```

对managedList的处理过程。

```java

private List<?> resolveManagedList(Object argName, List<?> ml) {
   List<Object> resolved = new ArrayList<Object>(ml.size());
   for (int i = 0; i < ml.size(); i++) {
      // 通过递归的方式，对List的元素进行解析
      resolved.add(
            resolveValueIfNecessary(new KeyedArgName(argName, i), ml.get(i)));
   }
   return resolved;
}
```

完成这个解析过程后，也即是BeanDefinitionValueResolver的resolveValueIfNecessary()方法中的相关内容执行完成后，
这个时候未依赖注入准备好了条件，这是真正把Bean对象设置到所有依赖的因一个Bean属性中的地方，其中处理的属性是各种各样的。

依赖注入的发生在BeanWrapperImpl中实现的。

bean属性注入通过setPropertyValues()方法完成，这是PropertyAccessor接口方法，实现类是AbstractPropertyAccessor，看一下调用的源码。

AbstractPropertyAccessor.setPropertyValues()方法源码：

调用入口
```java
@Override
public void setPropertyValues(PropertyValues pvs) throws BeansException {
   setPropertyValues(pvs, false, false);
}
```

```java

@Override
public void setPropertyValues(PropertyValues pvs, boolean ignoreUnknown, boolean ignoreInvalid)
      throws BeansException {
 
   List<PropertyAccessException> propertyAccessExceptions = null;
   // 得到属性列表
   List<PropertyValue> propertyValues = (pvs instanceof MutablePropertyValues ?
         ((MutablePropertyValues) pvs).getPropertyValueList() : Arrays.asList(pvs.getPropertyValues()));
   for (PropertyValue pv : propertyValues) {
      try {
         // This method may throw any BeansException, which won't be caught
         // here, if there is a critical failure such as no matching field.
         // We can attempt to deal only with less serious exceptions.
         // 属性注入
         setPropertyValue(pv);
      }
      catch (NotWritablePropertyException ex) {
         if (!ignoreUnknown) {
            throw ex;
         }
         // Otherwise, just ignore it and continue...
      }
      catch (NullValueInNestedPathException ex) {
         if (!ignoreInvalid) {
            throw ex;
         }
         // Otherwise, just ignore it and continue...
      }
      catch (PropertyAccessException ex) {
         if (propertyAccessExceptions == null) {
            propertyAccessExceptions = new LinkedList<PropertyAccessException>();
         }
         propertyAccessExceptions.add(ex);
      }
   }
 
   // If we encountered individual exceptions, throw the composite exception.
   if (propertyAccessExceptions != null) {
      PropertyAccessException[] paeArray =
            propertyAccessExceptions.toArray(new PropertyAccessException[propertyAccessExceptions.size()]);
      throw new PropertyBatchUpdateException(paeArray);
   }
}
代码追溯到：

protected void setPropertyValue(PropertyTokenHolder tokens, PropertyValue pv) throws BeansException {
   if (tokens.keys != null) {
      processKeyedProperty(tokens, pv);
   }
   else {
      processLocalProperty(tokens, pv);
   }
}
```
最后到在processKeyedProperty中完成依赖注入的处理：
```java
private void processKeyedProperty(PropertyTokenHolder tokens, PropertyValue pv) {
   Object propValue = getPropertyHoldingValue(tokens);
   String lastKey = tokens.keys[tokens.keys.length - 1];
 
   if (propValue.getClass().isArray()) {
      PropertyHandler ph = getLocalPropertyHandler(tokens.actualName);
      Class<?> requiredType = propValue.getClass().getComponentType();
      int arrayIndex = Integer.parseInt(lastKey);
      Object oldValue = null;
      try {
         if (isExtractOldValueForEditor() && arrayIndex < Array.getLength(propValue)) {
            oldValue = Array.get(propValue, arrayIndex);
         }
         Object convertedValue = convertIfNecessary(tokens.canonicalName, oldValue, pv.getValue(),
               requiredType, ph.nested(tokens.keys.length));
         int length = Array.getLength(propValue);
         if (arrayIndex >= length && arrayIndex < this.autoGrowCollectionLimit) {
            Class<?> componentType = propValue.getClass().getComponentType();
            Object newArray = Array.newInstance(componentType, arrayIndex + 1);
            System.arraycopy(propValue, 0, newArray, 0, length);
            setPropertyValue(tokens.actualName, newArray);
            propValue = getPropertyValue(tokens.actualName);
         }
         Array.set(propValue, arrayIndex, convertedValue);
      }
      catch (IndexOutOfBoundsException ex) {
         throw new InvalidPropertyException(getRootClass(), this.nestedPath + tokens.canonicalName,
               "Invalid array index in property path '" + tokens.canonicalName + "'", ex);
      }
   }
 
   else if (propValue instanceof List) {
      PropertyHandler ph = getPropertyHandler(tokens.actualName);
      Class<?> requiredType = ph.getCollectionType(tokens.keys.length);
      List<Object> list = (List<Object>) propValue;
      int index = Integer.parseInt(lastKey);
      Object oldValue = null;
      if (isExtractOldValueForEditor() && index < list.size()) {
         oldValue = list.get(index);
      }
      Object convertedValue = convertIfNecessary(tokens.canonicalName, oldValue, pv.getValue(),
            requiredType, ph.nested(tokens.keys.length));
      int size = list.size();
      if (index >= size && index < this.autoGrowCollectionLimit) {
         for (int i = size; i < index; i++) {
            try {
               list.add(null);
            }
            catch (NullPointerException ex) {
               throw new InvalidPropertyException(getRootClass(), this.nestedPath + tokens.canonicalName,
                     "Cannot set element with index " + index + " in List of size " +
                     size + ", accessed using property path '" + tokens.canonicalName +
                     "': List does not support filling up gaps with null elements");
            }
         }
         list.add(convertedValue);
      }
      else {
         try {
            list.set(index, convertedValue);
         }
         catch (IndexOutOfBoundsException ex) {
            throw new InvalidPropertyException(getRootClass(), this.nestedPath + tokens.canonicalName,
                  "Invalid list index in property path '" + tokens.canonicalName + "'", ex);
         }
      }
   }
 
   else if (propValue instanceof Map) {
      PropertyHandler ph = getLocalPropertyHandler(tokens.actualName);
      Class<?> mapKeyType = ph.getMapKeyType(tokens.keys.length);
      Class<?> mapValueType = ph.getMapValueType(tokens.keys.length);
      Map<Object, Object> map = (Map<Object, Object>) propValue;
      // IMPORTANT: Do not pass full property name in here - property editors
      // must not kick in for map keys but rather only for map values.
      TypeDescriptor typeDescriptor = TypeDescriptor.valueOf(mapKeyType);
      Object convertedMapKey = convertIfNecessary(null, null, lastKey, mapKeyType, typeDescriptor);
      Object oldValue = null;
      if (isExtractOldValueForEditor()) {
         oldValue = map.get(convertedMapKey);
      }
      // Pass full property name and old value in here, since we want full
      // conversion ability for map values.
      Object convertedMapValue = convertIfNecessary(tokens.canonicalName, oldValue, pv.getValue(),
            mapValueType, ph.nested(tokens.keys.length));
      map.put(convertedMapKey, convertedMapValue);
   }
 
   else {
      throw new InvalidPropertyException(getRootClass(), this.nestedPath + tokens.canonicalName,
            "Property referenced in indexed property path '" + tokens.canonicalName +
            "' is neither an array nor a List nor a Map; returned value was [" + propValue + "]");
   }
}
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
