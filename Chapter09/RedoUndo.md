一、前言
关系型数据的四大特性包括了原子性、一致性、隔离性、持久性(ACID)。

总的来说，InnoDB存储引擎的原子性是通过undo log来保证，事务的持久性是通过redo log来实现的，事务的隔离性是通过读写锁+MVCC机制来实现的。

而原子性、持久性、隔离性都只是手段，其目的是为了实现一致性。MySQL满足的是其自身内部数据的一致性，而对于具体业务的一致性，还需要应用程序本身遵守一致性规约。

MySQL事务实现的机制是WAL(Write-ahend logging,预写式日志)，这是比较主流的方案。

在MySQL服务异常奔溃后，使用WAL，可以在系统重启之后，通过比较日志和系统状态来决定继续之前的操作或者是撤销之前的操作。

redo log(重做日志)：每当操作时，在磁盘数据变更之前，将操作写入redo log，这样当系统奔溃重启后可以继续执行。
undo log(回滚日志)：当一个事务执行一半无法继续执行时，可以根据回滚日志将之前的修改恢复到变更之前的状态。
除了WAL(预写式日志)外，还有Commit Logging(提交日志)和Shadow Paging(影子分页)都可以实现事务的原子性和持久性。

Commit Logging只有在日志记录全部都安全写入磁盘之后，数据库在日志中看到代表事务成功的“提交记录”(Commit Record)之后，才会根据日志上的信息对真正的数据进行修改，修改完成后，再在日志中加入一条“结束记录”(End Record)表示事务已完全持久化。与WAL的区别是：WAL允许在事务提交之前，提前写入变动数据，而Commit Loggin不行；同时WAL中有undo log，Commmit Logging中却没有。

注：阿里的OceanBase使用的Commint Logging来实现事务。

Shadow Paging的实现是数据的变动并不直接修改原来的数据，而是对需要修改的数据生成一个副本，保留原数据，修改副本数据。因此在整个事务过程中，需要修改的数据会同时存在两份，即修改前的数据和修改后的数据，当事务成功提交，所有数据的修改都成功持久化之后，最后一步是去修改数据引用的指针，将引用从原数据修改为副本数据，最后修改指针的这个操作被认为是原子操作。

二、Redo log
在前面Buffer Pool的文章中已经介绍过，MySQL操作数据是在内存中完成的，然后再把内存中的数据页写入到磁盘中。

如果每次修改一条数据，就把整个内存页数据刷新到磁盘是非常浪费的，并且由于一个事务可能包含了多个执行语句，而执行语句对应的数据可能分散在不同的数据页，这样写磁盘就是多次随机IO操作，性能是非常低下的。

所以InnoDB引擎就引入了Redo Log来提高性能，Buffer Pool中的数据修改，并不需要立即就刷新到磁盘中，具体的刷盘时机可以参考《Buffer Pool》这篇文章中关于脏页刷盘的介绍。

但每一条数据的修改，都会记录一条redo log的记录，同样redo log也有自己的缓冲区存放数据修改的记录。当每个事务提交时，就会把缓存区中的记录刷新到磁盘中，同时由于磁盘中redo log的写入是顺序IO，所以效率也很高。

变相来说，redo log实现了内存页数据刷新到磁盘从随机IO变成了顺序IO，当然Buffer Pool本身在刷新数据到磁盘中可能还是随机IO。

与在事务提交时将所有修改过的内存中的页面刷新到磁盘中相比，只将该事务执行过程中产生的redo日志刷新到磁盘的好处如下：

redo日志占用的空间非常小

存储表空间ID、页号、偏移量以及需要更新的值所需的存储空间是很小的。

redo日志是顺序写入磁盘的

在执行事务的过程中，每执行一条语句，就可能产生若干条redo日志，这些日志是按照产生的顺序写入磁盘的，也就是使用顺序IO。

2.1 redo 日志格式
redo log本质上就只是记录了一下事务对数据库做了哪些修改。InnoDB引擎针对事务对数据库的不同修改场景定义了多种类型的redo log。

大部分类型的redo log都是下面这种通用的结构：

type：该条redo日志的类型，大约有53种不同的类型
sapce ID：表空间ID
page number：页号
data：该条redo日志的具体内容

在前面介绍行记录的文章中提到，如果没有为某个表显式的定义主键，并且表中也没有定义Unique键，那么InnoDB会自动的为表添加一个称之为row_id的隐藏列作为主键。

为这个row_id隐藏列赋值的方式如下：

