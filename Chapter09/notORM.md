# 为什么说MyBatis不是完整的ORM框架

ORM是Object和Relation之间的映射，包括Object->Relation和Relation->Object两方面。Hibernate是个完整的ORM框架，而MyBatis完成的是Relation->Object，也就是其所说的Data Mapper Framework。

JPA是ORM框架标准，主流的ORM框架都实现了这个标准。MyBatis没有实现JPA，它和ORM框架的设计思路不完全一样。MyBatis是拥抱SQL，而ORM则更靠近面向对象，不建议写SQL，实在要写，则推荐你用框架自带的类SQL代替。MyBatis是SQL映射框架而不是ORM框架，当然ORM和MyBatis都是持久层框架。

最典型的ORM 框架是Hibernate，它是全自动ORM框架，而MyBatis是半自动的。Hibernate完全可以通过对象关系模型实现对数据库的操作，拥有完整的JavaBean对象与数据库的映射结构来自动生成SQL。而MyBatis仅有基本的字段映射，对象数据以及对象实际关系仍然需要通过手写SQL来实现和管理。

Hibernate数据库移植性远大于MyBatis。Hibernate通过它强大的映射结构和HQL语言，大大降低了对象与数据库（oracle、mySQL等）的耦合性，而MyBatis由于需要手写SQL，因此与数据库的耦合性直接取决于程序员写SQL的方法，如果SQL不具通用性而用了很多某数据库特性的SQL语句的话，移植性也会随之降低很多，成本很高。



## MyBatis-Plus弊端

MyBatis-Plus（简称 MP）是一个 MyBatis 的增强工具，在 MyBatis 的基础上做的增强，号称是"为简化开发、提高效率而生"。

为什么会诞生MyBatis-Plus这个东西呢？明眼人一猜就能明白，无非就是MyBatis有不足，MyBatis-Plus想做个增强，把MyBatis的不足给补上。

以彼之道，还彼之身。照此推理，既然连大名鼎鼎的MyBatis都有不足，那么MyBatis-Plus肯定也有不足，也有弊端。说白了，它补上了MyBatis的不足，同样也暴露了自身的不足。

使用MyBatis-Plus弊端有几个：

1. 增加了学习成本。mybatis功能已经足够强大，足以应付绝大多数的开发，再花费时间和精力去学习mybatis-plus，走取巧之路，有好的一面，肯定也有不好的一面。
2. 增加了升级和维护成本。mybatis升级之后，mybatis-plus还能不能用呢？如果不能用或者出现bug，这就是一个风险。
3. 造成团队分裂。一个团队，萝卜青菜各有所爱，mybatis是事实的标准，功能强大，全世界范围的程序员都在使用，mybatis-plus呢，未必所有的人都赞同使用这个工具。

综之，mybatis只是个orm框架，是对jdbc的封装，从它的初衷和使命来看，其已经非常强大，而且完美。