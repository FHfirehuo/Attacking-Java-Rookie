# 系统内核
一、查看Linux内核版本命令（两种方法）：

1、cat /proc/version

2、uname -a
二、查看Linux系统版本的命令（3种方法）：

1、lsb_release -a
即可列出所有版本信息：
这个命令适用于所有的Linux发行版，包括Redhat、SuSE、Debian…等发行版。

2、cat /etc/redhat-release
这种方法只适合Redhat系的Linux：

3、cat /etc/issue
此命令也适用于所有的Linux发行版。

三、Linux查看版本多少位

1、getconf LONG_BIT