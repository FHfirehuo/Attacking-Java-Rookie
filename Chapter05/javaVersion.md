# 从JDK8飞升到JDK17

长期支持版本 8，11， 17

# JDK9新特性（2017年9月）

- 模块化
- 提供了List.of()、Set.of()、Map.of()和Map.ofEntries()等工厂方法
- 接口支持私有方法
- Optional 类改进
- 多版本兼容Jar包
- JShell工具
- try-with-resources的改进
- Stream API的改进
- 设置G1为JVM默认垃圾收集器
- 支持http2.0和websocket的API

**重要特性：主要是API的优化，如支持HTTP2的Client API、JVM采用G1为默认垃圾收集器**



# JDK10新特性（2018年3月）

- 局部变量类型推断，类似JS可以通过var来修饰局部变量，编译之后会推断出值的真实类型
- 不可变集合的改进
- 并行全垃圾回收器 G1，来优化G1的延迟
- 线程本地握手，允许在不执行全局VM安全点的情况下执行线程回调，可以停止单个线程，而不需要停止所有线程或不停止线程
- Optional新增orElseThrow()方法
- 类数据共享
- Unicode 语言标签扩展
- 根证书

**重要特性：通过var关键字实现局部变量类型推断，使Java语言变成弱类型语言、JVM的G1垃圾回收由单线程改成多线程并行处理，降低G1的停顿时间**



# JDK11新特性（2018年9月）（LTS版本）

- 增加一些字符串处理方法
- 用于 Lambda 参数的局部变量语法
- Http Client重写，支持HTTP/1.1和HTTP/2 ，也支持 websockets
- 可运行单一Java源码文件，如：java Test.java
- ZGC：可伸缩低延迟垃圾收集器，ZGC可以看做是G1之上更细粒度的内存管理策略。由于内存的不断分配回收会产生大量的内存碎片空间，因此需要整理策略防止内存空间碎片化，在整理期间需要将对于内存引用的线程逻辑暂停，这个过程被称为"Stop the world"。只有当整理完成后，线程逻辑才可以继续运行。（并行回收）
- 支持 TLS 1.3 协议
- Flight Recorder（飞行记录器），基于OS、JVM和JDK的事件产生的数据收集框架
- 对Stream、Optional、集合API进行增强

重要特性：对于JDK9和JDK10的完善，主要是对于Stream、集合等API的增强、新增ZGC垃圾收集器



# JDK12新特性（2019年3月）

- Switch 表达式扩展，可以有返回值
- 新增NumberFormat对复杂数字的格式化
- 字符串支持transform、indent操作
- 新增方法Files.mismatch(Path, Path)
- Teeing Collector
- 支持unicode 11
- Shenandoah GC，新增的GC算法
- G1收集器的优化，将GC的垃圾分为强制部分和可选部分，强制部分会被回收，可选部分可能不会被回收，提高GC的效率

**重要特性：switch表达式语法扩展、G1收集器优化、新增Shenandoah GC垃圾回收算法**

# JDK13新特性（2019年9月）

- Switch 表达式扩展，switch表达式增加yield关键字用于返回结果，作用类似于return，如果没有返回结果则使用break
- 文本块升级 """ ，引入了文本块，可以使用"""三个双引号表示文本块，文本块内部就不需要使用换行的转义字符
- SocketAPI 重构，Socket的底层实现优化，引入了NIO
- FileSystems.newFileSystem新方法
- ZGC优化，增强 ZGC 释放未使用内存，将标记长时间空闲的堆内存空间返还给操作系统，保证堆大小不会小于配置的最小堆内存大小，如果堆最大和最小内存大小设置一样，则不会释放内存还给操作系统



**重要特性：ZGC优化，释放内存还给操作系统、socket底层实现引入NIO**

# JDK14新特性（2020年3月）

- instanceof模式匹配，instanceof类型匹配语法简化，可以直接给对象赋值，如if(obj instanceof String str),如果obj是字符串类型则直接赋值给了str变量
- 引入Record类型，类似于Lombok 的@Data注解，可以向Lombok一样自动生成构造器、equals、getter等方法；
- Switch 表达式-标准化
- 改进 NullPointerExceptions提示信息，打印具体哪个方法抛的空指针异常，避免同一行代码多个函数调用时无法判断具体是哪个函数抛异常的困扰，方便异常排查；
- 删除 CMS 垃圾回收器

# JDK15新特性（2020年9月）

