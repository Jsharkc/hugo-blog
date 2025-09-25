---
title: "一个报警引发的思考"
description: ""
author: "jsharkc"
date: 2024-05-23T14:12:32+00:00
tags: ["biz"]
---

刚进入一家公司，老员工裁了一批，留下的也只熟悉自己那部分代码，有一部分大家都不熟悉，CEO 找技术 VP 说了报警的事，觉得每天报警太多了，也没人处理，VP 就开始 push 下面人解决报警问题。
之后通过报警遇到一个问题，接口报错，具体报错信息是

```
failed: users get one failed: Error 1390 (HY000): Prepared statement contains too many placeholders
```

根据报警日志，找到对应代码位置：
```golang
func (userDAO) GetAllByUserIds(ctx context.Context, uids []int) ([]model.User, error) {
	dbSession := dbConn.WithContext(ctx)

	var users []model.User
	err := dbSession.Model(&model.User{}).Where("id in ?", uids).Find(&users).Error
	return users, err
}
```

定位到问题代码，发现 uids 是一个切片，里面存放了 16w 个用户 id，sql 用的 in 语句

MySQL官方文档 error 定义：
Error number: 1390; Symbol: ER_PS_MANY_PARAM; SQLSTATE: HY000
Message: Prepared statement contains too many placeholders
在一个sql 语句中，最大占位符数量是有限制的，最大值为 16 bit 无符号数的最大值，即 65535

所以问题很明确了，一个sql 语句中，最大占位符数量为 65535，而传了 16w 个用户 id，所以报错

解决方法是将 uids 切片拆分成多个 1w 的切片，然后并发查询然后汇总即可
