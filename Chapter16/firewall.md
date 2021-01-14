# 防火墙

问题:老是关闭防火墙太麻烦，所以选择彻底关闭防火墙，发现每次都记不住命令!

下面是red hat/CentOs7关闭防火墙的命令!

1:查看防火状态

systemctl status firewalld

service  iptables status

2:暂时关闭防火墙

systemctl stop firewalld

service  iptables stop

3:永久关闭防火墙

systemctl disable firewalld

chkconfig iptables off

4:重启防火墙

systemctl enable firewalld

service iptables restart  

5:永久关闭后重启

//暂时还没有试过

chkconfig iptables on


重要的事情说三遍,强烈建议使用第二种方法!第二种方法!第二!;

开放端口的方法：

方法一：命令行方式
               1. 开放端口命令： /sbin/iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
               2.保存：/etc/rc.d/init.d/iptables save
               3.重启服务：/etc/init.d/iptables restart
               4.查看端口是否开放：/sbin/iptables -L -n
    

 方法二：直接编辑/etc/sysconfig/iptables文件
               1.编辑/etc/sysconfig/iptables文件：vi /etc/sysconfig/iptables
                   加入内容并保存：-A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT
               2.重启服务：/etc/init.d/iptables restart
               3.查看端口是否开放：/sbin/iptables -L -n

但是我用方法一一直保存不上，查阅网上发现直接修改文件不需要iptables save，重启下iptables 重新加载下配置。iptables save 是将当前的iptables写入到/etc/sysconfig/iptables。我不save直接restart也不行，所以还是方法二吧

 

查询端口是否有进程守护用如下命令grep对应端口，如80为端口号
例：netstat -nalp|grep 80


现在Linux服务器只打开了22端口，用putty.exe测试一下是否可以链接上去。
可以链接上去了，说明没有问题。
最后别忘记了保存 对防火墙的设置
通过命令：service iptables save 进行保存
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT
针对这2条命令进行一些讲解吧
-A 参数就看成是添加一条 INPUT 的规则
-p 指定是什么协议 我们常用的tcp 协议，当然也有udp 例如53端口的DNS
到时我们要配置DNS用到53端口 大家就会发现使用udp协议的
而 --dport 就是目标端口 当数据从外部进入服务器为目标端口
反之 数据从服务器出去 则为数据源端口 使用 --sport
-j 就是指定是 ACCEPT 接收 或者 DROP 不接收