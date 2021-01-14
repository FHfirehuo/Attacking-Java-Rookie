# 深入分析java中的enum

## 枚举类介绍

如果一个类的实例是有限且确定的，那么可以使用枚举类。比如：季节类，只有春夏秋冬四个实例。

枚举类使用enum进行创建，其实例必须从”第一行“开始显示写出。

```
enum Season{
　　 SPRING,SUMMER,FALL,WINTER;

}
```

* 枚举类的构造器都是private,所以无法在外部创建其实例，这也决定了枚举类实例的个数的确定性（写了几个就是几个）。
* enum类默认extends java.lang.Enum,所以无法再继承其他类

## enum为什么不能被继承

> 有一种说法是 枚举类的对象默认都是public static final。


这个经过实验是不对的，因为枚举类不能被final修饰。这个再编译阶段就是错误。

但枚举类使用enum定义后在编译后默认继承了java.lang.Enum类，而不是普通的继承Object类。
enum声明类继承了Serializable和Comparable两个接口。且采用enum声明后，
该类会被编译器加上"final"声明（同String），故该类是无法继承的。
枚举类的内部定义的枚举值就是该类的实例（且必须在第一行定义，当类初始化时，这些枚举值会被实例化）。
由于这些枚举值的实例化是在类初始化阶段，所以应该将枚举类的构造器（如果存在），采用private声明（这种情况下默认也是private）。