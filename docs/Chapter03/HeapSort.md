# 堆排序

 堆排序（Heapsort） 是指利用堆这种数据结构所设计的一种排序算法。
 堆积是一个近似完全二叉树的结构，
 并同时满足堆积的性质：
 即子结点的键值或索引总是小于（或者大于）它的父节点


 #### 算法描述
 * 步骤1：将初始待排序关键字序列(R1,R2….Rn)构建成大顶堆，此堆为初始的无序区；
 * 步骤2：将堆顶元素R[1]与最后一个元素R[n]交换，此时得到新的无序区(R1,R2,……Rn-1)和新的有序区(Rn),且满足R[1,2…n-1]<=R[n]；
 * 步骤3：由于交换后新的堆顶R[1]可能违反堆的性质，因此需要对当前无序区(R1,R2,……Rn-1)调整为新堆，然后再次将R[1]与无序区最后一个元素交换，得到新的无序区(R1,R2….Rn-2)和新的有序区(Rn-1,Rn)。不断重复此过程直到有序区的元素个数为n-1，则整个排序过程完成。

#### 动图演示

![堆排序](../image/c3/hs-1.jpg)


#### 代码实现

```java
package algorithm.sort;

import java.util.Arrays;

public class HeapSort {

    public static void main(String[] args) {

        int[] array = {1, 2, 9, 4, 6, 7, 8, 3, 0, 5};
        System.out.println("原始数组：" + Arrays.toString(array));
        System.out.println("排序后数组：" + Arrays.toString(HeapSort.heapSort(array)));

    }

    private static int[] heapSort(int[] array) {
        int length = array.length;
        if (length < 2) {
            return array;
        }

        buildMaxHeap(array, length);

        System.out.println("大顶堆：" + Arrays.toString(array));

        while (length > 1) {
            int temp = array[0];
            array[0] = array[length - 1];
            array[length - 1] = temp;
            length--;
            buildMaxHeap(array, length);
        }


        return array;
    }

    /**
     * 建立最大堆
     *
     * @param array
     * @param length
     */
    private static void buildMaxHeap(int[] array, int length) {
        for (int i = length / 2 - 1; i >= 0; i--) {
            adjustHeap(array, i, length);
        }
    }

    private static void adjustHeap(int[] array, int i, int length) {
        int temp = array[i];
        int parentIndex = i;
        int chaildIndex = 2 * parentIndex + 1;
        while (chaildIndex < length) {

            if (chaildIndex + 1 < length && array[chaildIndex] < array[chaildIndex + 1]) {
                //右叶子比较大
                chaildIndex++;
            }
            if (temp < array[chaildIndex]) {
                array[parentIndex] = array[chaildIndex];
                parentIndex = chaildIndex;
                chaildIndex = 2 * parentIndex + 1;
            }else {
                break;
            }
        }

        array[parentIndex] = temp;
    }
}

```

```java
package algorithm.sort;

import java.util.Arrays;

public class HeapSort {

    public static void main(String[] args) {

        int[] array = {1, 2, 9, 4, 6, 7, 8, 3, 0, 5};
        System.out.println("原始数组：" + Arrays.toString(array));
        System.out.println("排序后数组：" + Arrays.toString(HeapSort.heapSort(array)));

    }

    private static int[] heapSort(int[] array) {
        int length = array.length;
        if (length < 2) {
            return array;
        }

        buildMaxHeap(array, length);

        System.out.println("大顶堆：" + Arrays.toString(array));

        while (length > 1) {
            int temp = array[0];
            array[0] = array[length - 1];
            array[length - 1] = temp;
            length--;
            popBuildMaxHeap(array, length);
        }

        return array;
    }

    private static void popBuildMaxHeap(int[] array, int length) {
        int parentIndex = 0;
        int temp = array[parentIndex];
        int childIndex = 2 * parentIndex + 1;
        while (childIndex < length) {
            if (childIndex + 1 < length && array[childIndex] < array[childIndex + 1]) {
                childIndex++;
            }
            if (array[childIndex] > temp) {

                array[parentIndex] = array[childIndex];
                parentIndex = childIndex;
                childIndex = 2 * parentIndex + 1;
            } else {
                break;
            }
        }
        array[parentIndex] = temp;

    }

    /**
     * 建立最大堆
     *
     * @param array
     * @param length
     */
    private static void buildMaxHeap(int[] array, int length) {

        for (int i = 0; i < length / 2; i++) {
            downAdjustHeap(array, i, length);
        }
    }

    /**
     * 通过下沉初始化一个无序数组为大顶堆
     *
     * @param array
     * @param parentIndex
     */
    private static void downAdjustHeap(int[] array, int parentIndex, int length) {
        int childIndex = 2 * parentIndex + 1;
        if (childIndex + 1 < length && array[childIndex] < array[childIndex + 1]) {
            childIndex++;
        }
        if (array[childIndex] > array[parentIndex]) {
            int temp = array[parentIndex];
            array[parentIndex] = array[childIndex];
            array[childIndex] = temp;
        }
    }

}

```
#### 算法分析

