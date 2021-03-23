# spring boot与spring mvc的区别是什么？

所以，用最简练的语言概括就是：

Spring 是一个“引擎”；

Spring MVC 是基于Spring的一个 MVC 框架 ；

Spring Boot 是基于Spring4的条件注册的一套快速开发整合包。

   发现很多小伙伴不清楚springboot 和 springmvc 的区别，事实上从功能和本质上来讲，这2者没有任何关系。如果非要说有什么关系，那就是都属于spring家族的。

     什么是springboot : 一个自动配置化的工具

     什么是springmvc: 一个web框架

    那为什么2个毫无关系的框架会很容易发生混淆？

因为当springboot 嵌入springmvc的时候很多人以为它就是另一种web框架了，这是一种误区。事实上它和原有的springmvc相比只不过是将原有的配置在xml文件中的内容做了自动化配置而已。

       springboot 只不过将原有的与spring匹配的配置采用约定大于配置的方式进行自动化加载而已，使开发变得更加简单、方便。例如springboot嵌入mybatis等orm框架时，需要自动加载DataSource,约定的配置为spring.datasource.type 来配置对应的数据源，通过spring.datasource.driverClassName 来配置对应的驱动类名。通常我们想要将自己的模块嵌入springboot的时候只需要加入对应的 starter 即可，例如一些常见的 starter：

