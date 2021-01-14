# java 中的设计模式

Iterable 本身是迭代器模式里面的    

```java
default void forEach(Consumer<? super T> action) {
                            Objects.requireNonNull(action);
                            for (T t : this) {
                                action.accept(t);
                            }
                        }
```
其中action.accept(t)不是访问者模式