服务器会在内存中维护一个全局变量，每当向某个包含隐藏的row_id列的表中插入一条记录时，就会把该变量的值当作新记录的row_id列的值，并且把该变量自增1。
每当这个变量的值为256的倍数时，就会将该变量的值刷新到系统表空间的页号为7的页面中一个称之为Max Row ID的属性处。
当系统启动时，会将上边提到的Max Row ID属性加载到内存中，将该值加上256之后赋值给我们前边提到的全局变量。
Max Row ID属性占用的存储空间是8个字节，当某个事务向某个包含row_id隐藏列的表插入一条记录，并且为该记录分配的row_id值为256的倍数时，就会向系统表空间页号为7的页面的相应偏移量处写入8个字节的值。

这个写入实际上是在Buffer Pool中完成的，需要为这个页面的修改记录一条redo日志，以便在系统崩溃后能将已经提交的该事务对该页面所做的修改恢复出来。这种情况下对页面的修改是极其简单的，redo日志中只需要记录一下在某个页面的某个偏移量处修改了几个字节的值，具体被修改的内容是什么，InnoDB把这种极其简单的redo日志称之为物理日志，并且根据在页面中写入数据的多少划分了几种不同的redo日志类型：

MLOG_1BYTE（type字段对应的十进制数字为1）：表示在页面的某个偏移量处写入1个字节的redo日志类型。
MLOG_2BYTE（type字段对应的十进制数字为2）：表示在页面的某个偏移量处写入2个字节的redo日志类型。
MLOG_4BYTE（type字段对应的十进制数字为4）：表示在页面的某个偏移量处写入4个字节的redo日志类型。
MLOG_8BYTE（type字段对应的十进制数字为8）：表示在页面的某个偏移量处写入8个字节的redo日志类型。
MLOG_WRITE_STRING（type字段对应的十进制数字为30）：表示在页面的某个偏移量处写入一串数据。
上边提到的Max Row ID属性实际占用8个字节的存储空间，所以在修改页面中的该属性时，会记录一条类型为MLOG_8BYTE的redo日志，MLOG_8BYTE的redo日志结构如下所示：


offset代表在页面中的偏移量。

其余MLOG_1BYTE、MLOG_2BYTE、MLOG_4BYTE类型的redo日志结构和MLOG_8BYTE的类似，只不过具体数据中包含对应个字节的数据罢了。MLOG_WRITE_STRING类型的redo日志表示写入一串数据，但是因为不能确定写入的具体数据占用多少字节，所以需要在日志结构中还会多一个len字段。

但通常执行一条SQL语句，除了要记录索引树的变化外，还有什么File Header、Page Header、Page Directory等等部分，所以每往叶子节点代表的数据页里插入一条记录时，还有其他很多地方会跟着更新，比如说：

更新Page Directory中的槽信息、Page Header中的各种页面统计信息，比如槽数量可能会更改，还未使用的空间最小地址可能会更改，本页面中的记录数量可能会更改，各种信息都可能会被修改。

同时数据页里的记录是按照索引列从小到大的顺序组成一个单向链表的，每插入一条记录，还需要更新上一条记录的记录头信息中的next_record属性来维护这个单向链表。

如果使用上边介绍的简单的物理redo日志来记录这些修改时，可以有两种解决方案：

方案一：在每个修改的地方都记录一条redo日志。

因为被修改的地方是在太多了，可能记录的redo日志占用的空间都比整个页面占用的空间都多了。

方案二：将整个页面的第一个被修改的字节到最后一个修改的字节之间所有的数据当成是一条物理redo日志中的具体数据。

第一个被修改的字节到最后一个修改的字节之间仍然有许多没有修改过的数据，我们把这些没有修改的数据也加入到redo日志中去依然很浪费。

正因为上述两种使用物理redo日志的方式来记录某个页面中做了哪些修改比较浪费，InnoDB中就有非常多的redo日志类型来做记录。

2.2 redo 日志写入过程
2.2.1 redo log block和log buffer
前面提到了，redo log本身也有自己对应的缓冲区，实际上在服务器启动时就向操作系统申请了一大片称之为redo log buffer的连续内存空间，简称为log buffer。

这片内存空间被划分成若干个连续的redo log block，InnoDB把redo日志都放在了大小为512字节的块（block）中(对应磁盘块)，可以通过启动参数innodb_log_buffer_size来指定log buffer的大小，该启动参数的默认值为16MB。

向log buffer中写入redo日志的过程是顺序的，也就是先往前边的block中写，当该block的空闲空间用完之后再往下一个block中写。

2.2.2 redo log刷盘时机
log buffer的记录需要按照一定的策略被刷新到redo log的磁盘文件中，比如：

log buffer空间不足

log buffer的大小是有限的（通过系统变量innodb_log_buffer_size指定），如果不停的往这个有限大小的log buffer里塞入日志，很快它就会被填满。

