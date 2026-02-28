---
title: "一些功能、工具记录"
description: ""
author: "jsharkc"
date: 2024-05-23T14:12:32+00:00
tags: ["biz"]
---

## 关于工具

1. tableflip 优雅热升级工具
2. singleflight 防缓存击穿利器
3. loongsuite-go-agent [Go 应用自动获得全链路可观测能力](https://mp.weixin.qq.com/s/0RfVQk-WMvNud7FTSMtm_w) [传送门](https://github.com/alibaba/loongsuite-go-agent)

## 关于功能

### 流程编排

1. rulego
2. go-workflow

### 上线发布系统

1. Spug

### SQL 审核系统

1. hhyo/Archery

### 多 Agent

1. crewai.com
2. metaAI
3. [Parlant](https://www.parlant.io/) 是可控 LLM 代理框架，解决大模型输出不稳定的问题。适合做客服机器人、任务助手这类需要精确控制的场景，不是纯聊天而是能干活的 AI Agent

### API 测试工具

1. [hoppscotch](https://hoppscotch.io/) 是开源版 Postman，支持 REST、GraphQL、WebSocket。有 Web、桌面、CLI 版本，可以自己部署，数据完全本地化，适合企业内网。更新很活跃。

### 浏览器

1. [Ladybird](https://ladybird.org/) 是真从零写的独立浏览器，不是 Chromium 换皮。从 SerenityOS 分出来的，成立了非营利组织，承诺不搞商业化套路。8 个全职工程师，2026 年夏天 Alpha 版本

### 水印

1. [blind_watermark](https://github.com/fire-keeper/BlindWatermark) 是个 Python 盲水印库，核心亮点是不需要原图就能提取水印。做版权保护、图片溯源的兄弟们可以用这个给图片加暗水印

