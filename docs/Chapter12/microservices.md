任何一个大型项目，在发展到一定时期后由于其内部逻辑及功能模块的增多，就需要将业务及模块解耦进行模块化开发，每个模块折分成多个颗粒度较小的独立服务，这就是“微服务”。但是随着服务的折分，系统间的调用关系错综复杂，也会出现一些问题（比如出错了不好定位等），所以伴随微服务的还有服务治理，服务治里主要包括：鉴权、限流（也就是我们说的限制接口调用次数）、降级、熔断、监控等。



在微服务架构中，需要调用很多服务才能完成一项功能。服务之间如何互相调用就变成微服务架构中的一个关键问题。

服务调用有两种方式，一种是RPC方式，另一种是事件驱动（Event-driven）方式，也就是发消息方式。

消息方式是松耦合方式，比紧耦合的RPC方式要优越，但RPC方式如果用在适合的场景也有它的一席之地。

我们总在谈耦合，那么耦合到底意味着什么呢？



# 耦合的种类：



**时间耦合：**客户端和服务端必须同时上线才能工作。发消息时，接受消息队列必须运行，但后台处理程序暂时不工作也不影响。

**容量耦合：**客户端和服务端的处理容量必须匹配。发消息时，如果后台处理能力不足也不要紧，消息队列会起到缓冲的作用。

**接口耦合：**RPC调用有函数标签，而消息队列只是一个消息。例如买了商品之后要调用发货服务，如果是发消息，那么就只需发送一个商品被买消息。

**发送方式耦合：**RPC是点对点方式，需要知道对方是谁，它的好处是能够传回返回值。消息既可以点对点，也可以用广播的方式，这样减少了耦合，但也使返回值比较困难。

下面我们来逐一分析这些耦合的影响。第一，时间耦合，对于多数应用来讲，你希望能马上得到回答，因此即使使用消息队列，后台也需要一直工作。

第二，容量耦合，如果你对回复有时间要求，那么消息队列的缓冲功能作用不大，因为你希望及时响应。

真正需要的是自动伸缩（Auto-scaling），它能自动调整服务端处理能力去匹配请求数量。第三和第四，接口耦合和发送方式耦合，这两个确实是RPC方式的软肋。



# 事件驱动（Event-Driven）方式



Martin Fowler把事件驱动分成四种方式(What do you mean by “Event-Driven”)，简化之后本质上只有两种方式。一种就是我们熟悉的的事件通知（Event Notification），另一种是事件溯源（Event Sourcing）。

事件通知就是微服务之间不直接调用，而是通过发消息来进行合作。事件溯源有点像记账，它把所有的事件都记录下来，作为永久存储层，再在它的基础之上构建应用程序。

实际上从应用的角度来讲，它们并不应该分属一类，它们的用途完全不同。事件通知是微服务的调用（或集成）方式，应该和RPC分在一起。事件溯源是一种存储数据的方式，应该和数据库分在一起。



# 事件通知（Event Notification）方式





# 事件溯源(Event Sourcing)

这是一种具有颠覆性质的的设计，它把系统中所有的数据都以事件（Event）的方式记录下来，它的持久存储叫Event Store， 一般是建立在数据库或消息队列（例如Kafka）基础之上，并提供了对事件进行操作的接口，例如事件的读写和查询。事件溯源是由领域驱动设计(Domain-Driven Design)提出来的。

DDD中有一个很重要的概念，有界上下文（Bounded Context），可以用有界上下文来划分微服务，每个有界上下文都可以是一个微服务。



事件溯源是微服务的一种存储方式，它是微服务的内部实现细节。因此你可以决定哪些微服务采用事件溯源方式，哪些不采用，而不必所有的服务都变成事件溯源的。通常整个应用程序只有一个Event Store， 不同的微服务都通过向Event Store发送和接受消息而互相通信。

Event Store内部可以分成不同的stream（相当于消息队列中的Topic）， 供不同的微服务中的领域实体（Domain Entity）使用。

事件溯源的一个短板是数据查询，它有两种方式来解决。第一种是直接对stream进行查询，这只适合stream比较小并且查询比较简单的情况。

查询复杂的话，就要采用第二种方式，那就是建立一个只读数据库，把需要的数据放在库中进行查询。数据库中的数据通过监听Event Store中相关的事件来更新。

# 微服务的数量有没有上限？



总的来说微服务的数量不要太多，不然会有比较重的运维负担。有一点需要明确的是微服务的流行不是因为技术上的创新，而是为了满足管理上的需要。单体程序大了之后，各个模块的部署时间要求不同，对服务器的优化要求也不同，而且团队人数众多，很难协调管理。