InnoDB认为如果当前写入log buffer的redo日志量已经占满了log buffer总容量的大约一半左右，就需要把这些日志刷新到磁盘上。

事务提交时

前边说过之所以使用redo日志主要是因为它占用的空间少，还是顺序写，在事务提交时可以不把修改过的Buffer Pool缓存页刷新到磁盘，但是为了保证持久性，必须要把修改这些页面对应的redo日志刷新到磁盘。

后台有一个线程，大约每秒都会刷新一次log buffer中的redo日志到磁盘。

正常关闭服务器时等等。

2.2.3 redo log 文件组
MySQL的数据目录（使用SHOW VARIABLES LIKE 'datadir'查看）下默认有两个名为ib_logfile0和ib_logfile1的文件，log buffer中的日志默认情况下就是刷新到这两个磁盘文件中。

可以通过下面的参数进行调节：

innodb_log_group_home_dir，该参数指定了redo日志文件所在的目录，默认值就是当前的数据目录。
innodb_log_file_size，该参数指定了每个redo日志文件的大小，默认值为48MB，
innodb_log_files_in_group，该参数指定redo日志文件的个数，默认值为2，最大值为100。
1
2
3
磁盘上的redo日志文件可以不只一个，而是以一个日志文件组的形式出现的。这些文件以ib_logfile[数字]（数字可以是0、1、2…）的形式进行命名。在将redo日志写入日志文件组时，是从ib_logfile0开始写，如果ib_logfile0写满了，就接着ib_logfile1写，同理，ib_logfile1写满了就去写ib_logfile2，依此类推。如果最后一个文件写满，那就重新转到ib_logfile0继续写。

注：Redo log文件是循环写入的，在覆盖写之前，总是要保证对应的脏页已经刷到了磁盘。在非常大的负载下，为避免错误的覆盖，InnoDB 会强制的flush脏页

2.2.4 redo log文件格式
log buffer本质上是一片连续的内存空间，被划分成了若干个512字节大小的block。

将log buffer中的redo日志刷新到磁盘的本质就是把block的镜像写入日志文件中，所以redo日志文件其实也是由若干个512字节大小的block组成。

redo日志文件组中的每个文件大小都一样，格式也一样，都是由两部分组成：前2048个字节，也就是前4个block是用来存储一些管理信息的。

从第2048字节往后是用来存储log buffer中block镜像的。

2.3 Log Sequence Number
InnoDB为记录已经写入的redo日志量，设计了一个称之为Log Sequence Number的全局变量，即日志序列号，简称LSN。

规定初始的lsn值为8704（也就是一条redo日志也没写入时，LSN的值为8704）。

注：LSN记录的写入都log buffer中的日志序列号，并不是写入到redo log文件中日志序列号

2.3.1 flushed_to_disk_lsn
redo log首先是就到log buffer中，之后才会刷新到磁盘的redo log文件中。

而InnoDB中有一个buf_next_to_write的全局变量，标记当前log buffer中已经有哪些日志被刷新到磁盘中了。

上面说的LSN包括了还没刷新到磁盘的日志，同样InnoDB也有一个表示刷新到磁盘中的redo日志量的全局变量flushed_to_disk_lsn。

系统第一次启动时，该变量的值和初始的lsn值是相同的，都是8704。随着系统的运行，redo日志被不断写入log buffer，但是并不会立即刷新到磁盘，所以lsn的值就和flushed_to_disk_lsn的值拉开了差距。

当有新的redo日志写入到log buffer时，首先lsn的值会增长，但flushed_to_disk_lsn不变，随后随着不断有log buffer中的日志被刷新到磁盘上，flushed_to_disk_lsn的值也跟着增长。如果两者的值相同时，说明log buffer中的所有redo日志都已经刷新到磁盘中了。

注：应用程序向磁盘写入文件时其实是先写到操作系统的缓冲区中去，如果某个写入操作要等到操作系统确认已经写到磁盘时才返回，那需要调用一下操作系统提供的fsync函数。其实只有当系统执行了fsync函数后，flushed_to_disk_lsn的值才会跟着增长，当仅仅把log buffer中的日志写入到操作系统缓冲区却没有显式的刷新到磁盘时，另外的一个write_lsn的值跟着增长。

2.3.2 查看系统中的各种LSN值
可以使用下面的命令查看当前InnoDB存储引擎中的各种LSN值的情况：

SHOW ENGINE INNODB STATUS;
1
查询信息如下：

