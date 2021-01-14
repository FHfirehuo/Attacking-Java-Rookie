# 插入排序 (直接插入排序)

插入排序（Insertion-Sort） 的算法描述是一种简单直观的排序算法。
它的工作原理是通过构建有序序列，对于未排序数据，
在已排序序列中从后向前扫描，找到相应位置并插入。
插入排序在实现上，通常采用in-place排序（即只需用到O(1)的额外空间的排序），
因而在从后向前扫描过程中，需要反复把已排序元素逐步向后挪位，
为最新元素提供插入空间。

###### 算法描述

一般来说，插入排序都采用in-place在数组上实现。具体算法描述如下：
* 步骤1: 从第一个元素开始，该元素可以认为已经被排序；
* 步骤2: 取出下一个元素，在已经排序的元素序列中从后向前扫描；
* 步骤3: 如果该元素（已排序）大于新元素，将该元素移到下一位置；
* 步骤4: 重复步骤3，直到找到已排序的元素小于或者等于新元素的位置；
* 步骤5: 将新元素插入到该位置后；
* 步骤6: 重复步骤2~5。

###### 动图演示

![插入排序](../image/c3/is-1.jpg)

###### 代码实现

方式一

```java
package algorithm.sort;

import java.util.Arrays;

public class Insertion {

    public static void main(String[] args) {

        int[] array = {1, 2, 9, 4, 6, 7, 8, 3, 0, 5};
        System.out.println("原始数组：" + Arrays.toString(array));
        System.out.println("排序后数组：" + Arrays.toString(Insertion.insertion(array)));
    }

    private static int[] insertion(int[] array) {
        if (array.length == 0) {
            return array;
        }
        int arrayLength = array.length;

        int current;
        int preIndex;

        for (int i = 1; i < arrayLength; i++) {
            current = array[i];
            preIndex = i -1;
            while (preIndex >= 0 && current < array[preIndex]) {
                array[preIndex + 1] = array[preIndex];
                preIndex--;
            }
            if (preIndex != i -1) {
                array[preIndex + 1] = current;
            }

        }

        return array;
    }
}

```

方式二

```java

package algorithm.sort;

import java.util.Arrays;

public class Insertion {

    public static void main(String[] args) {

        int[] array = {1, 2, 9, 4, 6, 7, 8, 3, 0, 5};
        System.out.println("原始数组：" + Arrays.toString(array));
        System.out.println("排序后数组：" + Arrays.toString(Insertion.insertion(array)));
    }

    private static int[] insertion(int[] array) {
        if (array.length == 0) {
            return array;
        }
        int arrayLength = array.length;

        int item;

        for (int i = 1; i < arrayLength; i++) {
            for (int j = i; j > 0 && array[j-1] > array[j] ; j--) {
                item = array[j];
                array[j] = array[j-1];
                array[j-1] = item;
            }

        }

        return array;
    }
}

```

显然方式二比方式一的赋值操作多，所以方式一更好

###### 算法分析

* 最佳情况：T(n) = O(n)
* 最坏情况：T(n) = O(n2)
* 平均情况：T(n) = O(n2)

插入排序在实现上，通常采用in-place排序
（即只需用到O(1)的额外空间的排序），
因而在从后向前扫描过程中，需要反复把已排序元素逐步向后挪位，
为最新元素提供插入空间。

###### 时间复杂度

在插入排序中，当待排序数组是有序时，是最优的情况，
只需当前数跟前一个数比较一下就可以了，这时一共需要比较N- 1次，
时间复杂度为 O(N) 。
最坏的情况是待排序数组是逆序的，
此时需要比较次数最多，总次数记为：1+2+3+…+N-1，
所以，插入排序最坏情况下的时间复杂度为  O(N2) 。


###### 空间复杂度

插入排序的空间复杂度为常数阶

###### 稳定性分析

关键词相同的数据元素将保持原有位置不变，所以该算法是稳定的
