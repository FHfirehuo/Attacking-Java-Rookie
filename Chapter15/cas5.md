# 客户端接入

我们使用这个简单的基于Spring Boot的用户登录系统，将给它来接入CAS系统，这里的登录验证是使用的spring-boot-starter-data-jpa，来验证表user中的用户信息。现在我们介入CAS客户端代码，首先导入依赖。

```xml
 <!--CAS Client-->
  <dependency>
      <groupId>org.jasig.cas.client</groupId>
      <artifactId>cas-client-core</artifactId>
      <version>3.5.1</version>
  </dependency>

```

首先我们在application.properties中添加配置，
这里也就是我们上面讲解过的配置信息。

```yaml

spring:
  cas:
    sign-out-filters: /* # 监听退出的接口，即所有接口都会进行监听
    auth-filters: /* # 需要拦截的认证的接口
    validate-filters: /*
    request-wrapper-filters: /*
    assertion-filters: /*
    ignore-filters: /test # 表示忽略拦截的接口，也就是不用进行拦截
    cas-server-login-url: https://sso.fire.com:8443/login
    cas-server-url-prefix: https://sso.fire.com:8443/
    redirect-after-validation: true
    use-session: true
    server-name: https://gateway.fire.com:8000


```

然后再新建bean类SpringCasAutoconfig，读取配置文件中的信息。

