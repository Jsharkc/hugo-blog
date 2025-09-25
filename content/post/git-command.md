---
title: Git命令清单
description: Git命令清单
date: 2016-08-28T22:49:10+00:00
tags: ["git"]
---

#### Git专有名词解释：

* Workspace：工作区
* Index / Stage：暂存区
* Repository：仓库区（或本地仓库）
* Remote：远程仓库


-----

#### 一、新建代码库

```
# 在当前目录新建一个Git代码库
$ git init

# 新建一个目录，将其初始化为Git代码库
$ git init [project-name]

# 下载一个项目和它的整个代码历史
$ git clone [url]
```

#### 二、配置

Git的设置文件为.gitconfig，它可以在用户主目录下（全局配置），也可以在项目目录下（项目配置）

```
# 显示当前的Git配置
$ git config --list

# 编辑Git配置文件
$ git config -e [--golbal]

# 设置提交代码时的用户信息
$ git config [--global] user.name "[name]"
$ git config [--global] user.email "[email address]"
```

#### 三、增加 / 删除文件

```
# 添加制定文件到暂存区
$ git add [file1] [file2] ...

# 添加制定目录到暂存区，包括子目录
$ git add [dir]

# 添加每个变化前，都会要求确认
# 对于同一个文件的多处变化，可以实现分次提交
$ git add -p

# 删除工作区文件，并且将这次删除放入暂存区
$ git rm [file1] [file2]...

# 停止追踪指定文件，但该文件会保留在工作区
$ git rm --cached [file]

# 改名文件，并且将这个改名放入暂存区
$ git mv [file-original] [file-renamed]
```

#### 四、Branch 分支

1. 删除远端分支

```git
git push origin --delete [branch_name]
```

2. 推送本地分支到远端

```git
git push origin [本地分支名称]:[远端分支名称]
```

3. 查看分支

```git
查看本地分支 git branch
查看远程分支 git branch -r
查看本地和远程分支 git branch -a
```

