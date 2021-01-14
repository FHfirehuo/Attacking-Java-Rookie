# Java集合ArrayList中modCount详解及subList函数要点

modCount属性是从AbstractList抽象类继承而来的。
查看javadoc文档中的解释:

    The number of times this list has been structurally modified. Structural modifications are those that change the size of the list, or otherwise perturb it in such a fashion that iterations in progress may yield incorrect results.
    This field is used by the iterator and list iterator implementation returned by the iterator and listIterator methods. If the value of this field changes unexpectedly, the iterator (or list iterator) will throw a ConcurrentModificationException in response to the next, remove, previous, set or add operations. This provides fail-fast behavior, rather than non-deterministic behavior in the face of concurrent modification during iteration.

我们知道该参数用来记录集合被修改的次数，之所以要记录修改的次数，
是因为ArrayList不是线程安全的，
为了防止在使用迭代器和子序列的过程当中对原集合的修改导致迭代器及子序列的失效，
故保存了修改次数的记录，在迭代器的操作及子序列的操作过程当中，
会首先去检查modCount是否相等（函数checkForComodification()），
如果不想等的话，则说明集合被修改了，那么为了防止后续不明确的错误发生，
于是便抛出了该异常。为了防止该异常的出现，在使用迭代器进行集合的迭代是，
若要对集合进行修改，需要通过迭代器提供的对集合进行操作的函数来进行。



