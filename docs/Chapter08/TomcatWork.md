# tomcat的三种工作模式

## Tomcat 的连接器有两种：HTTP和AJP

####  AJP(Apache JServ Protocol):

AJP是面向数据包的基于TCP/IP的协议，它在Apache和Tomcat的实例之间提供了一个专用的通信信道

主要有以下特征：

> 1) 在快速网络有着较好的性能表现，支持数据压缩传输；
   2) 支持SSL，加密及客户端证书；
   3) 支持Tomcat实例集群；
   4) 支持在apache和tomcat之间的连接的重用；
   


## Tomcat Connector(连接器)有三种运行模式：bio nio apr

一、bio(blocking I/O)

即阻塞式I/O操作，表示Tomcat使用的是传统的Java I/O操作(即java.io包及其子包)。是基于JAVA的HTTP/1.1连接器，Tomcat7以下版本在默认情况下是以bio模式运行的。一般而言，bio模式是三种运行模式中性能最低的一种。我们可以通过Tomcat Manager来查看服务器的当前状态。（Tomcat7 或以下，在 Linux 系统中默认使用这种方式）

一个线程处理一个请求，缺点：并发量高时，线程数较多，浪费资源


二、nio(new I/O)

是Java SE 1.4及后续版本提供的一种新的I/O操作方式(即java.nio包及其子包)。Java nio是一个基于缓冲区、并能提供非阻塞I/O操作的Java API，因此nio也被看成是non-blocking I/O的缩写。它拥有比传统I/O操作(bio)更好的并发运行性能。要让Tomcat以nio模式来运行只需要在Tomcat安装目录/conf/server.xml 中将对应的中protocol的属性值改为 org.apache.coyote.http11.Http11NioProtocol即可

利用 Java 的异步请求 IO 处理，可以通过少量的线程处理大量的请求

注意： Tomcat8 以上版本在 Linux 系统中，默认使用的就是NIO模式，不需要额外修改 ，Tomcat7必须修改Connector配置来启动

三、apr(Apache Portable Runtime/Apache可移植运行时) （ 安装配置过程相对复杂）

Tomcat将以JNI的形式调用Apache HTTP服务器的核心动态链接库来处理文件读取或网络传输操作，从而大大地提高Tomcat对静态文件的处理性能。Tomcat apr也是在Tomcat上运行高并发应用的首选模式。从操作系统级别来解决异步的IO问题

APR是使用原生C语言编写的非堵塞I/O，利用了操作系统的网络连接功能，速度很快。
但是需先安装apr和native，若直接启动就支持apr，能大幅度提升性能，不亚于魔兽开局爆高科技兵种，威力强大

