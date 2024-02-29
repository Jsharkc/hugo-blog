---
title: VSCode ssh-remote 连接不上问题 
date: 2024-02-28T21:42:23+00:00
tags: ["CentOS7"]
categories: ["CentOS7"]
---

### 背景

官方问题 [传送门](https://code.visualstudio.com/docs/remote/linux#_remote-host-container-wsl-linux-prerequisites)，发现是远程机器有一些需求，下面先列一下:


> kernel >= 4.18, glibc >=2.28, libstdc++ >= 3.4.25, Python 2.6 or 2.7, tar

然后是通过下面的命令，可以检查上面这些需求的版本

> Run ldd --version to check the glibc version. Run strings /usr/lib64/libstdc++.so.6 | grep GLIBCXX to see if libstdc++ 3.4.25 is available.

检查后发现 glibc 2.29 符合要求，libstdc++ 至少要 3.4.25 版本，内核要求 4.18 及以上，我查了一下，我系统 CentOS7，内核 3.10.0-957.21.3.el7.x86_64，我以为不行了，后面我一试，没问题。下面主要讲一下 ibstdc++ 3.4.25 版本的安装。

### 一、下载

直接下载包

```shell
weg http://ftp.de.debian.org/debian/pool/main/g/gcc-8/libstdc++6-8-dbg_8.3.0-6_amd64.deb
```

其他版本，可从下面链接直接寻找

http://ftp.de.debian.org/debian/pool/main/g/

### 二、解压

使用以下命令进行解压

```shell
ar -x libstdc++6-8-dbg_8.3.0-6_amd64.deb
#（就是 ar 命令，不是tar）
# 之后再解压刚才解压出来的 data.tar.xz
tar -xvf data.tar.xz
```

### 三、安装

先删除之前的 libstdc++.so.6

```shell
rm /usr/lib64/libstdc++.so.6
```

再把刚解压出来的进行拷贝

```shell
cp usr/lib/x86_64-linux-gnu/debug/libstdc++.so.6.0.25 /usr/lib64/
```

进行连接

```shell
ln -s /usr/lib64/libstdc++.so.6.0.25 /usr/lib64/libstdc++.so.6
```

### 四、检查验证

之后通过以下命令查看：

```shell
strings /usr/lib64/libstdc++.so.6 | grep '^GLIBCXX_'
```

结果如下：

```shell
GLIBCXX_3.4
GLIBCXX_3.4.1
GLIBCXX_3.4.2
GLIBCXX_3.4.3
GLIBCXX_3.4.4
GLIBCXX_3.4.5
GLIBCXX_3.4.6
GLIBCXX_3.4.7
GLIBCXX_3.4.8
GLIBCXX_3.4.9
GLIBCXX_3.4.10
GLIBCXX_3.4.11
GLIBCXX_3.4.12
GLIBCXX_3.4.13
GLIBCXX_3.4.14
GLIBCXX_3.4.15
GLIBCXX_3.4.16
GLIBCXX_3.4.17
GLIBCXX_3.4.18
GLIBCXX_3.4.19
GLIBCXX_3.4.20
GLIBCXX_3.4.21
GLIBCXX_3.4.22
GLIBCXX_3.4.23
GLIBCXX_3.4.24
GLIBCXX_3.4.25
GLIBCXX_DEBUG_MESSAGE_LENGTH
```

可以看到有 GLIBCXX_3.4.25，成功！~

之后就可以用 VSCode 正常远程连接啦！~

以上
