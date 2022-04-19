---
title: git 不常用命令
date: 2022-02-24T11:42:23+80:00
tags: ["k8s"]
---

### 一、Branch 分支

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