把程序拆分成微服务之后，每个团队负责几个服务，就容易管理了，而且每个团队也可以按照自己的节奏进行创新，但它给运维带来了巨大的麻烦。所以在微服务刚出来时，我一直觉得它是一个退步，弊大于利。但由于管理上的问题没有其他解决方案，只有硬着头皮上了。

值得庆幸的是微服务带来的麻烦都是可解的。直到后来，微服务建立了全套的自动化体系，从程序集成到部署，从全链路跟踪到日志，以及服务检测，服务发现和注册，这样才把微服务的工作量降了下来。

虽然微服务在技术上一无是处，但它的流行还是大大推动了容器技术，服务网格（Service Mesh）和全链路跟踪等新技术的发展。不过它本身在技术上还是没有发现任何优势。

直到有一天，我意识到单体程序其实性能调试是很困难的（很难分离出瓶颈点），而微服务配置了全链路跟踪之后，能很快找到症结所在。看来微服务从技术来讲也不全是缺点，总算也有好的地方。但微服务的颗粒度不宜过细，否则工作量还是太大。

一般规模的公司十几个或几十个微服务都是可以承受的，但如果有几百个甚至上千个，那么绝不是一般公司可以管理的。尽管现有的工具已经很齐全了，而且与微服务有关的整个流程也已经基本上全部自动化了，但它还是会增加很多工作。

Martin Fowler几年以前建议先从单体程序开始（详见 MonolithFirst），然后再逐步把功能拆分出去，变成一个个的微服务。但是后来有人反对这个建议，他也有些松口了。

如果单体程序不是太大，这是个好主意。可以用数据额库表的数量来衡量程序的大小，我见过大的单体程序有几百张表，这就太多了，很难管理。正常情况下，一个微服务可以有两、三张表到五、六张表，一般不超过十张表。但如果要减少微服务数量的话，可以把这个标准放宽到不要超过二十张表。

用这个做为大致的指标来创建微程序，如果使用一段时间之后还是觉得太大了，那么再逐渐拆分。当然，按照这个标准建立的服务更像是服务组合，而不是单个的微服务。不过它会为你减少工作量。只要不影响业务部门的创新进度，这是一个不错的方案。

到底应不应该选择微服务呢？如果单体程序已经没法管理了，那么你别无选择。如果没有管理上的问题，那么微服务带给你的只有问题和麻烦。其实，一般公司都没有太多选择，只能采用微服务，不过你可以选择建立比较少的微服务。如果还是没法决定，有一个折中的方案，“内部微服务设计”。



# 内部微服务设计



这种设计表面上看起来是一个单体程序，它只有一个源代码存储仓库，一个数据库，一个部署，但在程序内部可以按照微服务的思想来进行设计。它可以分成多个模块，每个模块是一个微服务，可以由不同的团队管理。



![微服务之间的最佳调用方式](https://p1-tt.byteimg.com/origin/pgc-image/837f3fc91ce646dfac0f9e6c9d1b5907?from=pc)

用这张图做例子。这个图里的每个圆角方块大致是一个微服务，但我们可以把它作为一个单体程序来设计，内部有五个微服务。

每个模块都有自己的数据库表，它们都在一个数据库中，但模块之间不能跨数据库访问（不要建立模块之间数据库表的外键）。

“User”（在Conference Management模块中）是一个共享的类，但在不同的模块中的名字不同，含义和用法也不同，成员也不一样（例如，在“Customer Service”里叫“Customer”）。

DDD（Domain-Driven Design）建议不要共享这个类，而是在每一个有界上下文（模块）中都建一个新类，并拥有新的名字。

虽然它们的数据库中的数据应该大致相同，但DDD建议每一个有界上下文中都建一个新表，它们之间再进行数据同步。

这个所谓的“内部微服务设计”其实就是DDD，但当时还没有微服务，因此外表看起来是单体程序，但内部已经是微服务的设计了。

它的书在2003就出版了，当时就很有名。但它更偏重于业务逻辑的设计，践行起来也比较困难，因此大家谈论得很多，真正用的较少。

直到十年之后，微服务出来之后，人们发现它其实内部就是微服务，而且微服务的设计需要用它的思想来指导，于是就又重新焕发了青春，而且这次更猛，已经到了每个谈论微服务的人都不得不谈论DDD的地步。不过一本软件书籍，在十年之后还能指导新技术的设计，非常令人钦佩。

这样设计的好处是它是一个单体程序，省去了多个微服务带来的部署、运维的麻烦。但它内部是按微服务设计的，如果以后要拆分成微服务会比较容易。至于什么时候拆分不是一个技术问题。

如果负责这个单体程序的各个团队之间不能在部署时间表，服务器优化等方面达成一致，那么就需要拆分了。

当然你也要应对随之而来的各种运维麻烦。内部微服务设计是一个折中的方案，如果你想试水微服务，但又不愿意冒太大风险时，这是一个不错的选择。