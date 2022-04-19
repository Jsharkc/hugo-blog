---
title: Centos7 安装 Docker
date: 2021-11-15T17:42:23+80:00
tags: ["Docker", "Centos"]
---

### 一条命令安装

官方脚本：

```shell
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

国内 daocloud 安装命令：

```shell
curl -sSL https://get.daocloud.io/docker | sh
```

### 手动安装指定版本

#### 卸载旧版本

```shell
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine \
                  container-selinux \
                  docker-selinux
```

#### 安装相关依赖

yum-utils 提供 yum-config-manager 工具, devicemapper存储驱动依赖 device-mapper-persistent-data 和 lvm2.

```shell
yum install -y yum-utils device-mapper-persistent-data lvm2
```

#### 配置版本镜像库

季度更新的稳定 stable 版和 test 版

```sh
yum-config-manager --add-repo \
     https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-test
```

由于 docker.com 服务器下载很慢,所以改为国内镜像.

```sh
yum-config-manager --add-repo \
    https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

如需禁止 test 版本, 可以执行下面的命令

```Sh
yum-config-manager --disable docker-ce-test
```

#### 安装 Docker

更新缓存

```shell
yum clean all
yum makecache
```

or 

```shell
yum makecache fast
```

安装

```shell
yum install docker-ce docker-ce-cli containerd.io
```

安装完后，查看安装的软件

```shell
rpm -qa | grep docker
```

输出结果为：

> docker-ce-19.03.9-3.el7.x86_64
> docker-ce-cli-19.03.9-3.el7.x86_64

#### 启动 Docker

```shell
systemctl enable docker
systemctl start docker
```

查看 Docker 版本：

```shell
docker --version
```

结果：(注：我这个)

> Docker version 20.10.9, build 9d988398e7

因为没有指定版本，所以安装的是最新版本，如果想安装指定版本，先查看所有版本列表：

```shell
yum list docker-ce --showduplicates | sort -r
```

`sort -r` 会按版本倒序排序，第二列是版本号，el7 表示 centos7，第三列是库名。

> docker-ce.x86_64            3:20.10.9-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:20.10.8-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:20.10.7-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:20.10.6-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:20.10.5-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:20.10.4-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:20.10.3-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:20.10.2-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:20.10.1-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:20.10.12-3.el7                  docker-ce-stable
> docker-ce.x86_64            3:20.10.11-3.el7                  docker-ce-stable
> docker-ce.x86_64            3:20.10.10-3.el7                  docker-ce-stable
> docker-ce.x86_64            3:20.10.0-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:19.03.9-3.el7                    docker-ce-stable
> docker-ce.x86_64            3:19.03.8-3.el7                    docker-ce-stable

例如安装 3:19.03.9-3.el7：

```shell
yum install docker-ce-19.03.9-3.el7 docker-ce-cli-19.03.9-3.el7 containerd.io
```

安装完成后，检查版本：

```shell
docker --version
```

> Docker version 19.03.9, build 9d988398e7

## 非root用户启动docker

默认情况下，`docker` 命令会使用 Unix socket 与 Docker 引擎通讯。而只有 `root` 用户和 `docker` 组的用户才可以访问 Docker 引擎的 Unix socket。出于安全考虑，一般 Linux 系统上不会直接使用 `root` 用户。因此，更好地做法是将需要使用 `docker` 的用户加入 `docker` 用户组。

建立 `docker` 组：

```Sh
$ sudo groupadd docker
```

将当前用户加入 `docker` 组：

```sh
$ sudo usermod -aG docker $USER
```
