# NIO示例

##### ByteBuffer
``` java
//定义一个容量为10的buffer 
ByteBuffer bbf = ByteBuffer.allocate(10);
//依次在0-4填充H、e、l、l、o字节码。如果不转换成byte将以字符形式存入
bbf.put((byte) 'H').put((byte) 'e').put((byte) 'l').put((byte) 'l').put((byte) 'o');
//修改第0位为M，填充第5位为w；
bbf.put(0, (byte) 'M').put((byte) 'w');
//
bbf.limit(bbf.position()).position(0);
//
bbf.flip();
```

##### 读取文件
``` java
        RandomAccessFile aFile = new RandomAccessFile("data/nio-data.txt", "rw");
        FileChannel inChannel = aFile.getChannel();

        //create buffer with capacity of 48 bytes
        ByteBuffer buf = ByteBuffer.allocate(48);

        int bytesRead = inChannel.read(buf); //read into buffer.
        while (bytesRead != -1) {

            buf.flip();  //make buffer ready for read

            while (buf.hasRemaining()) {
                System.out.print((char) buf.get()); // read 1 byte at a time
            }

            buf.clear(); //make buffer ready for writing
            bytesRead = inChannel.read(buf);
        }
        aFile.close();
```

##### 读取中文文件
``` java
        RandomAccessFile aFile = new RandomAccessFile("data/nio-data.txt", "rw");
        FileChannel inChannel = aFile.getChannel();

        ByteBuffer buf = ByteBuffer.allocate(48);

        int byteRead = inChannel.read(buf);
        while (byteRead != -1) {
            System.out.println("Read" + byteRead);
            buf.flip();
            byte[] bytes = new byte[byteRead];
            int index = 0;
            while (buf.hasRemaining()) {
                bytes[index] = buf.get();
                index++;
            }
            System.out.println(new String(bytes, "utf-8"));
            buf.clear();
            byteRead = inChannel.read(buf);
        }
        aFile.close();
```

#### Channel数据转换
``` java
        RandomAccessFile fromFile = new RandomAccessFile("fromFile.txt", "rw");
        FileChannel fromChannel = fromFile.getChannel();

        RandomAccessFile toFile = new RandomAccessFile("toFile.txt", "rw");
        FileChannel toChannel = toFile.getChannel();

        long position = 0;
        long count = fromChannel.size();

        toChannel.transferFrom(fromChannel, position, count);
```

#### Selector
与Selector一起使用时，Channel必须处于非阻塞模式下。这意味着不能将FileChannel与Selector一起使用，因为FileChannel不能切换到非阻塞模式。而套接字通道都可以。

``` java

        Selector selector = Selector.open();
        ServerSocketChannel channel = ServerSocketChannel.open();
        //通道在被注册到一个选择器上之前，必须先设置为非阻塞模式
        channel.configureBlocking(false);
        SelectionKey key = channel.register(selector, SelectionKey.OP_READ);
        while (true) {
            int readyChannels = selector.select();
            if (readyChannels == 0) continue;
            Set selectedKeys = selector.selectedKeys();
            Iterator keyIterator = selectedKeys.iterator();
            while (keyIterator.hasNext()) {
                SelectionKey key1 = (SelectionKey) keyIterator.next();
                if (key1.isAcceptable()) {
                    // a connection was accepted by a ServerSocketChannel.
                } else if (key1.isConnectable()) {
                    // a connection was established with a remote server.
                } else if (key1.isReadable()) {
                    // a channel is ready for reading
                } else if (key1.isWritable()) {
                    // a channel is ready for writing
                }
                keyIterator.remove();
            }
        }
```
#### pipe

``` java
        //通过Pipe.open()方法打开管道
        Pipe pipe = Pipe.open();

        //要向管道写数据，需要访问sink通道。像这样：
        Pipe.SinkChannel sinkChannel = pipe.sink();

        //通过调用SinkChannel的write()方法，将数据写入SinkChannel,像这样：

        String newData = "New String to write to file..." + System.currentTimeMillis();
        ByteBuffer buf = ByteBuffer.allocate(48);
        buf.clear();
        buf.put(newData.getBytes());

        buf.flip();

        while(buf.hasRemaining()) {
            sinkChannel.write(buf);
        }

        //从读取管道的数据，需要访问source通道，像这样：
        Pipe.SourceChannel sourceChannel = pipe.source();

        //调用source通道的read()方法来读取数据，像这样 read()方法返回的int值会告诉我们多少字节被读进了缓冲区。

        ByteBuffer rBuf = ByteBuffer.allocate(48);
        int bytesRead = sourceChannel.read(rBuf);
```

#### SocketChannel(client)

