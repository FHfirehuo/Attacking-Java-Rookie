# java中Keytool的使用总结

Keytool 是一个Java 数据证书的管理工具 ,Keytool 将密钥（key）和证书（certificates）存在一个称为keystore的文件中 在keystore里，包含两种数据： 
* 密钥实体（Key entity）——密钥（secret key）又或者是私钥和配对公钥（采用非对称加密） 
* 可信任的证书实体（trusted certificate entries）——只包含公钥

ailas(别名)每个keystore都关联这一个独一无二的alias，这个alias通常不区分大小写

JDK中keytool 常用命令: 

* -genkey      在用户主目录中创建一个默认文件".keystore",还会产生一个mykey的别名，mykey中包含用户的公钥、私钥和证书
(在没有指定生成位置的情况下,keystore会存在用户系统默认目录，如：对于window xp系统，会生成在系统的C:/Documents and Settings/UserName/文件名为“.keystore”)
* -alias       产生别名
* -keystore    指定密钥库的名称(产生的各类信息将不在.keystore文件中)
* -keyalg      指定密钥的算法 (如 RSA  DSA（如果不指定默认采用DSA）)
* -validity    指定创建的证书有效期多少天
* -keysize     指定密钥长度
* -storepass   指定密钥库的密码(获取keystore信息所需的密码)
* -keypass     指定别名条目的密码(私钥的密码)
* -dname       指定证书拥有者信息 例如：  "CN=名字与姓氏,OU=组织单位名称,O=组织名称,L=城市或区域名称,ST=州或省份名称,C=单位的两字母国家代码"
* -list        显示密钥库中的证书信息      keytool -list -v -keystore 指定keystore -storepass 密码
* -v           显示密钥库中的证书详细信息
* -export      将别名指定的证书导出到文件  keytool -export -alias 需要导出的别名 -keystore 指定keystore -file 指定导出的证书位置及证书名称 -storepass 密码
* -file        参数指定导出到文件的文件名
* -delete      删除密钥库中某条目          keytool -delete -alias 指定需删除的别  -keystore 指定keystore  -storepass 密码
* -printcert   查看导出的证书信息          keytool -printcert -file yushan.crt
* -keypasswd   修改密钥库中指定条目口令    keytool -keypasswd -alias 需修改的别名 -keypass 旧密码 -new  新密码  -storepass keystore密码  -keystore sage
* -storepasswd 修改keystore口令      keytool -storepasswd -keystore e:/yushan.keystore(需修改口令的keystore) -storepass 123456(原始密码) -new yushan(新密码)
* -import      将已签名数字证书导入密钥库  keytool -import -alias 指定导入条目的别名 -keystore 指定keystore -file 需导入的证书


下面是各选项的缺省值。 
* -alias "mykey"
* -keyalg "DSA"
* -keysize 1024
* -validity 90
* -keystore 用户宿主目录中名为 .keystore 的文件
* -file 读时为标准输入，写时为标准输出 

## keystore的生成

#### 分阶段生成

    keytool -genkey -alias yushan(别名) -keypass yushan(别名密码) -keyalg RSA(算法) -keysize 1024(密钥长度) -validity 365(有效期，天单位) -keystore   e:/yushan.keystore(指定生成证书的位置和证书名称) -storepass 123456(获取keystore信息的密码)
    
#### 一次性生成

    keytool -genkey -alias yushan -keypass yushan -keyalg RSA -keysize 1024 -validity 365 -keystore  e:/yushan.keystore -storepass 123456 -dname "CN=(名字(名字与姓氏), OU=(组织单位名称), O=(组织名称), L=(城市或区域名称), ST=(州或省份名称), C=(单位的两字母国家代码)";(中英文即可)

## keystore信息的查看 

    keytool -list  -v -keystore e:/keytool /yushan.keystore -storepass 123456
    
## 证书的导出

    keytool -export -alias yushan -keystore e:/yushan.keystore -file e:/yushan.crt(指定导出的证书位置及证书名称) -storepass 123456

## 查看导出的证书信息 

    keytool -printcert -file yushan.crt

## 证书的导入

    

