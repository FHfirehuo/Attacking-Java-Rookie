# gradle说明

Gradle 的介绍和优缺点我这里就不一一说明了：

* gradle/wrapper包：Gradle 的一层包装，能够让机器在不安装 Gradle 的情况下运行程序，便于在团队开发过程中统一 Gradle 构建的版本，推荐使用。

* gradlew：Gradle 命令的包装，当机器上没有安装 Gradle 时，可以直接用 gradlew 命令来构建项目。

* settings.gradle：可以视为多模块项目的总目录， Gradle 通过它来构建各个模块，并组织模块间的关系。

* build.gradle：管理依赖包的配置文件（相当于Maven的pom.xml）。

* gradle.properties：需手动创建，配置gradle环境变量，或配置自定义变量供 build.gradle 使用。



# Gradle最佳实践

1. 将 gradle-wrapper.properties 中的 Gradle 下载镜像改为国内地址。

```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
#distributionUrl=https\://services.gradle.org/distributions/gradle-7.6-bin.zip
distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-7.5-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

2. 新建 gradle.properties 文件，配置 Gradle 参数，提升构建速度。

   ```properties
   org.gradle.configureondemand=true
   org.gradle.caching=true
   org.gradle.parallel=true
   org.gradle.jvmargs=-Xms1024m -Xmx4048m -XX:SoftRefLRUPolicyMSPerMB=0 -noverify -XX:TieredStopAtLevel=1
   org.gradle.unsafe.configuration-cache=false
   ```

   

3. 将 maven 仓库地址改为国内镜像

4. 将经常变更的依赖包版本、 maven 库地址等变量提取到 gradle.properties 里， build.gradle 可直接读取使用。

   ```
   springBootVersion=2.7.3
   springVersion=5.3.22
   
   group=org.apereo.cas
   version=6.6.4
   ```

   

5. 指定 JDK 版本和编码。

   ```properties
   sourceCompatibility=11
   targetCompatibility=11
   ```

   

6. 使用 buildscript 方式引用 gradle plugins ，优点是可以使用自定义仓库，且便于子模块继承。

7. 新建 spring.gradle 配置文件，引用相关的 Spring 依赖包。

8. 在 build.gradle 里添加引用本地jar包的语句，这样配置后，仓库中没有的jar包，放到 src/libs 文件夹下就可以直接使用了，非常方便。

9. 在 build.gradle 中添加一个拷贝 jar 包的 task ，在 build 或 bootJar 后执行，用于将子模块打包后，拷贝到根目录下。