LOG
---
Log sequence number 45056080
Log flushed up to   45056080
Pages flushed up to 45056080
Last checkpoint at  45056071
0 pending log flushes, 0 pending chkp writes
12 log i/o's done, 0.00 log i/o's/second
1
2
3
4
5
6
7
8
Log sequence number：代表系统中的lsn值，也就是当前系统已经写入的redo日志量，包括写入log buffer中的日志。
Log flushed up to：代表flushed_to_disk_lsn的值，也就是当前系统已经写入磁盘的redo日志量。
Pages flushed up to：代表flush链表中被最早修改的那个页面对应的oldest_modification属性值。
Last checkpoint at：当前系统的checkpoint_lsn值。

2.3.3 innodb_flush_log_at_trx_commit
为了保证事务的持久性，用户线程在事务提交时需要将该事务执行过程中产生的所有redo日志都刷新到磁盘上。

这会很明显的降低数据库性能。如果对事务的持久性要求不是那么强烈的话，可以选择修改系统变量innodb_flush_log_at_trx_commit的值，该变量有3个可选的值：

0：当该系统变量值为0时，表示在事务提交时不立即向磁盘中同步redo日志，这个任务是交给后台线程做的。
这样很明显会加快请求处理速度，但是如果事务提交后服务器挂了，后台线程没有及时将redo日志刷新到磁盘，那么该事务对页面的修改会丢失。

1：当该系统变量值为1时，表示在事务提交时需要将redo日志同步到磁盘，可以保证事务的持久性。1也是innodb_flush_log_at_trx_commit的默认值。


2：当该系统变量值为2时，表示在事务提交时需要将redo日志写到操作系统的缓冲区中，但并不需要保证将日志真正的刷新到磁盘。

这种情况下如果数据库挂了，操作系统没挂的话，事务的持久性还是可以保证的，但是操作系统也挂了的话，那就不能保证持久性了。

三、Undo log
事务原子性需要保证事务中的操作要么全部完成，要么什么也不做。但通常会遇到下面的情况：

事务执行过程中可能遇到各种错误，比如服务器本身的错误等
程序在执行过程中通过ROLLBACK取消当前事务的执行。
上面这两种情况就导致事务执行到一半就结束了，但可能已经修改了很多数据，为了事务的原子性，需要把修改的数据给还原回来，这个过程就是回滚。

InnoDB引擎中的回滚通过undo log来实现，当需要修改某个数据时候，首先把数据页从磁盘加载到Buffer Pool中，然后记录一条undo log日志，之后再进行修改。

而对于增删查改，不同的操作产生的undo log的格式也有所不同。Undo log是与事务密切相关的，先简单了解一下事务的相关信息。

3.1 事务ID
3.1.1 分配时机
事务可以是只读事务，也可以是读写事务。

可以通过START TRANSACTION READ ONLY语句开启只读事务，也可以通过START TRANSACTION READ WRITE开启读写事务。或者使用BEGIN、START TRANSACTION语句开启的事务默认也算是读写事务。

对于只读事务来说，它不能对普通的表进行增删改的操作，但是可以对创建的临时表执行增删改操作，且只有在第一次执行增删改操作时，这个事务才会给分配一个事务id，否则的话是不分配事务id的。

对于读写事务来说，只有在它第一次对某个表（包括用户创建的临时表）执行增删改操作时才会为这个事务分配一个事务id，否则的话也是不分配事务id的。

注：虽然开启了一个读写事务，但是在这个事务中全是查询语句，并没有执行增、删、改的语句，那也就意味着这个事务并不会被分配一个事务id。

3.1.2 分配策略
事务id本质上就是一个数字，它的分配策略和我们前边提到的对隐藏列row_id（当用户没有为表创建主键和UNIQUE键时InnoDB自动创建的列）的分配策略大抵相同：

服务器会在内存中维护一个全局变量，每当需要为某个事务分配一个事务id时，就会把该变量的值当作事务id分配给该事务，并且把该变量自增1。
每当这个变量的值为256的倍数时，就会将该变量的值刷新到系统表空间的页号为5的页面中一个称之为Max Trx ID的属性处，这个属性占用8个字节的存储空间。
当系统下一次重新启动时，会将上边提到的Max Trx ID属性加载到内存中，将该值加上256之后赋值给我们前边提到的全局变量（因为在上次关机时该全局变量的值可能大于Max Trx ID属性值）。
这样就可以保证整个系统中分配的事务id值是一个递增的数字。先被分配id的事务得到的是较小的事务id，后被分配id的事务得到的是较大的事务id。

3.1.3 隐藏列trx_id
在前面《InnoDB存储结构》的文章中介绍过了，一条记录除了保存真实数据外，还会有额外信息和隐藏列，而隐藏列中有trx_id和roll_pointer两个属性。


其中的trx_id列就是某个对这个聚簇索引记录做改动的语句所在的事务对应的事务id而已（此处的改动可以是INSERT、DELETE、UPDATE操作）。至于roll_pointer隐藏列我们后边分析。

