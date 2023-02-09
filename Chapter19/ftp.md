# Docker FTP服务器



## 我们先了解一下FTP

文件传输协议（File Transfer Protocol，FTP）是用于在网络上进行文件传输的一套标准协议，它工作在 OSI 模型的第七层， TCP 模型的第四层， 即应用层， 使用 TCP 传输

不是 UDP， 客户在和服务器建立连接前要经过一个“三次握手”的过程， 保证客户与服务器之间的连接是可靠的， 而且是面向连接， 为数据传输提供可靠保证。
FTP允许用户以文件操作的方式（如文件的增、删、改、查、传送等）与另一主机相互通信。然而， 用户并不真正登录到自己想要存取的计算机上面而成为完全用户， 可用FTP程序访问远程资源， 实现用户往返传输文件、目录管理以及访问电子邮件等等， 即使双方计算机可能配有不同的操作系统和文件存储方式。

使用 Docker 搭建 FTP 服务，不仅十分简单，而且可以对宿主机有一定的隔离。下面介绍下Docker创建FTP服务器，内容介绍如下所示：

## 一.创建命令如下

```shell
docker run -d -p  21:21 -p  20:20 -p 21100-21110:21100-21110 \
-v /Users/apple/DockerFile/ftp:/home/vsftpd \
-e FTP_USER=admin \
-e FTP_PASS=1234 \
-e PASV_MIN_PORT=21100 \
-e PASV_MAX_PORT=21110 \
-e PASV_ADDRESS=192.168.2.22 \
-e PASV_ENABLE=YES \
--name ftp \
--restart=always \
--privileged=true fauria/vsftpd
```

## 二.命令含义

| 参数                             | 含义                                                         |
| :------------------------------- | :----------------------------------------------------------- |
| -d                               | 后台启动容器                                                 |
| -p 20:20                         | 将外部的20端口映射到内部的20端口                             |
| -p 21:21                         | 将外部的21端口映射到内部的21端口                             |
| -p 21100-21110:21100-21110       | 将外部的 21100-21110端口映射到内部的21100-21110端口          |
| -v /opt/vsftpd/file:/home/vsftpd | 将本地磁盘的 /opt/vsftpd/file路径映射到内部的/home/vsftpd路径 |
| -e FTP_USER=admin                | ftp的主用户                                                  |
| -e FTP_PASS=1234                 | ftp主用户的密码                                              |
| -e PASV_MIN_PORT=21100           | 最小被动端口                                                 |
| -e PASV_MAX_PORT=21110           | 最大被动端口                                                 |
| -e PASV_ADDRESS=192.168.2.22     | 指定本机的ip                                                 |
| -e PASV_ENABLE=YES               | 启动被动模式                                                 |
| –name vsftpd                     | 取一个名字，之后可以用(docker stop 名字 )来停止容器          |
| –restart=always                  | 开机自启动                                                   |
| –privileged=true                 | 容器内用户获取root权限                                       |
| fauria/vsftpd                    | 仓库的镜像                                                   |

## 三.客户端连接

1.客户端可以直接安装filezilla进行连接

如果你的客户端连接不上，你需要用telnet命令来看下

```
telnet  10.73.139.201 21
```

如果报错，那可能是防火墙没有打通

2.如果是mac用户，也可以浏览器进行连接

```
ftp://192.168.2.22
```

输入账号admin，密码1234

然后ls命令，如果报错

> 500 Illegal PORT command.
> 500 Unknown command.
> 425 Use PORT or PASV first.

可以在ftp下执行以下命令

```
pass
```

输出

> Passive mode on

这个时候，就可以正常的ls了





curl -T oa-fe.tar.gz -u admin:1234 ftp://172.17.0.5

curl -O -u admin:1234 ftp://172.17.0.5/96a89bf5fa5f49ef86c38f3789a95330.gz



curl -T oa-fe.tar.gz -u admin:1234 ftp://192.168.2.22



