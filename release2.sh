#!/bin/sh


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

echo "cp book.json ./content"
cp book.json ./content


echo "移动文件完成;安装插件"

echo "cd content"

cd content

echo "gitbook install"

gitbook install

if [ "$?" != "0" ] ; then
  echo "安装插件失败！退出！" 1>&2
  exit 1
fi

echo "插件安装完成;退出"

echo "cd .."

cd ..

echo "开始构建"

echo "npm run build"
npm run build

if [ "$?" != "0" ] ; then
  echo "构建失败！退出！" 1>&2
  exit 1
fi

echo "开始上传新docs文件夹"

echo "git add ."
git add .

echo "git commit -am 'release book'"
git commit -am "release book"

echo "git push"
git push

echo "上传完成"

echo "请查看链接 https://fhfirehuo.github.io/Attacking-Java-Rookie/"