3.2 undo log格式
一个事务在执行过程中可能新增、删除、更新若干条记录，也就是说需要记录很多条对应的undo日志，这些undo日志会被从0开始编号，也就是说根据生成的顺序分别被称为第0号undo日志、第1号undo日志、…、第n号undo日志等，这个编号也被称之为undo NO。

表空间其实是由许许多多的页面构成的，页面有不同的类型，其中有一种称之为FIL_PAGE_UNDO_LOG类型的页面是专门用来存储undo日志的。也就是说Undo page跟储存数据和索引的页等是类似的。

FIL_PAGE_UNDO_LOG页面可以从系统表空间中分配，也可以从一种专门存放undo日志的表空间分配，也就是所谓的undo tablespace中分配。

3.2.1 INSERT对应的undo log
对于插入操作的回滚日志，InnoDB设计了一个类型为TRX_UNDO_INSERT_REC的undo日志。

当向某个表中插入一条记录时，实际上需要向聚簇索引和所有的二级索引都插入一条记录。

但对于undo log而言，只需要考虑向聚簇索引插入记录时的情况，因为聚簇索引和二级索引记录是一一对应的，所以在回滚插入操作时，只需要知道这条记录的主键信息，然后根据主键信息做对应的删除操作，做删除操作时就会顺带着把所有二级索引中相应的记录也删除掉。

3.2.2 roll_pointer
roll_pointer本质上就是一个指向记录对应的undo日志的一个指针。

比方说我们向表里插入了2条记录，每条记录都有与其对应的一条undo日志。记录被存储到了类型为FIL_PAGE_INDEX的页面中（数据页），undo日志被存放到了类型为FIL_PAGE_UNDO_LOG的页面中。

3.2.3 DELETE对应的undo log
在介绍行记录结构和索引页结构的时候，介绍过每个行记录都有一个next_record属性，它将所有记录连成一个链表，而对于被删除的记录，同样会根据next_record连成一个链表，成为垃圾链表。

Page Header部分有一个称之为PAGE_FREE的属性，它指向由被删除记录组成的垃圾链表中的头节点。

如图所示(只把记录的delete_mask标志位展示了出来)：


使用DELETE语句把正常记录链表中的最后一条记录给删除掉，其实这个删除的过程需要经历两个阶段。

第一阶段：


将记录的delete_mask标识位设置为1，这个阶段称之为delete mark。

可以看到，正常记录链表中的最后一条记录的delete_mask值被设置为1，但是并没有被加入到垃圾链表。也就是此时记录处于一个中间状态。在删除语句所在的事务提交之前，被删除的记录一直都处于这种所谓的中间状态。

第二阶段：

当该删除语句所在的事务提交之后，会有专门的线程后来真正的把记录删除掉。

所谓真正的删除就是把该记录从正常记录链表中移除，并且加入到垃圾链表中，然后还要调整一些页面的其他信息，比如页面中的用户记录数量PAGE_N_RECS、上次插入记录的位置PAGE_LAST_INSERT、垃圾链表头节点的指针PAGE_FREE、页面中可重用的字节数量PAGE_GARBAGE、还有页目录的一些信息等等。这个阶段称之为purge。

把阶段二执行完了，这条记录就算是真正的被删除掉了。这条已删除记录占用的存储空间也可以被重新利用了。

从上边的描述中也可以看出来，在删除语句所在的事务提交之前，只会经历阶段一，也就是delete mark阶段（提交之后我们就不用回滚了，所以只需考虑对删除操作的阶段一做的影响进行回滚）。InnoDB中就会产生一种称之为TRX_UNDO_DEL_MARK_REC类型的undo日志。

3.2.4 UPDATE对应的undo log
在执行UPDATE语句时，InnoDB对更新主键和不更新主键这两种情况有截然不同的处理方案。

不更新主键
在不更新主键的情况下，又可以细分为被更新的列占用的存储空间不发生变化和发生变化的情况。

就地更新(in-place update)

更新记录时，对于被更新的每个列来说，如果更新后的列和更新前的列占用的存储空间都一样大，那么就可以进行就地更新，也就是直接在原记录的基础上修改对应列的值。再次强调一边，是每个列在更新前后占用的存储空间一样大，有任何一个被更新的列更新前比更新后占用的存储空间大，或者更新前比更新后占用的存储空间小都不能进行就地更新。

先删除掉旧记录，再插入新记录

在不更新主键的情况下，如果有任何一个被更新的列更新前和更新后占用的存储空间大小不一致，那么就需要先把这条旧的记录从聚簇索引页面中删除掉，然后再根据更新后列的值创建一条新的记录插入到页面中。

