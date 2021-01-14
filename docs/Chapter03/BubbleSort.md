# 冒泡排序

冒泡排序是一种简单的排序算法。
它重复地走访过要排序的数列，一次比较两个元素，
如果它们的顺序错误就把它们交换过来。
走访数列的工作是重复地进行直到没有再需要交换，
也就是说该数列已经排序完成。
这个算法的名字由来是因为越小的元素会经由交换慢慢“浮”到数列的顶端。 


#### 算法描述

* 比较相邻的元素。如果第一个比第二个大，就交换它们两个；
* 对每一对相邻元素作同样的工作，从开始第一对到结尾的最后一对，这样在最后的元素应该会是最大的数；
* 针对所有的元素重复以上的步骤，除了最后一个；
* 重复步骤1~3，直到排序完成。

#### 动图演示

![冒泡](../image/c3/bs-1.gif)

#### 代码实现

```java
package algorithm.sort;

import java.util.Arrays;

/**
 * 冒泡排序
 */
public class Bubble {

    public static void main(String[] args) {

        int[] array = {1, 2, 9, 4, 6, 7, 8, 3, 0, 5};
        System.out.println("原始数组：" + Arrays.toString(array));
        System.out.println("排序后数组：" + Arrays.toString(Bubble.bubble(array)));
    }

    public static int[] bubble(int[] origin) {
        if (origin.length < 1) {
            return origin;
        }

        int arrayLength = origin.length;
        int item = 0;

        //外循环为排序趟数，arrayLength 个数进行 arrayLength-1 趟
        for (int i = 0; i < arrayLength; i++) {
            int endLength = arrayLength - 1 - i;
            //内循环为每趟比较的次数，第i趟比较arrayLength-i次
            for (int j = 0; j < endLength; j++) {
                if (origin[j] > origin[j + 1]) {
                    item = origin[j + 1];
                    origin[j + 1] = origin[j];
                    origin[j] = item;
                }
            }
        }
        return origin;
    }
}


```

    执行结果:
    原始数组：[1, 2, 9, 4, 6, 7, 8, 3, 0, 5]
    排序后数组：[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]


#### 算法分析

* 最佳情况：T(n) = O(n)
* 最差情况：T(n) = O(n2)
* 平均情况：T(n) = O(n2)

###### 时间复杂度
　　若文件的初始状态是正序的，一趟扫描即可完成排序。
所需的关键字比较次数 和记录移动次数 均达到最小值：C_min = n-1, M_min = 0。


　　所以，冒泡排序最好的时间复杂度为 O(n)。

　　若初始文件是反序的，需要进行n-1 趟排序。
每趟排序要进行 n-i 次关键字的比较(1≤i≤n-1)，
且每次比较都必须移动记录三次来达到交换记录位置。
在这种情况下，比较和移动次数均达到最大值：

C_max= \frac{n(n-1)}{2} = O(n^2)

M_max = \frac{3n(n-1)}{2} = O(n^2)

冒泡排序的最坏时间复杂度为 O(n^2)

综上，因此冒泡排序总的平均时间复杂度为 O(n^2)

###### 算法稳定性
冒泡排序就是把小的元素往前调或者把大的元素往后调。
比较是相邻的两个元素比较，交换也发生在这两个元素之间。
所以，如果两个元素相等，是不会再交换的；
如果两个相等的元素没有相邻，
那么即使通过前面的两两交换把两个相邻起来，
这时候也不会交换，所以相同元素的前后顺序并没有改变，
所以冒泡排序是一种稳定排序算法。
