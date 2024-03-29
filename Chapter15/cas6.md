# CAS客户端集成gateway

## 简介
CAS提供的客户端是基于Servlet写的，也就是说我们如果使用非Servlet应用，那么客户端是无法继承的，项目中使用没有使用Zuul来作为网关，而是使用Gateway，所以我们需要将原有的逻辑迁移到Gateway上

## 实现思路
根据查询原有客户端我们可以发现，客户端本质是一些Servlet拦截器，在拦截器中对登录和验证进行各种逻辑，而Gateway也提供了拦截器GlobalFilter，所以我们只要实现GlobalFilter将原有的逻辑迁移到GlobalFilter中并在Spring中注册将其作用到Gateway即可,并且将代码封装成starter实现开箱即用。

## Cas客户单总体流程图
我们在Servelt应用中集成CAS客户端主要使用的是Cas30ProxyReceivingTicketValidationFilter和AuthenticationFilter两个拦截器，通过查看源码我们可以发现Cas30ProxyReceivingTicketValidationFilter的主要作用是验证Ticket，就是登陆完成后服务端会下发给一个临时的Ticket来验证请求的正确性，用ST来表示，这个类主要用来验证ST和在处理代理模式下的逻辑**(代理模式：两个应用同时集成了cas客户单，现在A应用要通过http协议直接调用B应用的接口，类似于Nginx，如果是这这类请求走的验证Ticket逻辑是不一样的，CAS会生成PGT和PGTIOU，通过PGTIOU作为键来对应PGT来验证代理服务器时候之前已经认证过，代理这部分放在以后再说明)**,



## 核心源码分析
### Cas30ProxyReceivingTicketValidationFilter
上文说到Cas30ProxyReceivingTicketValidationFilter的核心作用是验证Ticket，而具体的验证逻辑由TicketValidator类来控制，我们可以在Cas30ProxyReceivingTicketValidationFilter的父类Cas20ProxyReceivingTicketValidationFilter中的getTicketValidator方法中查看初始化TicketValidator的逻辑，总体分为2总一种是初始化代理端的TicketValidator，另一种是初始化被代理端的TicketValidator，下面的注释已经说明，而getTicketValidator方法又会在初始化Cas30ProxyReceivingTicketValidationFilter时被调用。通过源码我们可以发现根据逻辑的不同其初始化了Cas20ServiceTicketValidator或者Cas20ProxyTicketValidator的ticket验证器，前者是作为代理端的ticket验证器(类似nginx)如果不设置代理用这个ticket验证器即可，后者是被代理端的验证器，处理被代理端的ticket验证逻辑

### 调用TicketValidator
我们查看Cas30ProxyReceivingTicketValidationFilter的父类AbstractTicketValidationFilter的doFilter方法，主要逻辑已经在下面代码中做出注释，那么现在我们要做的主要事情已经清晰，重写拦截器中根据不同的功能配置不同协议的TicketValidator（我采用的是CAS3协议对应的是Cas30ServiceTicketValidator和Cas30ProxyTicketValidator,前者作为代理服务端验证ticket的逻辑,后者作为验证被代理端的ticket逻辑）每种不同协议的实现类会调用Cas Service的对应协议的URL具体可以查看各个协议实现的TicketValidator的getUrlSuffix()方法,然后验证成功后再将信息存在缓存中

## 功能补充
### session
serlvet客户单中采用缓存在session中的方式来缓存用户信息，在gateway中没有session的概念，因此我用cookie来解决用户标识的问题，在用户完成验证后会往cookie中写入信息，在请求时带上cooike信息然后再redis中判断用户是否登录过来模拟实现session

### 单点登出
上面提到我是使用redis来当做分布式session来使用，那么单点登出实现的逻辑是在gateway中提供统一的单点退出接口，用户调用此接口后清除redies中缓存的信息，并且重定向到CAS Service 调用/logout方法，并且在url中带上service参数后面跟上退出成功后cas重定向到的地址，这样在清除掉本地缓存的时又清楚了CAS Service中缓存的TGT信息实现单点退出.