这里所说的删除并不是delete mark操作，而是真正的删除掉，也就是把这条记录从正常记录链表中移除并加入到垃圾链表中，并且修改页面中相应的统计信息（比如PAGE_FREE、PAGE_GARBAGE等这些信息）。由用户线程同步执行真正的删除操作，真正删除之后紧接着就要根据各个列更新后的值创建的新记录插入。

如果新创建的记录占用的存储空间大小不超过旧记录占用的空间，那么可以直接重用被加入到垃圾链表中的旧记录所占用的存储空间，否则的话需要在页面中新申请一段空间以供新记录使用，如果本页面内已经没有可用的空间的话，那就需要进行页面分裂操作，然后再插入新记录。

针对UPDATE不更新主键的情况（包括上边所说的就地更新和先删除旧记录再插入新记录），InnoDB设计了一种类型为TRX_UNDO_UPD_EXIST_REC的undo日志。

更新主键
针对UPDATE语句中更新了记录主键值的这种情况，InnoDB在聚簇索引中分了两步处理：

将旧记录进行delete mark操作
在UPDATE语句所在的事务提交前，对旧记录只做一个delete mark操作，在事务提交后才由专门的线程做purge操作，把它加入到垃圾链表中。这里一定要和我们上边所说的在不更新记录主键值时，先真正删除旧记录，再插入新记录的方式区分开！
之所以只对旧记录做delete mark操作，是因为别的事务同时也可能访问这条记录，如果把它真正的删除加入到垃圾链表后，别的事务就访问不到了。这个功能就是所谓的MVCC。
创建一条新记录
根据更新后各列的值创建一条新记录，并将其插入到聚簇索引中（需重新定位插入的位置）。
由于更新后的记录主键值发生了改变，所以需要重新从聚簇索引中定位这条记录所在的位置，然后把它插进去。
针对UPDATE语句更新记录主键值的这种情况，在对该记录进行delete mark操作前，会记录一条类型为TRX_UNDO_DEL_MARK_REC的undo日志；之后插入新记录时，会记录一条类型为TRX_UNDO_INSERT_REC的undo日志，也就是说每对一条记录的主键值做改动时，会记录2条undo日志。

3.3 事务流程
3.3.1 事务执行

MySQL在事务执行的过程中，会记录相应SQL语句的UndoLog 和 Redo Log，然后在内存中更新数据并形成数据脏页。

接下来Redo Log会根据一定规则触发刷盘操作，Undo Log 和数据脏页则通过刷盘机制将数据持久化至磁盘文件。

事务提交时，会将当前事务相关的所有Redo Log刷盘，只有当前事务相关的所有Redo Log 刷盘成功，事务才算提交成功。
注：undo log也需要记录 redo log

3.3.2 事务恢复
如果MySQL由于某种原因崩溃或者宕机，就需要数据的恢复或者回滚操作。

如果事务在执行至上面的第8步(事务未成功提交)，即事务提交之前，MySQL 崩溃或者宕机，此时会先使用Redo Log恢复数据，然后使用Undo Log回滚数据。

如果在执行第8步之后MySQL崩溃或者宕机，此时会使用Redo Log恢复数据，大体流程如下图所示。


MySQL崩溃恢复后，首先会获取日志检查点信息，随后根据日志检查点信息使用Redo Log进行恢复。MySQL崩溃或者宕机时事务未提交，则接下来使用Undo Log回滚数据。如果在MySQL崩溃或者宕机时事务已经提交，则用Redo Log恢复数据即可

3.3.3 恢复机制
MySQL可以根据redo日志中的各种LSN值，来确定恢复的起点和终点。

然后将redo日志中的数据，以哈希表的形式，将一个页面下数据放到哈希表的一个槽中。

之后就可以遍历哈希表，因为对同一个页面进行修改的redo日志都放在了一个槽里，所以可以一次性将一个页面修复好（避免了很多读取页面的随机IO）。并且通过各种机制，避免无谓的页面修复，比如已经刷新的页面，进而提升崩溃恢复的速度。

3.3.4 崩溃后的恢复为什么不用binlog？
binlog 会记录表所有更改操作，包括更新删除数据，更改表结构等等，主要用于人工恢复数据，而 redo log 对于我们是不可见的，它是 InnoDB 用于保证 crash-safe 能力的，也就是在事务提交后MySQL崩溃的话，可以保证事务的持久性，即事务提交后其更改是永久性的。

一句话概括：binlog 是用作人工恢复数据，redo log 是 MySQL 自己使用，用于保证在数据库崩溃时的事务持久性。

redo log 是 InnoDB 引擎特有的，binlog 是 MySQL 的 Server 层实现的,所有引擎都可以使用。

