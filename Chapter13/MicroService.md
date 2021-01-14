# 微服务

微服务架构的问题？4步曲

1. 这么多服务，客户端如何去访问
2. 这么多服务，服务之间怎么通信
3. 这么多服务，怎么治理
4. 这么多服务，服务挂了怎么办
5. 服务是好的，网络出问题了怎么办

## SpringCloud

SpringCloud 不是一种技术，是一个生态或者说是一站式解决方案

#### spring cloud netflix 一站式解决方案

api: ---zuul

feign -- httpClient 同步阻塞

服务注册与发现 eureka

熔断机制 Hystrix

#### dubbo + zookeeper

ApI ： 没有 借助被人的或者自己写
Dubbo 异步非阻塞 RPC
服务注册与发现 zookeeper
熔断机制 没有借用 hystrix

#### springcloud alibab

## 下一代服务标准

目前又推出了新一代的服务标准Service Mesh （服务网格）
Istio 作为目前众多 Service Mesh 中最闪耀的新星 解决了网络问题
