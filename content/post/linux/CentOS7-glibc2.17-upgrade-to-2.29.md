---
title: "CentOS7 glibc 2.17 升级到 2.29"
description: 'nodejs 依赖高版本 glibc，遇到并解决该问题'
date: 2023-10-25T14:37:03+08:00
tags: ["glibc", "centos", "环境"]
author: "Jacobc"
---

原因：

遇到以下问题

```shell
❯ node                                                 
node: /lib64/libm.so.6: version `GLIBC_2.27' not found (required by node)
node: /lib64/libc.so.6: version `GLIBC_2.25' not found (required by node)
node: /lib64/libc.so.6: version `GLIBC_2.28' not found (required by node)
node: /lib64/libstdc++.so.6: version `CXXABI_1.3.9' not found (required by node)
node: /lib64/libstdc++.so.6: version `GLIBCXX_3.4.20' not found (required by node)
node: /lib64/libstdc++.so.6: version `GLIBCXX_3.4.21' not found (required by node)
```

需要升级 glibc 版本。

```shell
# 下载 glibc 2.29 版本包，比需要的 GLIBC_2.28 高就行
wget https://mirrors.aliyun.com/gnu/glibc/glibc-2.29.tar.gz
# 解压
tar xzf glibc-2.29.tar.gz
cd glibc-2.29
# 创建用于 build 的目录
mkdir build
cd build

../configure  --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin 

```

到这里会遇到一个问题：

```shell
checking for python3... no
checking for python... python
checking version of python... 2.7.5, bad
configure: error:
*** These critical programs are missing or too old: make compiler python
*** Check the INSTALL file for required versions.
```

Python 等级太低，直接源码编译挺麻烦的，可以考虑 `yum install python3` ，或者安装 MiniConda，用 MiniConda 安装 python3

```shell
# 下载 Miniconda 安装脚本
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
sh Miniconda3-latest-Linux-x86_64.sh
# 一路回车或者仔细看看，修改安装路径
source ~/.bashrc
# 创建 python 环境
conda create -n installenv python=3.8
# 激活环境
conda activate installenv
```

这样 python3 环境就有了，继续上面的 `../configure ..` 还会遇见问题，make 版本低的问题，所以升级一下 make 版本，太高了也不行，所以升级 4.2.1

```shell
# 下载
wget http://ftp.gnu.org/gnu/make/make-4.2.1.tar.gz
# 解压
tar -xvf make-4.2.1.tar.gz
# 编译、安装
cd make-4.2.1
mkdir build
cd build
../configure
make
make install
# 链接
ln -s -f /usr/local/bin/make /usr/bin/make
# 查看版本
make -v
```

升级完 make 版本后，继续上面的 `../configure ..` 还会遇见问题

```shell
checking for python3... python3
checking version of python3... 3.8.18, ok
configure: error:
*** These critical programs are missing or too old: compiler
*** Check the INSTALL file for required versions.
```

意思是 gcc 版本低，所以升级一下 gcc

```shell
wget https://mirrors.aliyun.com/gnu/gcc/gcc-9.3.0/gcc-9.3.0.tar.gz
tar xzf gcc-9.3.0.tar.gz
cd gcc-9.3.0

# 下载依赖的四个包
./contrib/download_prerequisites

# 看一下几核
cat /proc/cpuinfo| grep "processor"| wc -l

mkdir build && cd build

../configure --enable-checking=release --enable-language=c,c++ --disable-multilib --prefix=/usr
# --enable-languages表示你要让你的gcc支持那些语言，--disable-multilib不生成编译为其他平台可执行代码的交叉编译器。
# --disable-checking 生成的编译器在编译过程中不做额外检查，也可以使用*–enable-checking=xxx*来增加一些检查

make -j4
make install
```

还可以采用另一种方法，安装一个高版本 gcc 环境

```shell
# 最好在 bash 解释器使用
yum install -y centos-release-scl
yum install -y devtoolset-7-gcc*
# 启动上面安装的 gcc 7 
scl enable devtoolset-7 bash
```

效果如下：

```shell
[root@xxx ~]# gcc --version
gcc (GCC) 4.8.5 20150623 (Red Hat 4.8.5-36)
Copyright (C) 2015 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

[root@xxx ~]# scl enable devtoolset-7 bash
[root@xxx ~]# gcc --version
gcc (GCC) 7.3.1 20180303 (Red Hat 7.3.1-5)
Copyright (C) 2017 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

回到最开始 `glibc-2.29/build` 目录中，继续后续步骤升级

```shell
make -j4
make install
# 这个 localedata 记得也要安装一下，否则会一直报一个问题
make localedata/install-locales
```

`make install` 完成后会报一些错误，如下，但是不知道具体有什么影响，暂时可以忽略

```shell
test ! -x /root/glibc-2.29/build/elf/ldconfig || LC_ALL=C \
  /root/glibc-2.29/build/elf/ldconfig  \
			/lib64 /usr/lib64
LD_SO=ld-linux-x86-64.so.2 CC="gcc -B/usr/bin/" /usr/bin/perl scripts/test-installation.pl /root/glibc-2.29/build/
/usr/bin/ld: cannot find -lnss_test2
collect2: error: ld returned 1 exit status
Execution of gcc -B/usr/bin/ failed!
The script has found some problems with your installation!
Please read the FAQ and the README file and check the following:
- Did you change the gcc specs file (necessary after upgrading from
  Linux libc5)?
- Are there any symbolic links of the form libXXX.so to old libraries?
  Links like libm.so -> libm.so.5 (where libm.so.5 is an old library) are wrong,
  libm.so should point to the newly installed glibc file - and there should be
  only one such link (check e.g. /lib and /usr/lib)
You should restart this script from your build directory after you've
fixed all problems!
Btw. the script doesn't work if you're installing GNU libc not as your
primary library!
make[1]: *** [Makefile:111: install] Error 1
make[1]: Leaving directory '/root/glibc-2.29'
make: *** [Makefile:12: install] Error 2
```

如果不执行 `make localedata/install-locales` ，会遇到以下问题：

```shell
/bin/sh: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
```

网上查了很久，没有提到 glibc 的，后来想到是安装 glibc 出现的问题，就又找了几篇 glibc 升级的文档，发现有的多个 `make localedata/install-locales`，于是也安装了下，问题解决。说明做事情还是要做完整，不完整会有问题，网络上的文档无法分辨是否完整，就多看几篇，最好看官方文档，一般比较完善。

最后整体列一下 glibc 安装命令：

```shell
wget https://mirrors.aliyun.com/gnu/glibc/glibc-2.29.tar.gz
tar xzf glibc-2.29.tar.gz
cd glibc-2.29
mkdir build && cd build

../configure  --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin 

make -j4
make install
# 这个 localedata 记得也要安装一下，否则会一直报一个问题
make localedata/install-locales
```

