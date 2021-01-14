# 自定义登录界面和表单信息

## 自定义用户界面

在上一节中我们讲解了关于Service配置和管理，在Service的配置中，
我们可以配置theme参数。
比如，我们在使用上一节的代码中使用Json来存储Service配置，
在web-10000001.json文件中，我们添加指定主题的参数为fire。
配置如下：

```json
{
  "@class" : "org.apereo.cas.services.RegexRegisteredService",
  "serviceId" : "^(https|imaps|http)://.*",
  "name" : "web",
  "id" : 10000001,
  "evaluationOrder" : 10,
  "accessStrategy" : {
    "@class" : "org.apereo.cas.services.DefaultRegisteredServiceAccessStrategy",
    "enabled" : true,
    "ssoEnabled" : true
  },
  "theme": "fire"
}

```
接着我们在src/main目录下新建fire.properties文件，
文件名与主题参数一致。在官网中推荐我们在配置文件中写法为：

```properties
cas.standard.css.file=/themes/[theme_name]/css/cas.css
cas.javascript.file=/themes/[theme_name]/js/cas.js
cas.admin.css.file=/themes/[theme_name]/css/admin.css

```
这里采用的写法会把CAS系统中自带的页面样式完全覆盖，
如果我们只想自定义一部分页面，可以采用自定义部分样式的写法。

```properties
anumbrella.javascript.file=/themes/fire/js/cas.js
anumbrella.standard.css.file=/themes/fire/css/cas.css
```

比如这里我只想自定义登录页面，其他页面不变，可以采用上面的写法。
所以fire.properties文件的内容如下：
```properties
fire.javascript.file=/themes/fire/js/cas.js
fire.standard.css.file=/themes/fire/css/cas.css

fire.login.images.path=/themes/fire/images

cas.standard.css.file=/css/cas.css
cas.javascript.file=/js/cas.js
cas.admin.css.file=/css/admin.css

```

fire.login.images.path=/themes/fire/images
为要在html页面使用到的图片路径，所以这里自定义图片的地址。

接着我们在src\main\resources文件下新建static和templates文件夹，
同时在static文件夹下新建themes/anumbrella文件夹，
在templates目录下新建anumbrella文件夹。
继续在static/themes/anumbrella下新建css、js、images这三个文件夹，
把需要的css、js、图片放入这下面
。接着我们在templates/anumbrella目录下新建casLoginView.html文件。

*注意：这里的casLoginView.html文件不能乱命名，必须为casLoginView.html。这里是覆盖登录页面所以命名为casLoginView.html，如果要覆盖退出页面则是casLogoutView.html。*