- EdDSA 数字签名算法
- Sealed Classes（封闭类，预览），通过sealed关键字修饰抽象类限定只允许指定的子类才可以实现或继承抽象类，避免抽象类被滥用
- Hidden Classes（隐藏类）
- 移除 Nashorn JavaScript引擎
- 改进java.net.DatagramSocket 和 java.net.MulticastSocket底层实现



# JDK16新特性（2021年3月）

- 允许在 JDK C ++源代码中使用 C ++ 14功能
- ZGC性能优化，去掉ZGC线程堆栈处理从安全点到并发阶段
- 增加 Unix 域套接字通道
- 弹性元空间能力
- 提供用于打包独立 Java 应用程序的 jpackage 工具

**JDK16相当于是将JDK14、JDK15的一些特性进行了正式引入，如instanceof模式匹配（Pattern matching）、record的引入等**最终到JDK16变成了final版本



# JDK17新特性（2021年9月）（LTS版本）

- Free Java License
- JDK 17 将取代 JDK 11 成为下一个长期支持版本
- Spring 6 和 Spring Boot 3需要JDK17
- 移除实验性的 AOT 和 JIT 编译器
- 恢复始终执行严格模式 (Always-Strict) 的浮点定义
- 正式引入密封类sealed class，限制抽象类的实现
- 统一日志异步刷新，先将日志写入缓存，然后再异步刷新

**虽然JDK17也是一个LTS版本，但是并没有像JDK8和JDK11一样引入比较突出的特性，主要是对前几个版本的整合和完善。**



# 重要特性详解

# Java 模块化

JPMS（Java Platform Module System）是Java 9发行版的核心亮点。它也被称为Jigshaw项目。模块是新的结构，就像我们已经有包一样。使用新的模块化编程开发的应用程序可以看作是交互模块的集合，这些模块之间具有明确定义的边界和依赖关系。

JPMS包括为编写模块化应用程序提供支持，以及将JDK源代码模块化。JDK 9 附带了大约 92 个模块（在 GA 版本中可以进行更改）。Java 9 Module System有一个**"java.base"**模块。它被称为基本模块。它是一个独立的模块，不依赖于任何其他模块。默认情况下，所有其他模块都依赖于"java.base"。

在java模块化编程中：

- 一个模块通常只是一个 jar 文件，在根目录下有一个文件module-info.class。
- 要使用模块，请将 jar 文件包含到modulepath而不是classpath. 添加到类路径的模块化 jar 文件是普通的 jar 文件，module-info.class文件将被忽略。

典型的module-info.java类如下所示：

```
module helloworld {     
    exports com.alibaba.eight; 
} 
module test {     
    requires helloworld; 
}
```

**总结：模块化的目的，是让jdk的各个组件可以被分拆，复用和替换重写，**比如对java的gui不满意，可以自己实现一个gui，对java的语法不满意，可以把javac替换成其他语言和其他语言的编译器，比如kotlin和kotlinc等，没有模块化，几乎很难实现，每次修改某个模块，总不能把整个jdk给重新编译一遍，再发布一个整个sdk吧，模块化可以帮助更有效的定制化和部署



# 本地变量类型推断

在Java 10之前版本中，我们想定义定义局部变量时。我们需要在赋值的左侧提供显式类型，并在赋值的右边提供实现类型：

MyObject value = new MyObject();

在Java 10中，提供了本地变量类型推断的功能，可以通过var声明变量：

var value = new MyObject();

本地变量类型推断将引入“var”关键字，而不需要显式的规范变量的类型。

其实，所谓的本地变量类型推断，也是Java 10提供给开发者的语法糖。

虽然我们在代码中使用var进行了定义，但是对于虚拟机来说他是不认识这个var的，在java文件编译成class文件的过程中，会进行解糖，使用变量真正的类型来替代var



# HTTP客户端API-响应式流实现的HttpClient

Java 使用HttpURLConnection进行HTTP通信已经很长一段时间了。但随着时间的推移，要求变得越来越复杂，应用程序的要求也越来越高。在 Java 11 之前，开发人员不得不求助于功能丰富的库，如*Apache HttpComponents*或*OkHttp*等。

我们看到Java 9发布包含一个HttpClient实现作为实验性功能。它随着时间的推移而发展，现在是 Java 11 的最终功能。现在 Java 应用程序可以进行 HTTP 通信，而无需任何外部依赖。

作为JDK11中正式推出的新Http连接器，支持的功能还是比较新的，主要的特性有：

