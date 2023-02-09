# Dockerfile部署java项目

## Dockerfile编写

#### Jar项目的Dockerfile编写

```dockerfile
#拉取一个jdk1.8版本的docker镜像
FROM openjdk:8-jdk
# 将项目jar包添加到容器
ADD test.jar test.jar
# 将外部配置文件复制到容器
COPY ./config /tmp/config
# ENTRYPOINT 执行项目test.jar及外部配置文件
ENTRYPOINT ["java", "-jar", "test.jar","--spring.config.location=/tmp/config/application.yaml"]
```



## 传送

通过ftp上传上述包至centos指定目录中，例如上传到/usr/local/tools

或者

通过文件服务器上传，现在普遍情况是通过自动化检查后上传至文件服务器，目标服务器再通过文件服务器拉取文件进行部署。



## 部署

解压后目录

```shell
--jar #jar包相关文件目录
----test.jar
----Dockerfile #上述jar对应的Dockerfile，注意名字的大小写
----config #yaml配置文件目录
------application.yaml #java项目的配置文件
```

发布

```shell
cd ../jar
#进入config目录，配置yaml文件
cd config
vi application.yaml
#根据dockerfile构建docker镜像，其中 test_java 是镜像名；注意后面的点
docker build -t test_java .
#启动java项目，映射8080端口
docker run -it -d -p 8080:8080--name test_java test_java
docker run -dit --name test -m 400m  --cpus=2 -p 3306:3306 mysql	
```

