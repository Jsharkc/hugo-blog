---
title: CentOS 以 Docker 方式部署 Jenkins
date: 2022-11-02T16:33:00+00:00
author: jacobc
tags: ["Jenkins"]
---

# CentOS 以 Docker 方式部署 Jenkins

## 一、Docker 安装 Jenkins

### 1.1 下载 Jenkins 镜像

Jenkins 有两个产品线，一个是稳定版（Stable[LTS]），一个是新功能版（Regular[Weekly]），这里使用稳定版，当然，也可以使用新功能版。

```shell
# 稳定版
docker pull jenkins/jenkins:lts
# 或者
docker pull jenkins/jenkins:lts-jdk11

# 新功能版
docker pull jenkins/jenkins
# 或者
docker pull jenkins/jenkins:jdk11
```

### 1.2 安装 Jenkins

下载完成后启动 Jenkins 镜像，这里提供两种方式，一种直接使用 docker 命令启动，另一种使用 docker-compose 启动

#### 1.2.1 使用 docker 命令启动 Jenkins

```shell
docker run -d --name jenkins -p 8080:8080 -v /data/jenkins:/var/jenkins_home jenkins/jenkins:lts
备注：
-d  在后台运行
--name 容器名字
-p 端口映射前面的端口为宿主机端口，后面的端口为容器端口
-v 数据卷挂载映射 /data/jenkins：宿主主机目录，后面的为容器目录
enkins/jenkins:lts Jenkins镜像名称
```

#### 1.2.2 使用 docker-compose 启动 Jenkins

docker-compose.yaml 文件内容如下：

```yaml
version: '3'
services:
  jenkins:
    container_name: jenkins
    image: jenkins/jenkins:lts
    ports:
      - 8080:8080
    volumes:
      - /data/jenkins:/var/jenkins_home
```

在命令行输入如下命令：

```shell
docker-compose up -d -f docker-compose.yaml
备注：
-d  在后台运行
-f  启动使用的文件名称，如果名称 docker-compose.yaml，可不用此参数，因为默认值即为 
```

#### 1.2.3 可能遇见的问题

可能会遇见启动不起来的情况，即 jenkins 容器状态一直未 Exited，通过 docker logs jenkins 查看日志，如下：

```shell
$ docker logs jenkins
Can not write to /var/jenkins_home/copy_reference_file.log. Wrong volume permissions?
touch: cannot touch '/var/jenkins_home/copy_reference_file.log': Permission denied
Running from: /usr/share/jenkins/jenkins/war
```

大概意思是没有权限，/data/jenkins 目录所属是 root 用户，可以给该目录添加 777 权限：

```shell
chmod 777 /data/jenkins
```

再启动，应该就可以了

## 二、Jenkins 初始化配置

在浏览器输入机器的 ip:8080 进入 Jenkins 网页端

```shell
http://225.240.67.40:8080
```

### 2.1解锁 Jenkins

第一次进入会展示这个界面：

![](https://tva1.sinaimg.cn/large/008vxvgGgy1h7rq1bgcv9j30ra0khdgu.jpg)

按照提示，找到 Docker 映射挂着的目录 `/data/jenkins/secrets/initialAdminPassword`，查看内容，复制，并粘贴到这里。

### 2.2 安装插件

之后是安装插件，如下：

![](https://tva1.sinaimg.cn/large/008vxvgGgy1h7rrhobrlxj30jt0g1758.jpg)

新手建议选择前面这个，之后会跳转到如下页面，安装过程可能会有半个小时。

### 2.3 管理员用户创建

创建的第一个用户，具有最大权限。

![](https://tva1.sinaimg.cn/large/008vxvgGgy1h7rw6evpufj30rc0kjt9n.jpg)

填完这个表单，保存并完成，就安装成功了。

![](https://tva1.sinaimg.cn/large/008vxvgGgy1h7rw946jp1j30io0cht8u.jpg)

## 三、安装 gcc 环境

后面使用的过程中，可能会遇到一个问题，就是 jenkins 环境里没有 gcc，所以需要安装一下，直接进入镜像中安装不了，报没有权限，所以有两种方式：

一种是启动容器时，给 `privileged` 权限，或者说模式，这样会是容器拥有真正的 root 权限，但是容器就不安全了。

另一种是以原有镜像作为基础镜像，通过 Dockerfile 安装 gcc 及相关工具，打包新的镜像。

这里主要说镜像方案，Dockerfile 文件内容如下：

```dockerfile
FROM jenkins/jenkins:lts
USER root
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak && sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
RUN apt-get update && apt-get install -y build-essential
USER jenkins
```

写好之后，使用如下命令打包镜像：

```shell
docker build -t jenkins-gcc:lts .
```

当然，起什么镜像名称和版本号可以自己觉得，这里只是举个例子。

最后，只需要把上面用到的 docker-compose.yaml 文件进行简单的修改即可：

```yaml
version: '3'
services:
  jenkins:
    container_name: jenkins
-   image: jenkins/jenkins:lts
+   image: jenkins-gcc:lts
    ports:
      - 8080:8080
    volumes:
      - /data/jenkins:/var/jenkins_home
```

最后的最后，使用 `docker-compose up -d -f docker-compose.yaml` 启动 jenkins。

Finish
