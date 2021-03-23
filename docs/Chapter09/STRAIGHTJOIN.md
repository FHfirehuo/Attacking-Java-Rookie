# MySQL基础之STRAIGHT JOIN用法简介



MySQL基础之STRAIGHT JOIN用法简介

引用[mysql官方手册](https://dev.mysql.com/doc/refman/8.0/en/join.html)的说法：

> STRAIGHT_JOIN is similar to JOIN, except that the left table is always read before the right table. This can be used for those (few) cases for which the join optimizer processes the tables in a suboptimal order.

翻译过来就是：STRAIGHT_JOIN与 JOIN 类似，只不过左表始终在右表之前读取。这可用于联接优化器以次优顺序处理表的那些（少数）情况。

**注意：总的来说STRAIGHT_JOIN只适用于内连接，因为left join、right join已经知道了哪个表作为驱动表，哪个表作为被驱动表，比如left join就是以左表为驱动表，right join反之，而STRAIGHT_JOIN就是在内连接中使用，而强制使用左表来当驱动表，所以这个特性可以用于一些调优，强制改变mysql的优化器选择的执行计划**

