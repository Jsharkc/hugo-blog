---
title: Docker-deploy-MinDoc
description: '记录使用 docker-compose 部署 MinDoc 的过程'
date: 2023-11-08T19:21:24+08:00
tags: ["CentOS7", "MinDoc"]
author: "Jacobc"
---

[MinDoc 地址](https://github.com/mindoc-org/mindoc/issues?q=export_func_disable)

## 一、使用 docker-compose 部署 MinDoc

### 1. 使用 sqlite3 数据库

```yaml
version: '3'
services:
  mindoc:
    container_name: mindoc
    image: registry.cn-hangzhou.aliyuncs.com/mindoc-org/mindoc:v2.1
    restart: always
    ports:
      - 8181:8181
    environment:
      - MINDOC_RUN_MODE=prod
      - MINDOC_DB_ADAPTER=sqlite3
      - MINDOC_DB_DATABASE=./database/mindoc.db
      - MINDOC_CACHE=true
      - MINDOC_CACHE_PROVIDER=file
      - MINDOC_ENABLE_EXPORT=true
      - MINDOC_BASE_URL=
      - MINDOC_CDN_IMG_URL=
      - MINDOC_CDN_CSS_URL=
      - MINDOC_CDN_JS_URL=
    volumes:
      - ./conf:/mindoc/conf
      - ./static:/mindoc/static
      - ./views:/mindoc/views
      - ./uploads:/mindoc/uploads
      - ./runtime:/mindoc/runtime
      - ./database:/mindoc/database
```

`docker-compose up -d` 启动就可以了，登录账号是 admin，密码是 123456，进去后记得修改密码

但是会碰到导出 `PDF` 格式文档时一直让等待，其实是出问题了。

还要注意，`docker-compose.yaml` 中 `- MINDOC_ENABLE_EXPORT=true` 这里为 `true` 时，才能导出，从其他地方找的 `docker-compose.yaml` 中默认这里是 `false`。

### 2. 使用 mysql 数据库部署

mysql 版本可以自己定，比如 5.6、5.7、8.0 等等。但是要注意的一点是，比如用 5.7 版本的数据库启动了，后续迁移到新机器想换 msyql 版本，直接换是不行的，只能导出数据，再导入到新的数据库中，否则会起不来。

```yaml
version: '3'
services:
  mindoc:
    container_name: mindoc
    image: registry.cn-hangzhou.aliyuncs.com/mindoc-org/mindoc:v2.1
    restart: always
    depends_on:
      - mindoc_mysql
    ports:
      - 8181:8181
    environment:
      - MINDOC_RUN_MODE=prod
      - MINDOC_DB_ADAPTER=mysql
      - MINDOC_DB_HOST=mindoc_mysql
      - MINDOC_DB_DATABASE=mindoc
      - MINDOC_DB_USERNAME=mindoc
      - MINDOC_DB_PASSWORD=passwd_mindoc
      - MINDOC_CACHE=true
      - MINDOC_CACHE_PROVIDER=file
      - MINDOC_ENABLE_EXPORT=true
      - MINDOC_BASE_URL=
      - MINDOC_CDN_IMG_URL=
      - MINDOC_CDN_CSS_URL=
      - MINDOC_CDN_JS_URL=
    volumes:
      - ./conf:/mindoc/conf
      - ./static:/mindoc/static
      - ./views:/mindoc/views
      - ./uploads:/mindoc/uploads
      - ./runtime:/mindoc/runtime
      - ./database:/mindoc/database

  mindoc_mysql:
    container_name: mindoc_mysql
    image: mysql:5.7
    restart: always
    ports:
      - 3307:3306
    environment:
      MYSQL_ROOT_PASSWORD: mindoc
      MYSQL_DATABASE: mindoc
      MYSQL_USER: mindoc
      MYSQL_PASSWORD: passwd_mindoc
    volumes:
      - ./mysql:/var/lib/mysql
      - /etc/localtime:/etc/localtime:ro
    command:
      [
        'mysqld',
        '--character-set-server=utf8mb4',
        '--collation-server=utf8mb4_unicode_ci',
        '--max_allowed_packet=200M'
      ]
```

`docker-compose up -d` 启动就可以了。

## 二、解决导出问题

[查到这里](https://github.com/mindoc-org/mindoc/issues/807)

据说是不兼容 calibre 新版本的问题，Dockerfile 构建镜像时会一直使用最新版本的 calibre，但是目前不兼容最新版 6，可回滚到 5 版本，首先切换到部署 `docker-compose.yaml` 的目录

```shell
cd /path/to/mindoc
wget https://download.calibre-ebook.com/5.44.0/calibre-5.44.0-x86_64.txz
mkdir calibre
tar xJof calibre-5.44.0-x86_64.txz -C ./calibre

# 停止启动的 mindoc
docker-compose down

# 修改 docker-compose.yaml，在 volumes 最后面加上一行 - ./calibre:/opt/calibre，如下：
# volumes:
#   - ./conf:/mindoc/conf
#   - ./static:/mindoc/static
#   - ./views:/mindoc/views
#   - ./uploads:/mindoc/uploads
#   - ./runtime:/mindoc/runtime
#   - ./database:/mindoc/database
#   - ./calibre:/opt/calibre

# 启动 mindoc
docker-compose up -d
```