redo log是物理日志，记录的是“在某个数据页上做了什么修改”，恢复的速度更快；binlog是逻辑日志，记录的是这个语句的原始逻辑，比如“给ID=2这的c字段加1 ”。

redo log是“循环写”的日志文件，redo log 只会记录未刷盘的日志，已经刷入磁盘的数据都会从 redo log 这个有限大小的日志文件里删除。binlog 是追加日志，保存的是全量的日志。

当数据库 crash 后，想要恢复未刷盘但已经写入 redo log 和 binlog 的数据到内存时，binlog 是无法恢复的。虽然 binlog 拥有全量的日志，但没有一个标志让 innoDB 判断哪些数据已经入表(写入磁盘)，哪些数据还没有。

3.4 redo log和undo log关系
数据库崩溃重启后，需要先从redo log中把未落盘的脏页数据恢复回来，重新写入磁盘，保证用户的数据不丢失。

当然，在崩溃恢复中还需要把未提交的事务进行回滚操作。由于回滚操作需要undo log日志支持，undo log日志的完整性和可靠性需要redo log日志来保证，所以数据库崩溃需要先做redo log数据恢复，然后做undo log回滚。

redo log是物理日志，记录的是数据库页的物理修改操作。所以undo log（可以看成数据库的数据）的写入也会伴随着redo log的产生，这是因为undo log也需要持久化的保护。

事务进行过程中，每次sql语句执行，都会记录undo log和redo log，然后更新数据形成脏页。

事务执行COMMIT操作时，会将本事务相关的所有redo log进行落盘，只有所有的redo log落盘成功，才算COMMIT成功。然后内存中的undo log和脏页按照同样的规则进行落盘。如果此时发生崩溃，则只使用redo log恢复数据。

3.5 redo log和binlog一致性
当我们开启了MySQL的BinLog日志，很明显需要保证BinLog和事务日志的一致性，为了保证二者的一致性，使用了两阶段事务2PC（所谓的两个阶段是指：第一阶段：准备阶段和第二阶段：提交阶段）。步骤如下：

当事务提交时InnoDB存储引擎进行prepare操作。
MySQL上层会将数据库、数据表和数据表中的数据的更新操作写入BinLog文件。
InnoDB存储引擎将事务日志写入Redo Log文件中。



# 聊聊redo log是什么？

## 前言

说到`MySQL`，有两块日志一定绕不开，一个是`InnoDB`存储引擎的`redo log`（重做日志），另一个是`MySQL Servce`层的 `binlog`（归档日志）。



