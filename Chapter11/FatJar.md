# FatJar 的启动原理

SpringBoot在打包的时候会将依赖包也打进最终的Jar，变成一个可运行的FatJar。也就是会形成一个Jar in Jar的结构。
默认情况下，JDK提供的ClassLoader只能识别Jar中的class文件以及加载classpath下的其他jar包中的class文件。对于在jar包中的jar包是无法加载的。

## 储备知识

#### URLStreamHandler

java中描述资源常使用URL。而URL有一个方法用于打开链接java.net.URL#openConnection()。由于URL用于表达各种各样的资源，打开资源的具体动作由java.net.URLStreamHandler这个类的子类来完成。根据不同的协议，会有不同的handler实现。而JDK内置了相当多的handler实现用于应对不同的协议。比如jar、file、http等等。URL内部有一个静态HashTable属性，用于保存已经被发现的协议和handler实例的映射。

获得URLStreamHandler有三种方法

1. 实现URLStreamHandlerFactory接口，通过方法URL.setURLStreamHandlerFactory设置。该属性是一个静态属性，且只能被设置一次。
2. 直接提供URLStreamHandler的子类，作为URL的构造方法的入参之一。但是在JVM中有固定的规范要求：
3. 子类的类名必须是 Handler ，同时最后一级的包名必须是协议的名称。比如自定义了Http的协议实现，则类名必然为xx.http.Handler
4. JVM 启动的时候，需要设置 java.protocol.handler.pkgs 系统属性，如果有多个实现类，那么中间用 | 隔开。因为JVM在尝试寻找Handler时，会从这个属性中获取包名前缀，最终使用包名前缀.协议名.Handler，使用Class.forName方法尝试初始化类，如果初始化成功，则会使用该类的实现作为协议实现。

#### Archive

SpringBoot定义了一个接口用于描述资源，也就是org.springframework.boot.loader.archive.Archive。该接口有两个实现，分别是org.springframework.boot.loader.archive.ExplodedArchive和org.springframework.boot.loader.archive.JarFileArchive。
前者用于在文件夹目录下寻找资源，后者用于在jar包环境下寻找资源。而在SpringBoot打包的fatJar中，则是使用后者。

#### 打包

1. BOOT-INF文件夹下放的程序编译class和依赖的jar包
2. org目录下放的是SpringBoot的启动相关包。

来看描述文件MANIFEST.MF的内容

```
Manifest-Version: 1.0
Spring-Boot-Classpath-Index: BOOT-INF/classpath.idx
Implementation-Title: spring
Implementation-Version: 0.0.1-SNAPSHOT
Start-Class: io.github.firehuo.spring.Application
Spring-Boot-Classes: BOOT-INF/classes/
Spring-Boot-Lib: BOOT-INF/lib/
Build-Jdk-Spec: 1.8
Spring-Boot-Version: 2.3.4.RELEASE
Created-By: Maven Jar Plugin 3.2.0
Main-Class: org.springframework.boot.loader.JarLauncher


```

最为显眼的就是程序的启动类并不是我们项目的启动类，而是SpringBoot的JarLauncher。下面会来深究下这个类的作用。

## SpringBoot启动

首先来看启动方法

```
public static void main(String[] args) throws Exception {
        new JarLauncher().launch(args);
}
```

JarLauncher继承于org.springframework.boot.loader.ExecutableArchiveLauncher。该类的无参构造方法最主要的功能就是构建了当前main方法所在的FatJar的JarFileArchive对象。下面来看launch方法。该方法主要是做了2个事情：

1. 以FatJar为file作为入参，构造JarFileArchive对象。获取其中所有的资源目标，取得其Url，将这些URL作为参数，构建了一个URLClassLoader。
2. 以第一步构建的ClassLoader加载MANIFEST.MF文件中Start-Class指向的业务类，并且执行静态方法main。进而启动整个程序。

通过静态方法org.springframework.boot.loader.JarLauncher#main就可以顺利启动整个程序。这里面的关键在于SpringBoot自定义的classLoader能够识别FatJar中的资源，包括有：在指定目录下的项目编译class、在指令目录下的项目依赖jar。JDK默认用于加载应用的AppClassLoader只能从jar的根目录开始加载class文件，并且也不支持jar in jar这种格式。

为了实现这个目标，SpringBoot首先从支持jar in jar中内容读取做了定制，也就是支持多个!/分隔符的url路径。SpringBoot定制了以下两个方面：

1. 实现了一个java.net.URLStreamHandler的子类org.springframework.boot.loader.jar.Handler。该Handler支持识别多个!/分隔符，并且正确的打开URLConnection。打开的Connection是SpringBoot定制的org.springframework.boot.loader.jar.JarURLConnection实现。
2. 实现了一个java.net.JarURLConnection的子类org.springframework.boot.loader.jar.JarURLConnection。该链接支持多个!/分隔符，并且自己实现了在这种情况下获取InputStream的方法。而为了能够在org.springframework.boot.loader.jar.JarURLConnection正确获取输入流，SpringBoot自定义了一套读取ZipFile的工具类和方法。这部分和ZIP压缩算法规范紧密相连，就不深入了。

能够读取多个!/的url后，事情就变得很简单了。上文提到的ExecutableArchiveLauncher的launch方法会以当前的FatJar构建一个JarFileArchive，并且通过该对象获取其内部所有的资源URL，这些URL包含项目编译class和依赖jar包。在构建这些URL的时候传入的就是SpringBoot定制的Handler。将获取的URL数组作为参数传递给自定义的ClassLoaderorg.springframework.boot.loader.LaunchedURLClassLoader。该ClassLoader继承自UrlClassLoader。UrlClassLoader加载class就是依靠初始参数传入的Url数组，并且尝试Url指向的资源中加载Class文件。有了自定义的Handler，再从Url中尝试获取资源就变得很容易了。

至此，SpringBoot自定义的ClassLoader就能够加载FatJar中的依赖包的class文件了。

## 扩展
SpringBoot提供了一个很好的思路，但是其内部实现非常复杂，特别是其自行实现了一个ZipFIle的解析器。但是本质上这些背后的工作都是为了能够读取到FatJar内部的Jar的class文件资源。也就是只要有办法能够读取这些资源其实就可以实现加载Class文件了。而依靠JDK本身提供的JarFile其实就可以做到了。而读取到所有资源后，自定义一个ClassLoader加载读取到二进制数据进而定义Class对象并不是很难的项目实现。当然，SpringBoot定制的Zip解析可以在加载类阶段避免频繁的文件解压动作，在性能上良好一些。