SocketChannel 模拟连接导向的流协议（如 TCP/IP
``` java
        
        //打开 SocketChannel
        SocketChannel socketChannel = SocketChannel.open();
        //可以设置 SocketChannel 为非阻塞模式（non-blocking mode）.设置之后，就可以在异步模式下调用connect(), read() 和write()了。
        socketChannel.configureBlocking(false);
        //连接到互联网上的某台服务器。
        socketChannel.connect(new InetSocketAddress("http://jenkov.com", 80));

        while (!socketChannel.finishConnect()) {
            //wait, or do something else...
            //要从SocketChannel中读取数据
            ByteBuffer buf = ByteBuffer.allocate(48);
            int bytesRead = socketChannel.read(buf);

            //写入 SocketChannel
            String newData = "New String to write to file..." + System.currentTimeMillis();

            ByteBuffer wBuf = ByteBuffer.allocate(48);
            wBuf.clear();
            wBuf.put(newData.getBytes());

            wBuf.flip();

            while (buf.hasRemaining()) {
                //Write()方法无法保证能写多少字节到SocketChannel。所以，我们重复调用write()直到Buffer没有要写的字节为止。
                socketChannel.write(buf);
            }

        }

        //关闭 SocketChannel
        socketChannel.close();
```

####   ServerSocketChannel

ServerSocketChannel 是一个可以监听新进来的TCP连接的通道, 就像标准IO中的ServerSocket一样

``` java
        boolean go = true;
        //ServerSocketChannel 是一个可以监听新进来的TCP连接的通道, 就像标准IO中的ServerSocket一样
        ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();

        serverSocketChannel.socket().bind(new InetSocketAddress(9999));

        //ServerSocketChannel可以设置成非阻塞模式。在非阻塞模式下，accept() 方法会立刻返回，如果还没有新进来的连接,返回的将是null。 因此，需要检查返回的SocketChannel是否是null.如：
        serverSocketChannel.configureBlocking(false);

        while (go) {
            //通过 ServerSocketChannel.accept() 方法监听新进来的连接。当 accept()方法返回的时候,它返回一个包含新进来的连接的 SocketChannel。因此, accept()方法会一直阻塞到有新连接到达。
            SocketChannel socketChannel = serverSocketChannel.accept();

            if (socketChannel != null) {

                //do something with socketChannel...

            }

            //do something with socketChannel...
        }

        //通过调用ServerSocketChannel.close() 方法来关闭ServerSocketChannel
        serverSocketChannel.close();
```

#### DatagramChannel

与面向流的的 socket 不同，DatagramChannel 可以发送单独的数据报给不同的目的地址。

同样，DatagramChannel 对象也可以接收来自任意地址的数据包。每个到达的数据报都含有关于它来自何处的信息（源地址）。

Java NIO中的DatagramChannel是一个能收发UDP包的通道。因为UDP是无连接的网络协议，所以不能像其它通道那样读取和写入。它发送和接收的是数据包。
        
``` java

        DatagramChannel channel = DatagramChannel.open();
        //打开的 DatagramChannel可以在UDP端口9999上接收数据包。
        channel.socket().bind(new InetSocketAddress(9999));

        //receive()方法会将接收到的数据包内容复制到指定的Buffer. 如果Buffer容不下收到的数据，多出的数据将被丢弃。
        ByteBuffer buf = ByteBuffer.allocate(48);
        buf.clear();
        channel.receive(buf);

        //发送数据
        String newData = "New String to write to file..." + System.currentTimeMillis();

        ByteBuffer sendBuf = ByteBuffer.allocate(48);
        sendBuf.clear();
        sendBuf.put(newData.getBytes());
        sendBuf.flip();
        //这个例子发送一串字符到”jenkov.com”服务器的UDP端口80。 因为服务端并没有监控这个端口，所以什么也不会发生。也不会通知你发出的数据包是否已收到，因为UDP在数据传送方面没有任何保证。
        int bytesSent = channel.send(buf, new InetSocketAddress("jenkov.com", 80));


        //可以将DatagramChannel“连接”到网络中的特定地址的。由于UDP是无连接的，连接到特定地址并不会像TCP通道那样创建一个真正的连接。而是锁住DatagramChannel ，让其只能从特定地址收发数据。
        channel.connect(new InetSocketAddress("jenkov.com", 80));

        //当连接后，也可以使用read()和write()方法，就像在用传统的通道一样。只是在数据传送方面没有任何保证。这里有几个例子：
        int bytesRead = channel.read(buf);
        int bytesWritten = channel.write(sendBuf);
```


#### SelectSockets

它创建了 ServerSocketChannel 和 Selector 对象，并将通道注册到选择器上。我们不在注册的键中保存服务器 socket 的引用，因为它永远不会被注销。

这个无限循环在最上面先调用了 select( )，这可能会无限期地阻塞。当选择结束时，就遍历选择键并检查已经就绪的通道。

