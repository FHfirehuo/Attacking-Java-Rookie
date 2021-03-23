# 创建mysql用户



## mysql 8.*创建

新版的的mysql版本已经将创建账户和赋予权限的方式分开了

```

CREATE user king_d@'%' identified by 'dragon123';

grant all privileges on dragon_king.* to king_d@'%' with grant option;

flush privileges;

show grants for 'king_d';

drop user king@'%';

ALTER USER 'king_d'@'%' IDENTIFIED WITH mysql_native_password BY 'dragon1223';  

```

