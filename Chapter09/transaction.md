# mybatis 事物

Mybatis提供了一个事务接口`Transaction`以及两个实现类`jdbcTransaction`和`ManagedTransaction`。因此有两个类型

JDBC和managed。

（1）type为"JDBC"时，使用JdbcTransaction管理事务。
（2）type为"managed"时，使用ManagedTransaction管理事务（也就是交由外部容器管理）





1. type为"JDBC"时，及JdbcTransaction管理事务， 使用JDBC的事务管理机制，就是利用`java.sql.Connection`对象完成对事务的提交。
2. type为"managed"时， 及ManagedTransaction， 使用MANAGED的事务管理机制，此时MyBatis自身不会去实现事务管理，而是让程序的容器（JBOSS、WebLogic，spring）来实现对事务的管理

**总之，Mybatis的事务管理机制还是比较简单的，其并没有做过多的操作，只是封装一下方便别人调用而已。**



## SpringManagedTransaction 类

当Spring与Mybatis一起使用时，Spring提供了一个实现类`SpringManagedTransaction`。它其实也是通过使用JDBC来进行事务管理的，当Spring的事务管理有效时，不需要操作commit、rollback、close，Spring事务管理会自动帮我们完成。



## 源码分析

解析配置文件的transactionManager节点

```java
//org.apache.ibatis.builder.xml.XMLConfigBuilder
  
  private void environmentsElement(XNode context) throws Exception {
    if (context != null) {
      if (environment == null) {
        environment = context.getStringAttribute("default");
      }
      for (XNode child : context.getChildren()) {
        String id = child.getStringAttribute("id");
        if (isSpecifiedEnvironment(id)) {
          //只关注事务部分...
          TransactionFactory txFactory = transactionManagerElement(child.evalNode("transactionManager"));
          DataSourceFactory dsFactory = dataSourceElement(child.evalNode("dataSource"));
          DataSource dataSource = dsFactory.getDataSource();
          Environment.Builder environmentBuilder = new Environment.Builder(id)
              .transactionFactory(txFactory)
              .dataSource(dataSource);
          configuration.setEnvironment(environmentBuilder.build());
          break;
        }
      }
    }
  }

	//解析xml中事物的类型创建事物工厂
  private TransactionFactory transactionManagerElement(XNode context) throws Exception {
    if (context != null) {
      String type = context.getStringAttribute("type");
      Properties props = context.getChildrenAsProperties();
      TransactionFactory factory = (TransactionFactory) resolveClass(type).getDeclaredConstructor().newInstance();
      factory.setProperties(props);
      return factory;
    }
    throw new BuilderException("Environment declaration requires a TransactionFactory.");
  }
```

注意：两种事务工厂已经在mybatis初始化的时候完成了注册：

* typeAliasRegistry.registerAlias("JDBC", JdbcTransactionFactory.class);
* typeAliasRegistry.registerAlias("MANAGED", ManagedTransactionFactory.class);
* 

利用反射机制生成具体的的factory，此处以JdbcTransactionFactory为例，查看一下JdbcTransactionFactory的源码：