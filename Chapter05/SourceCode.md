# 源码解析

## 一、sun.misc.VM.getSavedProperty和System.getProperty的区别是什么

java运行的设置：

```
-Djava.lang.Integer.IntegerCache.high=250
-Dhigh=250
```

```java
public static void main(String[] args) {
		String a = sun.misc.VM.getSavedProperty("java.lang.Integer.IntegerCache.high");
		String b = sun.misc.VM.getSavedProperty("high");
		String c = System.getProperty("java.lang.Integer.IntegerCache.high");
		String d = System.getProperty("high");
		System.err.println(a);
		System.err.println(b);
		System.err.println(c);
		System.err.println(d);
}
```
结果：
250
250
null
250

为什么对于java.lang.Integer.IntegerCache.high这个设置的参数值用System.getProperty获取不到，
但是用sun.misc.VM.getSavedProperty是可以获取到的？

#### 原因如下：
为了将JVM系统所需要的参数和用户使用的参数区别开，
java.lang.System.initializeSystemClass在启动时，会将启动参数保存在两个地方：

1、sun.misc.VM.savedProps中保存全部JVM接收的系统参数。
  JVM会在启动时，调用java.lang.System.initializeSystemClass方法，初始化该属性。
  同时也会调用sun.misc.VM.saveAndRemoveProperties方法，从java.lang.System.props中删除以下属性：
  
```
  sun.nio.MaxDirectMemorySize
  sun.nio.PageAlignDirectMemory
  sun.lang.ClassLoader.allowArraySyntax
  java.lang.Integer.IntegerCache.high
  sun.zip.disableMemoryMapping
  sun.java.launcher.diag
```
  以上罗列的属性都是JVM启动需要设置的系统参数，所以为了安全考虑和隔离角度考虑，将其从用户可访问的System.props分开。
  
2、java.lang.System.props中保存除了以下JVM启动需要的参数外的其他参数。
```
sun.nio.MaxDirectMemorySize
sun.nio.PageAlignDirectMemory
sun.lang.ClassLoader.allowArraySyntax
java.lang.Integer.IntegerCache.high
sun.zip.disableMemoryMapping
sun.java.launcher.diag
```