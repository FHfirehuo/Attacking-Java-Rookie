# 分布式集群中为什么会有 Master

在分布式环境中，有些业务逻辑只需要集群中的某一台机器进行执行，其他的机 器可以共享这个结果，

这样可以大大减少重复计算，提高性能，于是就需要进行leader 选举。