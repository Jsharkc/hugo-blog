---
title: 限制内存 mongo docker-compsoe 部署
description: 1. 通过 Docker 限制内存 2. 通过 MongoDB 配置文件限制内存
date: 2022-04-02T17:29:23+08:00
tags: ["mongo"]
---

用 docker 起 mongo，有两种限制方式：

1. 通过 Docker 限制内存
2. 通过 MongoDB 自己的配置文件限制



#### 一、通过 Docker 限制内存

内存限制相关参数：

| 参数            | 简介                                                        |
| --------------- | ----------------------------------------------------------- |
| -m, --memory    | 内存限制，格式：数字+单位，单位可以是b, k, m, g，最小4M     |
| -- -memory-swap | 存和交换空间总大小限制，注意：必须比-m参数大，-1 表示不受限 |

例子：

```shell
docker run -m 100M --memory-swap -1 mongo:5.0
```

#### 二、通过 mongo 配置文件限制

> 配置文件位置：
>
> 3.x : /etc/mongod.conf
>
> 4.x : /etc/mongod.conf.orig

默认配置：

```yaml
storage:
  # mongod 进程存储数据目录，此配置仅对 mongod 进程有效
  dbPath: /data/mongodb/db
  是否开启 journal 日志持久存储，journal 日志用来数据恢复，是 mongod 最基础的特性，通常用于故障恢复。64 位系统默认为 true，32 位默认为 false，建议开启，仅对 mongod 进程有效。
  journal:
    enabled: true
 # 存储引擎类型，mongodb 3.0 之后支持 “mmapv1”、“wiredTiger” 两种引擎，默认值为“mmapv1”；官方宣称 wiredTiger 引擎更加优秀。
  engine: mmapv1

systemLog:
  # 日志输出目的地，可以指定为 “file” 或者“syslog”，表述输出到日志文件，如果不指定，则会输出到标准输出中（standard output）
  destination: file
  # 如果为 true，当 mongod/mongos 重启后，将在现有日志的尾部继续添加日志。否则，将会备份当前日志文件，然后创建一个新的日志文件；默认为 false。
  logAppend: true
  # 日志路径
  path: /var/log/mongodb/mongod.log

net:
 # 指定端口
  port: 27017
  # 绑定外网 op 多个用逗号分隔
  bindIp: 0.0.0.0
  maxIncomingConnections: 10000
```

限制内存、使用 wiredTiger 引擎后配置：

```yaml
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /data/db
  journal:
    enabled: true
  engine: wiredTiger
    wiredTiger:
      engineConfig:
        # 限制 5GB 内存大小
        cacheSizeGB: 5

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0
	maxIncomingConnections: 10000

# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

```



#### 三、用 docker-compose 启动

docker-comopose 文件内容：

```yaml
version: '2'
services:
  mongo:
    image: "mongo:5.0"
    container_name: "mongo-v5"
    restart: always
    mem_limit: 6G
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: xxxxxx
    ports:
      - 27017:27017
    volumes:
      - ./db:/data/db
      - ./logs:/var/log/mongodb
      - ./mongod.conf.orig:/etc/mongod.conf.orig
    command: mongod --auth

  mongo-express:
    image: "mongo-express:0.54"
    container_name: "mongo-express"
    links:
      - mongo
    depends_on:
      - mongo
    ports:
      - 8081:8081
    environment:
      ME_CONFIG_BASICAUTH_USERNAME: admin
      ME_CONFIG_BASICAUTH_PASSWORD: xxxxxx
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: xxxxxx
```

做了 volume 映射，`./db:/data/db` 保证容器删了数据不会丢失，`./mongod.conf.orig` 记得放到该 `docker-compose.yam ` 同目录。`./logs` 查看 MongoDB 日志。另外起了 `mongo-express` 容器方便查看数据。

至此，完。

