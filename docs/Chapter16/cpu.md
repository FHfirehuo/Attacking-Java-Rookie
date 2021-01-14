# linux下怎么查看cpu核数

###### 查看CPU型号

```shell script
$ cat /proc/cpuinfo | grep name | sort | uniq
model name	: Intel(R) Xeon(R) CPU E5-2630 v3 @ 2.40GHz
```

###### 查看物理CPU数目

```shell script
$ cat /proc/cpuinfo | grep "physical id"
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1
physical id	: 0
physical id	: 1

```
所有physical id都是0，可知有1个物理CPU。这里有0又有1所以是两个物理cpu。

也用管道排序去重后直接输出物理cpu的个数；

```shell script
$ cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l
2
```

###### 查看核数和逻辑CPU数目

```shell script
$ cat /proc/cpuinfo | grep "core id" | sort | uniq | wc -l
8
$ cat /proc/cpuinfo | grep "processor" | sort | uniq | wc -l
32
```
由图可知：2颗物理CPU，8核32线程；

###### 如果不想自己算，也可以直接lscpu

```shell script
$ lscpu
Architecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                32
On-line CPU(s) list:   0-31
Thread(s) per core:    2
Core(s) per socket:    8
Socket(s):             2
NUMA node(s):          2
Vendor ID:             GenuineIntel
CPU family:            6
Model:                 63
Stepping:              2
CPU MHz:               2400.001
BogoMIPS:              4799.30
Virtualization:        VT-x
L1d cache:             32K
L1i cache:             32K
L2 cache:              256K
L3 cache:              20480K
NUMA node0 CPU(s):     0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30
NUMA node1 CPU(s):     1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31

```
主要是看下面几个
```shell script
CPU(s):                32 #32个逻辑cpu
Thread(s) per core:    2
Core(s) per socket:    8
Socket(s):             2  #2个物理cpu
```