``` java
public class SelectSockets {

    public static int PORT_NUMBER = 1234;

    public static void main(String[] argv) throws Exception {
        new SelectSockets().go(argv);
    }

    public void go(String[] argv) throws Exception {
        int port = PORT_NUMBER;
        if (argv.length > 0) { // Override default listen port
            port = Integer.parseInt(argv[0]);
        }
        System.out.println("Listening on port " + port);
// Allocate an unbound server socket channel
        ServerSocketChannel serverChannel = ServerSocketChannel.open();
// Get the associated ServerSocket to bind it with
        ServerSocket serverSocket = serverChannel.socket();
// Create a new Selector for use below
        Selector selector = Selector.open();
// Set the port the server channel will listen to
        serverSocket.bind(new InetSocketAddress(port));
// Set nonblocking mode for the listening socket
        serverChannel.configureBlocking(false);
// Register the ServerSocketChannel with the Selector
        serverChannel.register(selector, SelectionKey.OP_ACCEPT);
        while (true) {

// This may block for a long time. Upon returning, the
// selected set contains keys of the ready channels.
            int n = selector.select();
            if (n == 0) {
                continue; // nothing to do
            }
// Get an iterator over the set of selected keys
            Iterator it = selector.selectedKeys().iterator();
// Look at each key in the selected set
            while (it.hasNext()) {
                SelectionKey key = (SelectionKey) it.next();
// Is a new connection coming in?
                if (key.isAcceptable()) {
                    ServerSocketChannel server =
                            (ServerSocketChannel) key.channel();
                    SocketChannel channel = server.accept();
                    registerChannel(selector, channel,
                            SelectionKey.OP_READ);
                    sayHello(channel);
                }
// Is there data to read on this channel?
                if (key.isReadable()) {
                    readDataFromSocket(key);
                }
// Remove key from selected set; it's been handled
                it.remove();
            }
        }
    }
// ----------------------------------------------------------

    /**
     * Register the given channel with the given selector for the given
     * operations of interest
     */
    protected void registerChannel(Selector selector,
                                   SelectableChannel channel, int ops) throws Exception {
        if (channel == null) {
            return; // could happen
        }
// Set the new channel nonblocking
        channel.configureBlocking(false);
// Register it with the selector
        channel.register(selector, ops);
    }

    // ----------------------------------------------------------
// Use the same byte buffer for all channels. A single thread is
// servicing all the channels, so no danger of concurrent acccess.
    private ByteBuffer buffer = ByteBuffer.allocateDirect(1024);

    /**
     * Sample data handler method for a channel with data ready to read.
     *
     * @param key A SelectionKey object associated with a channel determined by
     *            the selector to be ready for reading. If the channel returns
     *            142
     *            an EOF condition, it is closed here, which automatically
     *            invalidates the associated key. The selector will then
     *            de-register the channel on the next select call.
     */
    protected void readDataFromSocket(SelectionKey key) throws Exception {
        SocketChannel socketChannel = (SocketChannel) key.channel();
        int count;
        buffer.clear(); // Empty buffer
// Loop while data is available; channel is nonblocking
        while ((count = socketChannel.read(buffer)) > 0) {
            buffer.flip(); // Make buffer readable
// Send the data; don't assume it goes all at once
            while (buffer.hasRemaining()) {
                socketChannel.write(buffer);
            }
// WARNING: the above loop is evil. Because
// it's writing back to the same nonblocking
// channel it read the data from, this code can
// potentially spin in a busy loop. In real life
// you'd do something more useful than this.
            buffer.clear(); // Empty buffer
        }
        if (count < 0) {
// Close channel on EOF, invalidates the key
            socketChannel.close();
        }
    }
// ----------------------------------------------------------

    /**
     * Spew a greeting to the incoming client connection.
     *
     * @param channel The newly connected SocketChannel to say hello to.
     */
    private void sayHello(SocketChannel channel) throws Exception {
        buffer.clear();
        buffer.put("Hi there!\r\n".getBytes());
        buffer.flip();
        channel.write(buffer);
    }

}
```


