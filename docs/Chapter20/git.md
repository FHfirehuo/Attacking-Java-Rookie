# git

#### github删除提交历史

1. 尝试 运行 git checkout --orphan latest_branch
2. 添加所有文件git add -A
3. 提交更改git commit -am "commit message"
4. 删除分支git branch -D master
5. 将当前分支重命名git branch -m master
6. 最后，强制更新存储库。git push -f origin master

#### 清理远程已删除本地还存在的分支

使用命令 git remote show origin，可以查看remote地址，远程分支，还有本地分支与之相对应关系等信息

清理远程已删除本地还存在的分支 git fetch --prune origin 或者 git fetch -p 或者 git pull -p


    $ git remote show origin
