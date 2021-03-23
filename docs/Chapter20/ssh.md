# Shell脚本交互之：自动输入密码



 expect就是用来做交互用的，基本任何交互登录的场合都能使用，但是需要安装expect包

   语法如下：



```

#!/bin/expect
set timeout 30
spawn ssh -l jikuan.zjk 10.125.25.189
expect "password:"
send "zjk123\r"

```



注意：expect跟bash类似，使用时要先登录到expect，所以首行要指定使用expect
在运行脚本时候要expect  file，不能sh file了

上面语句第一句是设定超时时间为30s，spawn是expect的语句，执行命令前都要加这句

expect "password："这句意思是交互获取是否返回password：关键字，因为在执行ssh时会返回输入password的提示：jikuan.zjk@10.125.25.189's password:

send就是将密码zjk123发送过去

interact代表执行完留在远程控制台，不加这句执行完后返回本地控制台 
   