- 完整支持HTTP 2.0 或者HTTP 1.1
- 支持 HTTPS/TLS
- 有简单的阻塞使用方法
- 支持异步发送，异步时间通知
- 支持WebSocket
- 支持响应式流

HTTP2.0其他的客户端也能支持，而HttpClient使用CompletableFuture作为异步的返回数据。WebSocket的支持则是HttpClient的优势。响应式流的支持是HttpClient的一大优势。

HttpClient中的NIO模型、函数式编程、CompletableFuture异步回调、响应式流让HttpClient拥有极强的并发处理能力，所以其性能极高，而内存占用则更少。



# 语法糖

# Stream API 改进

# Collectors.teeing()

teeing 收集器已公开为静态方法**Collectors::teeing**。该收集器将其输入转发给其他两个收集器，然后将它们的结果使用函数合并。

**示例：**

```
List<Student> list = Arrays.asList(
        new Student("唐一", 55),
        new Student("唐二", 60),
        new Student("唐三", 90));
//平均分 总分
String result = list.stream().collect(Collectors.teeing(
        Collectors.averagingInt(Student::getScore),
        Collectors.summingInt(Student::getScore),
        (s1, s2) -> s1 + ":" + s2));
//最低分  最高分
String result2 = list.stream().collect(Collectors.teeing(
        Collectors.minBy(Comparator.comparing(Student::getScore)),
        Collectors.maxBy(Comparator.comparing(Student::getScore)),
        (s1, s2) -> s1.orElseThrow() + ":" + s2.orElseThrow()
));
System.out.println(result);
System.out.println(result2);
```



# 添加Stream.toList方法(jdk16)

```
List<String> list = Arrays.asList("1", "2", "3");
//之前这样写
List<Integer> oneList = list.stream()
    .map(Integer::parseInt)
    .collect(Collectors.toList());
//现在可以这样写
List<Integer> twoList = list.stream()
    .map(Integer::parseInt)
    .toList();
```



# Switch表达式改进

支持箭头表达式（jdk12预览 jdk14标准）

此更改扩展了switch 语句以便它可以用作语句或表达式。不必为break每个 case 块定义一个语句，我们可以简单地使用**箭头语法**

```
boolean isWeekend = switch (day) {
  case MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY -> false; 
  case SATURDAY, SUNDAY -> true;
  default -> throw new IllegalStateException("Illegal day entry :: " + day);
};
int size = 3;
String cn = switch (size) {
    case 1 -> "壹";
    case 2 -> "贰";
    case 3, 4 -> "叁";
    default -> "未知";
};
System.out.println(cn);
```

//要使用此预览功能，我们必须在应用程序启动期间使用–enable-preview标志明确指示 JVM。

yield关键字（jdk13）

使用yield，我们现在可以有效地从 switch 表达式返回值，并能够更容易实现策略模式。

```
public class SwitchTest {
    public static void main(String[] args) {
        var me = 4;
        var operation = "平方";
        var result = switch (operation) {
            case "加倍" -> {
                yield me * 2;
            }
            case "平方" -> {
                yield me * me;
            }
            default -> me;
        };
        System.out.println(result);
    }
}
```



# 字符串

# 文本块改进（jdk13）

早些时候，为了在我们的代码中嵌入 JSON，我们将其声明为*字符串*文字：

String json = "{\r\n" + "\"name\" : \"lingli\",\r\n" + "\"website\" : \"https://www.alibaba.com/\"\r\n" + "}";



*现在让我们使用字符串*文本块编写相同的 JSON ：

```
String json = """ 
{     
    "name" : "Baeldung",     
    "website" : "https://www.alibaba.com/" 
} 
""";
```

很明显，不需要转义双引号或添加回车。通过使用文本块，嵌入的 JSON 更易于编写，更易于阅读和维护。



# 更多的API

- isBlank()：如果字符串为空或字符串仅包含空格（包括制表符），则返回 true。注意与isEmpty() 不同，isEmpty()仅在长度为 0 时返回 true。
- lines()：将字符串拆分为字符串流，每个字符串包含一行。
- strip() ： 分别从开头和结尾；
- stripLeading()/stripTrailing()仅开始和仅结束删除空格。
- repeat(int times)：返回一个字符串，该字符串采用原始字符串并按指定的次数重复该字符串。
- readString()：允许从文件路径直接读取到字符串。
- writeString(Path path)：将字符串直接写入指定路径处的文件。
- indent(int level)：缩进字符串的指定量。负值只会影响前导空格。
- transform(Function f)：将给定的 lambda 应用于字符串。