# 栈

栈是存放对象的一种特殊容器，在插入与删除对象时，这种结构遵循后进先出（Last-in-first-out，LIFO）的原则--也就是说，对象可以任意插入栈中，但每次取出的都是此前插入的最后一个对象。
比如一摞椅子，只能将最顶端的椅子移出，也只能将新椅子放到最顶端--这两种操作分别称作入栈（Push）和退栈（Pop）。

![](../image/c2/stack-1.png)

栈是最基本的数据结构之一，在实际应用中几乎无所不在。
例如，网络浏览器会将用户最近访问过的地址组织为一个栈：
用户每访问一个新页面，其地址就会被存放至栈顶；
而用户每次按下“Back”按钮，最后一个被记录下的地址就会被清除掉。
再如，当今主流的文本编辑器大都支持编辑操作的历史记录功能：
用户的编辑操作会被依次记录在一个栈中；
一旦出现误操作，用户只需按下“Undo”按钮，
即可撤销最近一次操作并回到此前的编辑状态。

    由于栈的重要性，在Java 的java.util 包中已经专门为栈结构内建了一个类--java.util.Stack

### 栈ADT(AbstractDataType)

作为一种抽象数据类型，栈必须支持以下方法：

| 操作方法 | 功能描述 |
| :---- | :---- |
| push(x) | 将对象x 压至栈顶<br>输入：一个对象<br>输出：无 |
| pop() | 若栈非空，则将栈顶对象移除，并将其返回否则，报错<br>输入：无<br>输出：对象
| getSize() | 返回栈内当前对象的数目<br>输入：无<br>输出：非负整数 |
| isEmpty() | 检查栈是否为空<br>输入：无<br>输出：布尔标志 |
| top() | 若栈非空，则返回栈顶对象（但并不移除）否则，报错<br>输入：无<br>输出：栈顶对象 |


### 基于数组的简单实现

```java
package datastructure.stack;

public class FireStack {
    private int size;
    private Integer[] data;

    public FireStack(){
        data = new Integer[10];
    }

    public int getSize(){
        return size;
    }

    public boolean isEmpty(){
        return this.size == 0;
    }

    public void push(Integer element){
        //考虑扩容
        data[size++] = element;
    }

    public Integer pop(){
        if (isEmpty()){
            throw new IndexOutOfBoundsException("-1");
        }
        int result = data[--size];
        data[size] = null;
        return result;
    }

    public Integer top(){
        if (isEmpty()){
            throw new IndexOutOfBoundsException("-1");
        }
        return data[size-1];
    }


    public static void main(String[] args) {
        FireStack fireStack = new FireStack();
        fireStack.push(0);
        fireStack.push(1);
        fireStack.push(2);
        fireStack.push(3);
        int length = fireStack.size;
        for (int i = 0; i < length; i++) {
            System.out.println(fireStack.pop());
        }
    }
}

```

测试结果
```console
3
2
1
0
```

#### 面试中关于栈的常见问题

* 使用栈计算后缀表达式
* 对栈的元素进行排序
* 判断表达式是否括号平衡
* 括号匹配算法
* Tip借助栈进行数组倒置

