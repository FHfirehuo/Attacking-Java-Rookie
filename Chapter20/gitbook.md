# gitbook

&emsp;&emsp;不用猜了本书就是用gitbook写的。

首先安装git

[Git-2.25.0-32-bit.exe下载](http://www.filedropper.com/git-2250-32-bit)


GitBook 是一个基于 Node.js 的命令行工具。


#### 安装

    npm install gitbook-cli -g

#### 创建新书

    gitbook init

&emsp;&emsp;进入一个新的目录(电子书命名目录)执行本命令就可初始化电子书

#### 启动

    gitbook serve

#### 访问

    http://localhost:4000

#### 可能的问题

&emsp;&emsp;启动是可能会报如下错误

```
You already have a server listening on 35729 You should stop it and try again.
```

&emsp;&emsp;问题定位：端口被占用，关掉即可


&emsp;&emsp;步骤： 打开CMD，输入netstat -ano|findstr 35729 查询占用端口的pid。接着kill掉应用程序就行。


#### gitbook部署到github

&emsp;&emsp;以目录名为Attacking-Java-Rookie下面的章节目录为Chapter*格式

#### 编译成html

```shell

cd Attacking-Java-Rookie

mkdir content

cp *.md content

cp -r Chapter* content

gitbook serve ./content ./docs
```

&emsp;&emsp;每次启动的时候，都要敲长长的命令，很不方便，所以，我们就需要把命名简短化，具体就是去写成 npm 脚本


```shell

npm init -y

```

&emsp;&emsp;生成一个package.json文件，在package.json添加或修改一下代码

```json

 "scripts": {
    "build": "gitbook build ./content ./docs"
  }

```

&emsp;&emsp;然后执行命令运行

```shell

npm run build

```

&emsp;&emsp;这样 html 内容被编译好之后就会被保存到 docs 文件夹中

#### 部署到github pages

&emsp;&emsp;把文件push到github。

&emsp;&emsp;到仓库配置（settings）下的Options页面。往下拉。到达Github Pages 一项。
Source一项设置为 master branch  /docs folder。意思就是 master 分支的 docs 文件夹。

    当然master branch 也可以只是页面效果不一样而已可以自己尝试下。

&emsp;&emsp;最后完整版脚本release.sh

```shell

#!/bin/sh

echo "开始同步数据"

echo "git pull"

git pull

echo "同步数据完成"


echo "开始构建"

echo "rm -rf content"

rm -rf content

echo "rm -rf docs"

rm -rf docs

echo "旧目录删除完成"


echo "创建content文件夹"

echo "mkdir content"
mkdir content

echo "创建新文件夹完成;开始移动文件"

echo "cp -r *.md ./content"
cp -r *.md ./content

echo "cp -r Chapter* ./content"
cp -r Chapter* ./content

echo "cp -r image ./content"
cp -r image ./content

echo "cp -r file ./content"
cp -r file ./content

echo "移动文件完成;开始构建"

echo "npm run build"
npm run build

echo "构建完成;开始上传新docs文件夹"

echo "git add ."
git add .

echo "git commit -am 'release book'"
git commit -am "release book"

echo "git push"
git push

echo "上传完成"


```



在使用 `gitbook-cli` 时，可能会遇到如下问题：

```bash
$ gitbook --version
CLI version: 2.3.2
Installing GitBook 3.2.3
/Users/alphahinex/.nvm/versions/node/v12.22.12/lib/node_modules/gitbook-cli/node_modules/npm/node_modules/graceful-fs/polyfills.js:287
      if (cb) cb.apply(this, arguments)
                 ^

TypeError: cb.apply is not a function
    at /Users/alphahinex/.nvm/versions/node/v12.22.12/lib/node_modules/gitbook-cli/node_modules/npm/node_modules/graceful-fs/polyfills.js:287:18
    at FSReqCallback.oncomplete (fs.js:169:5)
```



降低 gitbook-cli 版本解决此问题

```bash
npm install -g gitbook-cli@2.2.0
```

## gitboot配置

介绍一下gitbook中book.json的一些实用配置和插件

#### 全局配置

###### title 设置书本的标题

    "title" : "Gitbook Use"

###### author 作者的相关信息

    "author" : "mingyue"

###### description 本书的简单描述

    "description" : "记录Gitbook的配置和一些插件的使用"

###### language

Gitbook使用的语言, 版本2.6.4中可选的语言如下：

    en, ar, bn, cs, de, en, es, fa, fi, fr, he, it, ja, ko, no, pl, pt, ro, ru, sv, uk, vi, zh-hans, zh-tw

例如，配置使用简体中文

    "language" : "zh-hans"

###### links 在左侧导航栏添加链接信息

```json

"links" : {
    "sidebar" : {
        "Home" : "https://www.baidu.com"
    }
}

```

###### styles 自定义页面样式， 默认情况下各generator对应的css文件

```json

"styles": {
    "website": "styles/website.css",
    "ebook": "styles/ebook.css",
    "pdf": "styles/pdf.css",
    "mobi": "styles/mobi.css",
    "epub": "styles/epub.css"
}
```

#### 插件列表plugins

在book.json中添加以下内容。然后执行gitbook install

###### 配置使用的插件

```json

"plugins": [
    "-search",
    "back-to-top-button",
    "expandable-chapters-small",
    "insert-logo"
]
```
其中"-search"中的 - 符号代表去除默认自带的插件

Gitbook默认自带有5个插件：

* highlight： 代码高亮
* search： 导航栏查询功能（不支持中文）
* sharing：右上角分享功能
* font-settings：字体设置（最上方的"A"符号）
* livereload：为GitBook实时重新加载

###### 配置插件的属性 

例如配置insert-logo的属性：

```json

  "pluginsConfig": {
    "insert-logo": {
      "url": "images/logo.png",
      "style": "background: none; max-height: 30px; min-height: 30px"
    }
  }
```

###### 一些实用的插件

回到顶部

```json

{
    "plugins": [
         "back-to-top-button"
    ]
}
```

 code 代码添加行号&复制按钮（可选）

 ```json

{
    "plugins" : [ "code" ]
}
 ```

如果想去掉复制按钮，在book.json的插件配置块更新：

```json

{
    "plugins" : [ "code" ],
    "pluginsConfig": {
          "code": {
          "copyButtons": false
      }
    }
}
```

 copy-code-button 代码块复制按钮

 ```json

{
    "plugins": ["copy-code-button"]
}
 ```


将logo插入到导航栏上方中

```json

{
  "plugins": [
       "insert-logo"
  ],
  "pluginsConfig": {
    "insert-logo": {
      "url": "images/logo.png",
      "style": "background: none; max-height: 30px; min-height: 30px"
    }
  }
}


```


支持中文搜索, 在使用此插件之前，需要将默认的search和lunr 插件去掉。

```json

{
    "plugins": [
         "-lunr", "-search", "search-pro"
    ]
}
```

## 大神的文章

https://www.cnblogs.com/mingyue5826/p/10307051.html