#### SelectSocketsThreadPool
``` java
public class SelectSocketsThreadPool extends SelectSockets {

    private static final int MAX_THREADS = 5;
    private ThreadPool pool = new ThreadPool(MAX_THREADS);

    // -------------------------------------------------------------
    public static void main(String[] argv) throws Exception {
        new SelectSocketsThreadPool().go(argv);
    }
// -------------------------------------------------------------

    /**
     * Sample data handler method for a channel with data ready to read. This
     * method is invoked from the go( ) method in the parent class. This handler
     * delegates to a worker thread in a thread pool to service the channel,
     * then returns immediately.
     *
     * @param key A SelectionKey object representing a channel determined by the
     *            selector to be ready for reading. If the channel returns an
     *            EOF condition, it is closed here, which automatically
     *            invalidates the associated key. The selector will then
     *            de-register the channel on the next select call.
     */
    protected void readDataFromSocket(SelectionKey key) throws Exception {

        WorkerThread worker = pool.getWorker();
        if (worker == null) {
// No threads available. Do nothing. The selection
// loop will keep calling this method until a
// thread becomes available. This design could
// be improved.
            return;
        }
// Invoking this wakes up the worker thread, then returns
        worker.serviceChannel(key);
    }
// ---------------------------------------------------------------

    /**
     * A very simple thread pool class. The pool size is set at construction
     * time and remains fixed. Threads are cycled through a FIFO idle queue.
     */
    private class ThreadPool {
        List idle = new LinkedList();

        ThreadPool(int poolSize) {
// Fill up the pool with worker threads
            for (int i = 0; i < poolSize; i++) {
                WorkerThread thread = new WorkerThread(this);
// Set thread name for debugging. Start it.
                thread.setName("Worker" + (i + 1));
                thread.start();
                idle.add(thread);
            }
        }

        /**
         * Find an idle worker thread, if any. Could return null.
         */
        WorkerThread getWorker() {
            WorkerThread worker = null;
            synchronized (idle) {
                if (idle.size() > 0) {
                    worker = (WorkerThread) idle.remove(0);
                }
            }
            return (worker);
        }

        /**
         * Called by the worker thread to return itself to the idle pool.
         */
        void returnWorker(WorkerThread worker) {
            synchronized (idle) {
                idle.add(worker);
            }
        }
    }

    /**
     * A worker thread class which can drain channels and echo-back the input.
     * Each instance is constructed with a reference to the owning thread pool
     * object. When started, the thread loops forever waiting to be awakened to
     * service the channel associated with a SelectionKey object. The worker is
     * tasked by calling its serviceChannel( ) method with a SelectionKey
     * object. The serviceChannel( ) method stores the key reference in the
     * thread object then calls notify( ) to wake it up. When the channel has
     * 147
     * been drained, the worker thread returns itself to its parent pool.
     */
    private class WorkerThread extends Thread {
        private ByteBuffer buffer = ByteBuffer.allocate(1024);
        private ThreadPool pool;
        private SelectionKey key;

        WorkerThread(ThreadPool pool) {
            this.pool = pool;
        }

        // Loop forever waiting for work to do
        public synchronized void run() {
            System.out.println(this.getName() + " is ready");
            while (true) {
                try {
// Sleep and release object lock
                    this.wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
// Clear interrupt status
                    this.interrupted();
                }
                if (key == null) {
                    continue; // just in case
                }
                System.out.println(this.getName() + " has been awakened");
                try {
                    drainChannel(key);
                } catch (Exception e) {
                    System.out.println("Caught '" + e
                            + "' closing channel");
// Close channel and nudge selector
                    try {
                        key.channel().close();
                    } catch (IOException ex) {
                        ex.printStackTrace();
                    }
                    key.selector().wakeup();
                }
                key = null;
// Done. Ready for more. Return to pool
                this.pool.returnWorker(this);
            }
        }

        /**
         * Called to initiate a unit of work by this worker thread on the
         * provided SelectionKey object. This method is synchronized, as is the
         * run( ) method, so only one key can be serviced at a given time.
         * Before waking the worker thread, and before returning to the main
         * selection loop, this key's interest set is updated to remove OP_READ.
         * This will cause the selector to ignore read-readiness for this
         * channel while the worker thread is servicing it.
         */
        synchronized void serviceChannel(SelectionKey key) {
            this.key = key;
            key.interestOps(key.interestOps() & (~SelectionKey.OP_READ));
            this.notify(); // Awaken the thread
        }

        /**
         * 148
         * The actual code which drains the channel associated with the given
         * key. This method assumes the key has been modified prior to
         * invocation to turn off selection interest in OP_READ. When this
         * method completes it re-enables OP_READ and calls wakeup( ) on the
         * selector so the selector will resume watching this channel.
         */
        void drainChannel(SelectionKey key) throws Exception {
            SocketChannel channel = (SocketChannel) key.channel();
            int count;
            buffer.clear(); // Empty buffer
// Loop while data is available; channel is nonblocking
            while ((count = channel.read(buffer)) > 0) {
                buffer.flip(); // make buffer readable
// Send the data; may not go all at once
                while (buffer.hasRemaining()) {
                    channel.write(buffer);
                }
// WARNING: the above loop is evil.
// See comments in superclass.
                buffer.clear(); // Empty buffer
            }
            if (count < 0) {
// Close channel on EOF; invalidates the key
                channel.close();
                return;
            }
// Resume interest in OP_READ
            key.interestOps(key.interestOps() | SelectionKey.OP_READ);
// Cycle the selector so this key is active again
            key.selector().wakeup();
        }
    }
}
```

