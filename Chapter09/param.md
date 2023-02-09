# mybatis中为什么映射一个参数不需要对应名称，而多个参数需要



我们从源码中一探究竟，这是为什么？

通过一步步跟踪，跟踪到了MappedMethod.convertArgsToSqlCommandParam方法。

该源码如下

```
```

