# 状态模式

当一个对象的内在状态改变时允许改变其行为，这个对象看起来像是改变了其类。
状态模式主要解决的是当控制一个对象状态的条件表达式过于复杂时的情况。
把状态的判断逻辑转移到表示不同状态的一系列类中，可以把复杂的判断逻辑简化。

态模式 (State Pattern)是设计模式的一种，属于行为模式。

### 模式中的角色
* 上下文环境（Context）：它定义了客户程序需要的接口并维护一个具体状态角色的实例，将与状态相关的操作委托给当前的Concrete State对象来处理。
* 抽象状态（State）：定义一个接口以封装使用上下文环境的的一个特定状态相关的行为。
* 具体状态（Concrete State）：实现抽象状态定义的接口。

这里来看看状态模式的标准代码；

首先我们先定义一个State抽象状态类，里面定义了一个接口以封装 与Context的一个特定状态相关的行为；

```java
/**
 * 抽象状态类
 *
 */
public abstract class State {
    public abstract void Handle(Context context);
}


```



```java
package designpatterns.state;

//Context类，维护一个ConcreteState子类的实例，这个实例定义当前的状态
public class Context {

    State state;

    public Context(State state) { //定义Context的初始状态
        super();
        this.state = state;
    }

    public State getState() {
        return state;
    }

    public void setState(State state) {
        this.state = state;
        System.out.println("当前状态为"+state);
    }
    public void request(){
        state.Handle(this); //对请求做处理并且指向下一个状态
    }
}


```



```java
package designpatterns.state;

public class ConcreteStateA extends State {
    @Override
    public void Handle(Context context) {
        context.setState(new ConcreteStateB()); //设置A的下一个状态是B

    }
}


```



```java
package designpatterns.state;

public class ConcreteStateB extends State {

    @Override
    public void Handle(Context context) {
        context.setState(new ConcreteStateA()); //设置B的下一个状态是A
    }
}


```



```java
package designpatterns.state;

/**
 * 节点接口
 *
 */
public abstract  class Node {

    private static String name; //当前节点名称
    //节点跳转
    public abstract void nodeHandle(FlowContext context);
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
}


```



```java

package designpatterns.state;

public class HrNode extends Node {

    @Override
    public void nodeHandle(FlowContext context) {
        //先判断流程是否结束
        if(!context.isFlag()){
            // 根据当前流程的状态，来控制流程的走向
            if (context != null &&
                    0 == context.getStatus()) { //只有上一级审核通过后才能轮到HR审核
                // 设置当前节点的名称
                setName("HR李");
                //读取上一级的审核内容并加上自己的意见
                System.out.println(context.getMessage()+getName()+"审核通过");
                // 审核通过
                context.setStatus(0); //HR审核通过并指向下一个节点 ,如果没有下一个节点就把状态设置为终结
                context.setFlag(true);

            }
        }else{
            System.out.println("流程已经结束");
        }
    }
}

```



```java
package designpatterns.state;

/**
 * 领导节点
 *
 */
public class LeadNode extends Node {
    @Override
    public void nodeHandle(FlowContext context) {
        //根据当前流程的状态，来控制流程的走向
        //先判断流程是否结束
        if(!context.isFlag()){
            System.out.println(context.getMessage()); //先读取申请的内容
            if(context!=null&&3==context.getStatus()){ //只有出于已经申请的状态才又部门领导审核
                //设置当前节点的名称
                setName("张经理");
                //加上审核意见
                context.setMessage(context.getMessage()+getName()+"审核通过;");
                //审核通过
                context.setStatus(0); //审核通过并指向下一个节点
                context.setNode(new HrNode());
                context.getNode().nodeHandle(context);
            }
        }else{
            System.err.println("流程已经结束");
        }
    }
}


```

```java
package designpatterns.state;

/**
 * 流程控制
 *
 */
public class FlowContext {

    private boolean flag; // 代表流程是否结束
    /**
     * 流程状态 0：通过 1:驳回 2.退回整改 3.已申请
     *
     */
    private int status;

    private String message; // 消息
    private Node node; // 节点信息
    public boolean isFlag() {
        return flag;
    }

    public void setFlag(boolean flag) {
        this.flag = flag;
    }

    public int getStatus() {
        return status;
    }

    public void setStatus(int status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Node getNode() {
        return node;
    }

    public void setNode(Node node) {
        this.node = node;
    }

    public static boolean start(FlowContext context) {
        Node node = new LeadNode();
        context.setNode(node); // 设置初始节点
        context.setStatus(3); // 设置状态为申请中
        context.getNode().nodeHandle(context); // 发起请求
        // 最后要知道是否申请成功
        //判断当前是最后一个节点并且审核通过，而且流程结束
        if("HR李".equals(node.getName())&&0==context.getStatus()&&context.isFlag()){
            System.out.println("审核通过,流程结束");
            return true;
        }else{
            System.out.println("审核未通过，流程已经结束");
            return false;
        }
    }

    public FlowContext() {
        super();
    }
}


```


```java
package designpatterns.state;

public class StateMain {

    public static void main(String[] args) {
        FlowContext context=new FlowContext();
        context.setMessage("本人王小二，因为十一家里有事情，所以要多请三天假，希望公司能够审核通过");
        context.start(context);
    }
}


```

打印结果如下
本人王小二，因为十一家里有事情，所以要多请三天假，希望公司能够审核通过
本人王小二，因为十一家里有事情，所以要多请三天假，希望公司能够审核通过张经理审核通过;HR李审核通过
审核通过,流程结束；

上面这个例子只是很简单的模仿了一下工作流控制状态的跳转。
状态模式最主要的好处就是把状态的判断与控制放到了其服务端的内部，
使得客户端不需要去写很多代码判断，来控制自己的节点跳转，而且这样实现的话，
我们可以把每个节点都分开来处理，当流程流转到某个节点的时候，可以去写自己的节点流转方法。
当然状态模式的缺点也很多，比如类的耦合度比较高，基本上三个类要同时去写，而且会创建很多的节点类。