![img](https://pic2.zhimg.com/80/v2-7db2f77c40f6420581324ebb5692d175_1440w.webp)



只要是数据更新操作，就一定会涉及它们，今天就来聊聊`redo log`（重做日志）。

## redo log

`redo log`（重做日志）是`InnoDB`存储引擎独有的，它让`MySQL`拥有了崩溃恢复能力。

比如`MySQL`实例挂了或宕机了，重启时，`InnoDB`存储引擎会使用`redo log`恢复数据，保证数据的持久性与完整性。



![img](https://pic1.zhimg.com/80/v2-db16779bfbde98a7dfc9b3310c0ad35c_1440w.webp)



上一篇中阿星讲过，`MySQL`中数据是以页为单位，你查询一条记录，会从硬盘把一页的数据加载出来，加载出来的数据叫数据页，会放入到`Buffer Pool`中。

后续的查询都是先从`Buffer Pool`中找，没有命中再去硬盘加载，减少硬盘`IO`开销，提升性能。

更新表数据的时候，也是如此，发现`Buffer Pool`里存在要更新的数据，就直接在`Buffer Pool`里更新。

然后会把“在某个数据页上做了什么修改”记录到重做日志缓存（`redo log buffer`）里，接着刷盘到`redo log`文件里。



![img](https://pic2.zhimg.com/80/v2-23d17cd5924fa37c0867cf52a5064b75_1440w.webp)



理想情况，事务一提交就会进行刷盘操作，但实际上，刷盘的时机是根据策略来进行的。

> 小贴士：每条redo记录由“表空间号+数据页号+偏移量+修改数据长度+具体修改的数据”组成

## 刷盘时机

`InnoDB`存储引擎为`redo log`的刷盘策略提供了`innodb_flush_log_at_trx_commit`参数，它支持三种策略

- **设置为0的时候，表示每次事务提交时不进行刷盘操作**
- **设置为1的时候，表示每次事务提交时都将进行刷盘操作（默认值）**
- **设置为2的时候，表示每次事务提交时都只把redo log buffer内容写入page cache**

另外`InnoDB`存储引擎有一个后台线程，每隔`1`秒，就会把`redo log buffer`中的内容写到文件系统缓存（`page cache`），然后调用`fsync`刷盘。



![img](https://pic3.zhimg.com/80/v2-e466e33bf61b4c5b70745685da3b376e_1440w.webp)



也就是说，一个没有提交事务的`redo log`记录，也可能会刷盘。

为什么呢？

因为在事务执行过程`redo log`记录是会写入`redo log buffer`中，这些`redo log`记录会被后台线程刷盘。



![img](https://pic2.zhimg.com/80/v2-8b45c811e7502bb04f0a370615380875_1440w.webp)



除了后台线程每秒`1`次的轮询操作，还有一种情况，当`redo log buffer`占用的空间即将达到`innodb_log_buffer_size`一半的时候，后台线程会主动刷盘。

下面是不同刷盘策略的流程图

### innodb_flush_log_at_trx_commit=0



![img](https://pic3.zhimg.com/80/v2-2abf4716c88e1cb6020a21f6d441cca2_1440w.webp)



为`0`时，如果`MySQL`挂了或宕机可能会有`1`秒数据的丢失。

### innodb_flush_log_at_trx_commit=1



![img](https://pic1.zhimg.com/80/v2-0181ad11442ef502210aeec8856f4fd8_1440w.webp)



为`1`时， 只要事务提交成功，`redo log`记录就 一定在硬盘里，不会有任何数据丢失。

如果事务执行期间`MySQL`挂了或宕机，这部分日志丢了，但是事务并没有提交，所以日志丢了也不会有损失。

### innodb_flush_log_at_trx_commit=2



![img](https://pic3.zhimg.com/80/v2-b1cfa7cae61b0917365acb7026e11a0e_1440w.webp)



为`2`时， 只要事务提交成功，`redo log buffer`中的内容只写入文件系统缓存（`page cache`）。

如果仅仅只是`MySQL`挂了不会有任何数据丢失，但是宕机可能会有`1`秒数据的丢失。

## 日志文件组

硬盘上存储的`redo log`日志文件不只一个，而是以一个**日志文件组**的形式出现的，每个的`redo`日志文件大小都是一样的。

比如可以配置为一组`4`个文件，每个文件的大小是`1GB`，整个`redo log`日志文件组可以记录`4G`的内容。

它采用的是环形数组形式，从头开始写，写到末尾又回到头循环写，如下图所示。



![img](https://pic3.zhimg.com/80/v2-dac07e843d4f6c3a94468168c4f13c6e_1440w.webp)



在个**日志文件组**中还有两个重要的属性，分别是`write pos、checkpoint`

- **write pos是当前记录的位置，一边写一边后移**
- **checkpoint是当前要擦除的位置，也是往后推移**

每次刷盘`redo log`记录到**日志文件组**中，`write pos`位置就会后移更新。

每次`MySQL`加载**日志文件组**恢复数据时，会清空加载过的`redo log`记录，并把`checkpoint`后移更新。

`write pos`和`checkpoint`之间的还空着的部分可以用来写入新的`redo log`记录。



![img](https://pic2.zhimg.com/80/v2-d9e45e6439aae88d6c7d8e5ba912d3b9_1440w.webp)



如果`write pos`追上`checkpoint`，表示**日志文件组**满了，这时候不能再写入新的`redo log`记录，`MySQL`得停下来，清空一些记录，把`checkpoint`推进一下。



![img](https://pic3.zhimg.com/80/v2-80c7219fb4a27e55110b8d6a0e3ee632_1440w.webp)



本文到此就结束了，下篇会聊聊`binlog`（归档日志）。

## 小结

相信大家都知道`redo log`的作用和它的刷盘时机、存储形式。

现在我们来思考一问题，只要每次把修改后的数据页直接刷盘不就好了，还有`redo log`什么事。

它们不都是刷盘么？差别在哪里？

```text
1 Byte = 8bit
1 KB = 1024 Byte
1 MB = 1024 KB
1 GB = 1024 MB
1 TB = 1024 GB
```

实际上，数据页大小是`16KB`，刷盘比较耗时，可能就修改了数据页里的几`Byte`数据，有必要把完整的数据页刷盘吗？

而且数据页刷盘是随机写，因为一个数据页对应的位置可能在硬盘文件的随机位置，所以性能是很差。

如果是写`redo log`，一行记录可能就占几十`Byte`，只包含表空间号、数据页号、磁盘文件偏移 量、更新值，再加上是顺序写，所以刷盘速度很快。

所以用`redo log`形式记录修改内容，性能会远远超过刷数据页的方式，这也让数据库的并发能力更强。

> 其实内存的数据页在一定时机也会刷盘，我们把这称为页合并，讲`Buffer Pool`的时候会对这块细说