* 最佳情况：T(n) = O(nlogn)
* 最差情况：T(n) = O(nlogn)
* 平均情况：T(n) = O(nlogn)

#### 堆的应用

###### 堆排序

其实就是用要排序的元素建一个堆（视情况而定是大根堆还是小根堆），然后依次弹出堆顶元素，最后得到的就是排序后的结果了

但是裸的并没有什么用，我们有sort而且sort还比堆排快，所以堆排一般都没有这种模板题，一般是利用堆排的思想，然后来搞一些奇奇怪怪的操作，第2个应用就有涉及到一点堆排的思想

###### 用两个堆来维护一些查询第k小/大的操作

洛谷P1801 黑匣子

利用一个大根堆一个小根堆来维护第k小，并没有强制在线

不强制在线，所以我们直接读入所有元素，枚举询问，因为要询问第k小，所以把前面的第k个元素都放进大根堆里面，然后如果元素数量大于k，就把堆顶弹掉放到小根堆里面，使大根堆的元素严格等于k，这样这次询问的结果就是小根堆的堆顶了（前面k-1小的元素都在大根堆里面了）

记得在完成这次询问后重新把小根堆的堆顶放到大根堆里面就好

###### 中位数

中位数也是这种操作可以解决的一种经典问题，但是实际应用不大（这种操作的复杂度为，然而求解中位数有做法）

Luogu中也有此类例题，题解内也讲的比较清楚了，此处不再赘述，读者可当做拓展练习进行食用

提示：设序列长度为，则中位数其实等价于序列中大的元素

例题：Luogu P1168 中位数

    事实上堆在难度较高的题目方面更多的用于维护一些贪心操作，
    以降低复杂度，很少会有题目是以堆为正解来出的了，更多的，堆在这些题目中处于“工具”的位置

###### 利用堆来维护可以“反悔的贪心”

题目：Luogu P2949 [USACO09OPEN]工作调度Work Scheduling

这道题的话算是这种类型应用的经典题了

首先只要有贪心基础就不难想出一个解题思路：因为所有工作的花费时间都一样，我们只要尽量的选获得利润高的工作，以及对于每个所选的工作，我们尽量让它在更靠近它的结束时间的地方再来工作

但是两种条件我们并不好维护，这种两个限制条件的题目也是有一种挺经典的做法的：对一个限制条件进行排序，对于另一个限制条件使用某些数据结构来维护（如treap，线段树，树状数组之类），但是这并不在我们今天的讨论范畴QAQ

考虑怎么将这两个条件“有机统一”。

排序的思路是没有问题的，我们可以对每个工作按照它的结束时间进行排序，从而来维护我们的第二个贪心的想法。

那么对于这样做所带来的一个冲突：对于一个截止时间在d的工作，我们有可能把0~d秒全都安排满了（可能会有多个任务的截止时间相同）

怎么解决这种冲突并保证答案的最有性呢？

一个直观的想法就是把我们目前已选的工作全部都比较一下，然后选出一个创造的利润最低的工作（假设当前正在决策的这个工作价值很高），然后舍弃掉利润最低的工作，把这个工作放进去原来的那个位置。（因为我们已经按照结束时间排序了，所以舍弃的那个任务的截止完成时间一定在当前决策的工作的之前）

但是对于大小高达的n，的复杂度显然是无法接受的，结合上面的内容，读者们应该也不难想出，可以使用堆来优化这个操作

我们可以在选用了这个工作之后，将当前工作放入小根堆中，如果堆内元素大于等于当前工作的截止时间了（因为这道题中，一个工作的执行时间是一个单位时间），我们就可以把当前工作跟堆顶工作的价值比较，如果当前工作的价值较大，就可以将堆顶弹出，然后将新的工作放入堆中，给答案加上当前工作减去堆顶元素的价值（因为堆顶元素在放入堆中的时候价值已经累加进入答案了）。如果堆内元素小于截止时间那么直接放入堆中就好

至此，我们已经可以以的效率通过本题

而通过这道题我们也可以发现，只有在优化我们思考出来的贪心操作的时间复杂度时，我们才用到了堆。正如我们先前所说到的，在大部分有一定难度的题目里，堆都是以一个“工具”的身份出现，用于优化算法（大多时候是贪心）的时间复杂度等
