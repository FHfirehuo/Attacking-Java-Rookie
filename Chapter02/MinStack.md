# 最小栈


设计一个支持 push，pop，top 操作，并能在常数时间内检索到最小元素的栈。

push(x) -- 将元素 x 推入栈中。

pop() -- 删除栈顶的元素。

top() -- 获取栈顶元素。

getMin() -- 检索栈中的最小元素。

示例:

```code
MinStack minStack = new MinStack();
minStack.push(-2);
minStack.push(0);
minStack.push(-3);
minStack.getMin();   --> 返回 -3.
minStack.pop();
minStack.top();      --> 返回 0.
minStack.getMin();   --> 返回 -2.
```

```java
package datastructure.stack;

public class FireMinStack {

    private FireStack data;
    private FireStack minIndex;

    public FireMinStack(){
        data = new FireStack();
        minIndex = new FireStack();
    }

    public int Size(){
        return data.getSize();
    }

    public boolean isEmpty(){
        return data.isEmpty();
    }

    public void push(Integer element){
        if (data.isEmpty()){
            minIndex.push(element);
        }else if(element < minIndex.top()){
            minIndex.push(element);
        }
        data.push(element);
    }

    public Integer pop(){
        int item = data.pop();
        if (item == minIndex.top()){
            minIndex.pop();
        }
        return item;
    }

    public Integer top(){
        return data.top();
    }

    public Integer getMin(){
        if(minIndex.isEmpty()){
            throw new RuntimeException("no min");
        }
        return minIndex.top();
    }

    public static void main(String[] args) {
        FireMinStack fireMinStack = new FireMinStack();
        fireMinStack.push(-2);
        fireMinStack.push(0);
        fireMinStack.push(-3);
        System.out.println(fireMinStack.getMin());
        fireMinStack.pop();
        System.out.println(fireMinStack.top());
        System.out.println(fireMinStack.getMin());
    }
}

```

### 可能得变种

ginMin() 取出最小的元素而不是检索最小的元素
