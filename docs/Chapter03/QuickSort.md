# 快速排序

快速排序的基本思想：通过一趟排序将待排记录分隔成独立的两部分，
其中一部分记录的关键字均比另一部分的关键字小，
则可分别对这两部分记录继续进行排序，以达到整个序列有序。

#### 算法描述

快速排序使用分治法来把一个串（list）分为两个子串（sub-lists）。具体算法描述如下：
* 步骤1：从数列中挑出一个元素，称为 “基准”（pivot ）；
* 步骤2：重新排序数列，所有元素比基准值小的摆放在基准前面，所有元素比基准值大的摆在基准的后面（相同的数可以到任一边）。在这个分区退出之后，该基准就处于数列的中间位置。这个称为分区（partition）操作；
* 步骤3：递归地（recursive）把小于基准值元素的子数列和大于基准值元素的子数列排序

#### 动图演示

![快速排序](../image/c3/qs-1.jpg)

#### 代码实现

```java
package algorithm.sort;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Stack;

public class QuickSort {

    public static void main(String[] args) {

        int[] array = {1, 2, 9, 4, 6, 7, 8, 3, 0, 5};
        System.out.println("原始数组：" + Arrays.toString(array));
        System.out.println("排序后数组：" + Arrays.toString(QuickSort.quickSort2(array)));

    }

    //填坑法
    private static int[] quickSort1(int[] array) {
        int length = array.length;
        if (length < 2) {
            return array;
        }

        sort11(array, 0, length - 1);

        return array;
    }

    private static void sort1(int[] array, int left, int right) {

        if (left >= right) {
            return;
        }
        //pivot pivət 枢纽
        int pivot = array[left];
        int index = left;
        int rIndex = right;
        int lIndex = left;

        for (; lIndex < rIndex; rIndex--) {
            if (array[rIndex] < pivot) {
                array[lIndex] = array[rIndex];
                index = lIndex;
                lIndex++;
                while (lIndex < rIndex && array[lIndex] < pivot) {
                    lIndex++;
                }
                if (lIndex != rIndex) {
                    array[rIndex] = array[lIndex];
                } else {
                    array[rIndex] = pivot;
                    index = rIndex;
                }

            }
        }
        if (lIndex == rIndex) {
            array[rIndex] = pivot;
            index = rIndex;
        }

        sort1(array, left, index - 1);
        sort1(array, index + 1, right);
    }


    private static void sort11(int[] array, int left, int right) {

        if (left >= right) {
            return;
        }
        //pivot pivət 枢纽
        int pivot = array[left];
        int index = left;
        int rIndex = right;
        int lIndex = left;

        while (lIndex < rIndex) {
            while (lIndex <= rIndex) {
                if (array[rIndex] < pivot) {
                    array[lIndex] = array[rIndex];
                    index = rIndex;
                    lIndex++;
                    break;
                }
                rIndex--;
            }


            while (lIndex <= rIndex) {
                if (array[lIndex] > pivot) {
                    array[rIndex] = array[lIndex];
                    index = lIndex;
                    rIndex--;
                    break;
                }
                lIndex++;
            }


        }
        array[index] = pivot;

        sort11(array, left, index - 1);
        sort11(array, index + 1, right);
    }

    //指针法
    private static int[] quickSort2(int[] array) {
        int length = array.length;
        if (length < 2) {
            return array;
        }
        sort2(array, 0, length - 1);
        return array;
    }

    private static void sort2(int[] array, int left, int right) {
        if (left >= right) {
            return;
        }

        int pivod = array[left];
        int lIndex = left, rIndex = right;
        while (lIndex < rIndex) {
            while (array[rIndex] > pivod && lIndex < rIndex) {
                rIndex--;
            }
            while (array[lIndex] <= pivod && lIndex < rIndex) {
                lIndex++;
            }

            if (lIndex < rIndex) {
                int item = array[rIndex];
                array[rIndex] = array[lIndex];
                array[lIndex] = item;
            }


        }


        array[left] = array[rIndex];
        array[rIndex] = pivod;

        sort2(array, left, rIndex - 1);
        sort2(array, rIndex + 1, right);

    }

    //指针发 + 随机pivot
    private static int[] quickSort3(int[] array) {
        int length = array.length;
        if (length < 2) {
            return array;
        }

        return array;
    }

    //栈的实现
    private static int[] quickSort4(int[] array) {
        int length = array.length;
        if (length < 2) {
            return array;
        }
        sort4(array, 0, length - 1);
        return array;
    }

    private static void sort4(int[] array, int left, int right) {

        // 用一个集合栈来代替递归的函数栈
        Stack<Map<String, Integer>> quickSortStack = new Stack<Map<String, Integer>>();
        Map rootParam = new HashMap();
        rootParam.put("startIndex", left);
        rootParam.put("endIndex", right);
        quickSortStack.push(rootParam);

        while (!quickSortStack.isEmpty()) {
            // 栈顶元素出栈，得到起止下标
            Map<String, Integer> param = quickSortStack.pop();
            // 得到基准元素位置
            int pivotIndex = partition(array, param.get("startIndex"), param.get("endIndex"));
            // 根据基准元素分成两部分, 把每一部分的起止下标入栈
            if (param.get("startIndex") < pivotIndex - 1) {
                Map<String, Integer> leftParam = new HashMap<String, Integer>();
                leftParam.put("startIndex", param.get("startIndex"));
                leftParam.put("endIndex", pivotIndex - 1);
                quickSortStack.push(leftParam);
            }
            if (pivotIndex + 1 < param.get("endIndex")) {
                Map<String, Integer> rightParam = new HashMap<String, Integer>();
                rightParam.put("startIndex", pivotIndex + 1);
                rightParam.put("endIndex", param.get("endIndex"));
                quickSortStack.push(rightParam);
            }
        }
    }

    private static int partition(int[] arr, int startIndex, int endIndex) {
        // 取第一个位置的元素作为基准元素
        int pivot = arr[startIndex];
        int left = startIndex;
        int right = endIndex;
        while (left < right) {
            //控制right指针比较并左移
            while (left < right && arr[right] > pivot) {
                right--;
            }
            //控制left指针比较并右移
            while (left < right && arr[left] <= pivot) {
                left++;
            }

            //交换left和right指向的元素
            if (left < right) {
                int p = arr[left];
                arr[left] = arr[right];
                arr[right] = p;
            }
        }

        //pivot和指针重合点交换
        int p = arr[left];
        arr[left] = arr[startIndex];
        arr[startIndex] = p;

        return left;
    }
}


```

#### 算法分析

* 最佳情况：T(n) = O(nlogn)
* 最差情况：T(n) = O(n2)
* 平均情况：T(n) = O(nlogn)

参考文档
https://www.sohu.com/a/246785807_684445
